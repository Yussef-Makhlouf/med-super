import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive_ce.dart';
import 'package:med_super/core/di/core_providers.dart';
import 'package:med_super/core/error/failure.dart';
import 'package:med_super/core/error/result.dart';
import 'package:med_super/core/storage/hive_service.dart';
import 'package:med_super/features/provider_registration/domain/entities/clinic_working_day.dart';
import 'package:med_super/features/provider_registration/domain/entities/doctor_registration_draft.dart';
import 'package:med_super/features/provider_registration/domain/entities/uploaded_document.dart';
import 'package:med_super/features/provider_registration/domain/repositories/provider_registration_repository.dart';
import 'package:med_super/features/provider_registration/presentation/controllers/registration_form_controller.dart';
import 'package:mocktail/mocktail.dart';

class _MockHiveService extends Mock implements HiveService {}

class _MockBox extends Mock implements Box<String> {}

class _MockRepository extends Mock implements ProviderRegistrationRepository {}

void main() {
  late _MockHiveService hiveService;
  late _MockBox box;
  late _MockRepository repository;
  late ProviderContainer container;

  setUpAll(() {
    registerFallbackValue(const DoctorRegistrationDraft());
  });

  setUp(() {
    hiveService = _MockHiveService();
    box = _MockBox();
    repository = _MockRepository();

    when(() => hiveService.providerRegistrationDraftBox).thenReturn(box);
    when(() => box.get(any())).thenReturn(null);
    when(() => box.put(any(), any())).thenAnswer((_) async {});
    when(() => box.delete(any())).thenAnswer((_) async {});

    container = ProviderContainer(
      overrides: [
        hiveServiceProvider.overrideWithValue(hiveService),
        providerRegistrationRepositoryProvider.overrideWithValue(repository),
      ],
    );
  });

  tearDown(() => container.dispose());

  test('build() starts with an empty draft when no cached draft exists', () {
    final draft = container.read(registrationFormControllerProvider);
    expect(draft, const DoctorRegistrationDraft());
  });

  test('build() restores a previously persisted draft from the box', () {
    when(() => box.get('draft')).thenReturn(
      jsonEncode({
        'full_name': 'Dr. Restored',
        'specialty': 'cardio',
        'degree': 'MD',
        'experience_years': 6,
        'bio': 'hello',
        'profile_photo_local_path': '/p.png',
        'documents': [
          {
            'id': '1',
            'file_name': 'license.pdf',
            'size_bytes': 10,
            'local_path': '/tmp/license.pdf',
            'type': 'medicalLicense',
          },
        ],
        'clinic_name': 'clinic',
        'clinic_address': 'addr',
        'city': 'cairo',
        'consultation_fee': 200,
        'agreed_to_terms': true,
      }),
    );

    final freshContainer = ProviderContainer(
      overrides: [
        hiveServiceProvider.overrideWithValue(hiveService),
        providerRegistrationRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(freshContainer.dispose);

    final draft = freshContainer.read(registrationFormControllerProvider);
    expect(draft.fullName, 'Dr. Restored');
    expect(draft.specialty, 'cardio');
    expect(draft.degree, 'MD');
    expect(draft.experienceYears, 6);
    expect(draft.bio, 'hello');
    expect(draft.profilePhotoLocalPath, '/p.png');
    expect(draft.documents, hasLength(1));
    expect(draft.documents.single.type, DocumentType.medicalLicense);
    expect(draft.clinicName, 'clinic');
    expect(draft.clinicAddress, 'addr');
    expect(draft.city, 'cairo');
    expect(draft.consultationFee, 200);
    expect(draft.agreedToTerms, isTrue);
  });

  test(
    'build() falls back to an empty draft when cached JSON is malformed',
    () {
      when(() => box.get('draft')).thenReturn('not json');

      final freshContainer = ProviderContainer(
        overrides: [
          hiveServiceProvider.overrideWithValue(hiveService),
          providerRegistrationRepositoryProvider.overrideWithValue(repository),
        ],
      );
      addTearDown(freshContainer.dispose);

      final draft = freshContainer.read(registrationFormControllerProvider);
      expect(draft, const DoctorRegistrationDraft());
    },
  );

  test('updateBasicInfo updates fields and persists to the box', () {
    container
        .read(registrationFormControllerProvider.notifier)
        .updateBasicInfo(
          fullName: 'Dr. New',
          specialty: 'derma',
          degree: 'MD',
          experienceYears: 2,
          bio: 'bio',
        );

    final draft = container.read(registrationFormControllerProvider);
    expect(draft.fullName, 'Dr. New');
    expect(draft.specialty, 'derma');
    verify(() => box.put('draft', any())).called(1);
  });

  test('updateProfilePhoto sets the local path and persists', () {
    container
        .read(registrationFormControllerProvider.notifier)
        .updateProfilePhoto('/photo.png');

    expect(
      container.read(registrationFormControllerProvider).profilePhotoLocalPath,
      '/photo.png',
    );
  });

  test('addDocument appends and removeDocument removes by id', () {
    final notifier = container.read(
      registrationFormControllerProvider.notifier,
    );
    const document = UploadedDocument(
      id: 'doc-1',
      fileName: 'license.pdf',
      sizeBytes: 10,
      localPath: '/tmp/license.pdf',
      type: DocumentType.medicalLicense,
    );

    notifier.addDocument(document);
    expect(container.read(registrationFormControllerProvider).documents, [
      document,
    ]);

    notifier.removeDocument('doc-1');
    expect(
      container.read(registrationFormControllerProvider).documents,
      isEmpty,
    );
  });

  test('removeDocument is a no-op when id is not found', () {
    final notifier = container.read(
      registrationFormControllerProvider.notifier,
    );
    const document = UploadedDocument(
      id: 'doc-1',
      fileName: 'license.pdf',
      sizeBytes: 10,
      localPath: '/tmp/license.pdf',
      type: DocumentType.medicalLicense,
    );
    notifier.addDocument(document);

    notifier.removeDocument('does-not-exist');

    expect(container.read(registrationFormControllerProvider).documents, [
      document,
    ]);
  });

  test('updateClinicInfo updates clinic fields', () {
    container
        .read(registrationFormControllerProvider.notifier)
        .updateClinicInfo(
          clinicName: 'Clinic',
          clinicAddress: 'Addr',
          city: 'cairo',
          clinicLat: 30.1,
          clinicLng: 31.2,
          consultationFee: 250,
        );

    final draft = container.read(registrationFormControllerProvider);
    expect(draft.clinicName, 'Clinic');
    expect(draft.clinicAddress, 'Addr');
    expect(draft.city, 'cairo');
    expect(draft.clinicLat, 30.1);
    expect(draft.clinicLng, 31.2);
    expect(draft.consultationFee, 250);
  });

  test('toggleWorkingDay flips isEnabled only for the matching day', () {
    final notifier = container.read(
      registrationFormControllerProvider.notifier,
    );

    notifier.toggleWorkingDay(Weekday.monday, true);

    final days = container.read(registrationFormControllerProvider).workingDays;
    for (final d in days) {
      expect(d.isEnabled, d.day == Weekday.monday);
    }
  });

  test('setWorkingHours sets from/to only for the matching day', () {
    final notifier = container.read(
      registrationFormControllerProvider.notifier,
    );
    const from = ClinicTime(hour: 9, minute: 0);
    const to = ClinicTime(hour: 17, minute: 0);

    notifier.setWorkingHours(Weekday.friday, from: from, to: to);

    final days = container.read(registrationFormControllerProvider).workingDays;
    final friday = days.firstWhere((d) => d.day == Weekday.friday);
    expect(friday.from, from);
    expect(friday.to, to);
    final others = days.where((d) => d.day != Weekday.friday);
    expect(others.every((d) => d.from == null), isTrue);
  });

  test('setAgreedToTerms updates the flag', () {
    container
        .read(registrationFormControllerProvider.notifier)
        .setAgreedToTerms(true);
    expect(
      container.read(registrationFormControllerProvider).agreedToTerms,
      isTrue,
    );
  });

  test('submit() clears the draft and box on success', () async {
    when(
      () => repository.submit(any()),
    ).thenAnswer((_) async => const Result.ok(null));
    final notifier = container.read(
      registrationFormControllerProvider.notifier,
    );
    notifier.updateBasicInfo(fullName: 'Dr. X');

    final result = await notifier.submit();

    expect(result.isOk, isTrue);
    expect(
      container.read(registrationFormControllerProvider),
      const DoctorRegistrationDraft(),
    );
    verify(() => box.delete('draft')).called(1);
  });

  test('submit() keeps the draft when the repository returns Err', () async {
    when(
      () => repository.submit(any()),
    ).thenAnswer((_) async => const Result.err(Failure.network()));
    final notifier = container.read(
      registrationFormControllerProvider.notifier,
    );
    notifier.updateBasicInfo(fullName: 'Dr. X');

    final result = await notifier.submit();

    expect(result.isErr, isTrue);
    expect(
      container.read(registrationFormControllerProvider).fullName,
      'Dr. X',
    );
    verifyNever(() => box.delete(any()));
  });
}

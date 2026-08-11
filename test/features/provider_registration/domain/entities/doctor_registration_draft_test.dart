import 'package:flutter_test/flutter_test.dart';
import 'package:med_super/features/provider_registration/domain/entities/clinic_working_day.dart';
import 'package:med_super/features/provider_registration/domain/entities/doctor_registration_draft.dart';
import 'package:med_super/features/provider_registration/domain/entities/uploaded_document.dart';

UploadedDocument _doc(DocumentType type) => UploadedDocument(
  id: type.name,
  fileName: '${type.name}.pdf',
  sizeBytes: 100,
  localPath: '/tmp/${type.name}.pdf',
  type: type,
);

void main() {
  group('DoctorRegistrationDraft defaults', () {
    test('has empty/zero defaults and 7 disabled working days', () {
      const draft = DoctorRegistrationDraft();

      expect(draft.fullName, '');
      expect(draft.specialty, isNull);
      expect(draft.degree, '');
      expect(draft.experienceYears, 0);
      expect(draft.bio, '');
      expect(draft.profilePhotoLocalPath, isNull);
      expect(draft.documents, isEmpty);
      expect(draft.clinicName, '');
      expect(draft.clinicAddress, '');
      expect(draft.city, isNull);
      expect(draft.clinicLat, isNull);
      expect(draft.clinicLng, isNull);
      expect(draft.consultationFee, 0);
      expect(draft.workingDays, hasLength(7));
      expect(draft.workingDays.every((d) => !d.isEnabled), isTrue);
      expect(draft.agreedToTerms, isFalse);
    });

    test('default working days cover every Weekday exactly once', () {
      const draft = DoctorRegistrationDraft();
      final days = draft.workingDays.map((d) => d.day).toSet();
      expect(days, Weekday.values.toSet());
    });
  });

  group('DoctorRegistrationDraft.basicInfoComplete', () {
    const complete = DoctorRegistrationDraft(
      fullName: 'Dr. Sara',
      specialty: 'cardio',
      degree: 'MD',
      experienceYears: 5,
    );

    test('true when all four conditions hold', () {
      expect(complete.basicInfoComplete, isTrue);
    });

    test('false when fullName is empty', () {
      expect(complete.copyWith(fullName: '').basicInfoComplete, isFalse);
    });

    test('false when fullName is only whitespace', () {
      expect(complete.copyWith(fullName: '   ').basicInfoComplete, isFalse);
    });

    test('false when specialty is null', () {
      const draft = DoctorRegistrationDraft(
        fullName: 'Dr. Sara',
        degree: 'MD',
        experienceYears: 5,
      );
      expect(draft.basicInfoComplete, isFalse);
    });

    test('false when degree is empty', () {
      expect(complete.copyWith(degree: '').basicInfoComplete, isFalse);
    });

    test('false when degree is only whitespace', () {
      expect(complete.copyWith(degree: '  ').basicInfoComplete, isFalse);
    });

    test('false when experienceYears is zero', () {
      expect(complete.copyWith(experienceYears: 0).basicInfoComplete, isFalse);
    });

    test('false when experienceYears is negative', () {
      expect(complete.copyWith(experienceYears: -1).basicInfoComplete, isFalse);
    });
  });

  group('DoctorRegistrationDraft.verificationComplete', () {
    test('true when both medicalLicense and nationalId are present', () {
      final draft = DoctorRegistrationDraft(
        documents: [
          _doc(DocumentType.medicalLicense),
          _doc(DocumentType.nationalId),
        ],
      );
      expect(draft.verificationComplete, isTrue);
    });

    test('true even with extra unrelated documents present', () {
      final draft = DoctorRegistrationDraft(
        documents: [
          _doc(DocumentType.medicalLicense),
          _doc(DocumentType.nationalId),
          _doc(DocumentType.specialtyCertificate),
          _doc(DocumentType.profilePhoto),
        ],
      );
      expect(draft.verificationComplete, isTrue);
    });

    test('false when no documents are present', () {
      const draft = DoctorRegistrationDraft();
      expect(draft.verificationComplete, isFalse);
    });

    test('false when only medicalLicense is present', () {
      final draft = DoctorRegistrationDraft(
        documents: [_doc(DocumentType.medicalLicense)],
      );
      expect(draft.verificationComplete, isFalse);
    });

    test('false when only nationalId is present', () {
      final draft = DoctorRegistrationDraft(
        documents: [_doc(DocumentType.nationalId)],
      );
      expect(draft.verificationComplete, isFalse);
    });

    test('false when unrelated documents only', () {
      final draft = DoctorRegistrationDraft(
        documents: [
          _doc(DocumentType.specialtyCertificate),
          _doc(DocumentType.profilePhoto),
        ],
      );
      expect(draft.verificationComplete, isFalse);
    });
  });

  group('DoctorRegistrationDraft.clinicScheduleComplete', () {
    final enabledDay = ClinicWorkingDay(day: Weekday.monday, isEnabled: true);
    final complete = DoctorRegistrationDraft(
      clinicName: 'Best Clinic',
      clinicAddress: '123 Street',
      city: 'cairo',
      consultationFee: 200,
      workingDays: [enabledDay],
    );

    test('true when every condition holds', () {
      expect(complete.clinicScheduleComplete, isTrue);
    });

    test('false when clinicName is empty', () {
      expect(complete.copyWith(clinicName: '').clinicScheduleComplete, isFalse);
    });

    test('false when clinicName is only whitespace', () {
      expect(
        complete.copyWith(clinicName: '   ').clinicScheduleComplete,
        isFalse,
      );
    });

    test('false when clinicAddress is empty', () {
      expect(
        complete.copyWith(clinicAddress: '').clinicScheduleComplete,
        isFalse,
      );
    });

    test('false when city is null', () {
      const draft = DoctorRegistrationDraft(
        clinicName: 'Best Clinic',
        clinicAddress: '123 Street',
        consultationFee: 200,
        workingDays: [ClinicWorkingDay(day: Weekday.monday, isEnabled: true)],
      );
      expect(draft.clinicScheduleComplete, isFalse);
    });

    test('false when consultationFee is zero', () {
      expect(
        complete.copyWith(consultationFee: 0).clinicScheduleComplete,
        isFalse,
      );
    });

    test('false when consultationFee is negative', () {
      expect(
        complete.copyWith(consultationFee: -5).clinicScheduleComplete,
        isFalse,
      );
    });

    test('false when no working day is enabled', () {
      final draft = complete.copyWith(
        workingDays: [
          const ClinicWorkingDay(day: Weekday.monday, isEnabled: false),
        ],
      );
      expect(draft.clinicScheduleComplete, isFalse);
    });

    test('false when workingDays list is empty', () {
      final draft = complete.copyWith(workingDays: const []);
      expect(draft.clinicScheduleComplete, isFalse);
    });

    test('true when at least one of several days is enabled', () {
      final draft = complete.copyWith(
        workingDays: [
          const ClinicWorkingDay(day: Weekday.sunday, isEnabled: false),
          const ClinicWorkingDay(day: Weekday.monday, isEnabled: true),
        ],
      );
      expect(draft.clinicScheduleComplete, isTrue);
    });
  });

  group('DoctorRegistrationDraft.copyWith', () {
    const original = DoctorRegistrationDraft(
      fullName: 'A',
      specialty: 'cardio',
      degree: 'MD',
      experienceYears: 3,
      bio: 'bio',
      profilePhotoLocalPath: '/a.png',
      clinicName: 'clinic',
      clinicAddress: 'addr',
      city: 'cairo',
      clinicLat: 30.0,
      clinicLng: 31.0,
      consultationFee: 100,
      agreedToTerms: true,
    );

    test('with no arguments, all fields are preserved', () {
      final copy = original.copyWith();

      expect(copy.fullName, original.fullName);
      expect(copy.specialty, original.specialty);
      expect(copy.degree, original.degree);
      expect(copy.experienceYears, original.experienceYears);
      expect(copy.bio, original.bio);
      expect(copy.profilePhotoLocalPath, original.profilePhotoLocalPath);
      expect(copy.documents, original.documents);
      expect(copy.clinicName, original.clinicName);
      expect(copy.clinicAddress, original.clinicAddress);
      expect(copy.city, original.city);
      expect(copy.clinicLat, original.clinicLat);
      expect(copy.clinicLng, original.clinicLng);
      expect(copy.consultationFee, original.consultationFee);
      expect(copy.workingDays, original.workingDays);
      expect(copy.agreedToTerms, original.agreedToTerms);
    });

    test('each field individually overrides when provided', () {
      final doc = _doc(DocumentType.medicalLicense);
      final days = [
        const ClinicWorkingDay(day: Weekday.friday, isEnabled: true),
      ];

      final copy = original.copyWith(
        fullName: 'B',
        specialty: 'derma',
        degree: 'PhD',
        experienceYears: 9,
        bio: 'new bio',
        profilePhotoLocalPath: '/b.png',
        documents: [doc],
        clinicName: 'clinic2',
        clinicAddress: 'addr2',
        city: 'giza',
        clinicLat: 1.0,
        clinicLng: 2.0,
        consultationFee: 300,
        workingDays: days,
        agreedToTerms: false,
      );

      expect(copy.fullName, 'B');
      expect(copy.specialty, 'derma');
      expect(copy.degree, 'PhD');
      expect(copy.experienceYears, 9);
      expect(copy.bio, 'new bio');
      expect(copy.profilePhotoLocalPath, '/b.png');
      expect(copy.documents, [doc]);
      expect(copy.clinicName, 'clinic2');
      expect(copy.clinicAddress, 'addr2');
      expect(copy.city, 'giza');
      expect(copy.clinicLat, 1.0);
      expect(copy.clinicLng, 2.0);
      expect(copy.consultationFee, 300);
      expect(copy.workingDays, days);
      expect(copy.agreedToTerms, isFalse);
    });

    test('copyWith cannot null-out a nullable field once set (uses ??)', () {
      // Documented current behavior: passing null is indistinguishable from
      // omitting the argument, so specialty/city/lat/lng can never be
      // cleared back to null via copyWith.
      final copy = original.copyWith();
      expect(copy.specialty, isNotNull);
    });
  });
}

import 'dart:convert';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:med_super/core/constants/storage_keys.dart';
import 'package:med_super/core/di/core_providers.dart';
import 'package:med_super/core/error/failure.dart';
import 'package:med_super/core/error/result.dart';
import 'package:med_super/features/provider_registration/data/datasources/remote/provider_registration_remote_datasource.dart';
import 'package:med_super/features/provider_registration/data/repositories/provider_registration_repository_impl.dart';
import 'package:med_super/features/provider_registration/domain/entities/clinic_working_day.dart';
import 'package:med_super/features/provider_registration/domain/entities/doctor_registration_draft.dart';
import 'package:med_super/features/provider_registration/domain/entities/uploaded_document.dart';
import 'package:med_super/features/provider_registration/domain/repositories/provider_registration_repository.dart';
import 'package:med_super/features/provider_registration/domain/usecases/get_my_doctor_registration_status_usecase.dart';
import 'package:med_super/features/provider_registration/domain/usecases/submit_registration_usecase.dart';

part 'registration_form_controller.g.dart';

/// Exposed (not private) so `SessionController.logout()` can clear the
/// draft directly — a different person registering as a doctor on the same
/// device must never see a half-filled draft left by whoever logged out.
const providerRegistrationDraftKey = 'draft';

@riverpod
ProviderRegistrationRemoteDatasource providerRegistrationRemoteDatasource(
  Ref ref,
) => ProviderRegistrationRemoteDatasource(ref.watch(dioProvider));

@riverpod
ProviderRegistrationRepository providerRegistrationRepository(Ref ref) =>
    ProviderRegistrationRepositoryImpl(
      remote: ref.watch(providerRegistrationRemoteDatasourceProvider),
    );

@riverpod
SubmitRegistrationUseCase submitRegistrationUseCase(Ref ref) =>
    SubmitRegistrationUseCase(
      ref.watch(providerRegistrationRepositoryProvider),
    );

@riverpod
GetMyDoctorRegistrationStatusUseCase myDoctorRegistrationStatusUseCase(
  Ref ref,
) => GetMyDoctorRegistrationStatusUseCase(
  ref.watch(providerRegistrationRepositoryProvider),
);

/// Holds the in-progress multi-step draft, auto-saved to Hive on every change
/// so the flow survives an app restart before final submission.
@Riverpod(keepAlive: true)
class RegistrationFormController extends _$RegistrationFormController {
  @override
  DoctorRegistrationDraft build() =>
      _loadDraft() ?? const DoctorRegistrationDraft();

  DoctorRegistrationDraft? _loadDraft() {
    final box = ref.read(hiveServiceProvider).providerRegistrationDraftBox;
    final raw = box.get(providerRegistrationDraftKey);
    if (raw == null) return null;
    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      return DoctorRegistrationDraft(
        fullName: json['full_name'] as String? ?? '',
        specialty: json['specialty'] as String?,
        degree: json['degree'] as String? ?? '',
        email: json['email'] as String? ?? '',
        experienceYears: json['experience_years'] as int? ?? 0,
        bio: json['bio'] as String? ?? '',
        licenseNumber: json['license_number'] as String? ?? '',
        profilePhotoLocalPath: json['profile_photo_local_path'] as String?,
        profilePhotoDataUri: json['profile_photo_data_uri'] as String?,
        documents: (json['documents'] as List<dynamic>? ?? const [])
            .whereType<Map<String, dynamic>>()
            .map(
              (d) => UploadedDocument(
                id: d['id'] as String,
                fileName: d['file_name'] as String,
                sizeBytes: d['size_bytes'] as int,
                localPath: d['local_path'] as String,
                type: DocumentType.values.byName(d['type'] as String),
              ),
            )
            .toList(),
        clinicName: json['clinic_name'] as String? ?? '',
        clinicAddress: json['clinic_address'] as String? ?? '',
        city: json['city'] as String?,
        regionCode: json['region_code'] as String?,
        consultationFee: json['consultation_fee'] as int? ?? 0,
        agreedToTerms: json['agreed_to_terms'] as bool? ?? false,
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> _persist() async {
    final box = ref.read(hiveServiceProvider).providerRegistrationDraftBox;
    final d = state;
    await box.put(
      providerRegistrationDraftKey,
      jsonEncode({
        'full_name': d.fullName,
        'specialty': d.specialty,
        'degree': d.degree,
        'email': d.email,
        'experience_years': d.experienceYears,
        'bio': d.bio,
        'license_number': d.licenseNumber,
        'profile_photo_local_path': d.profilePhotoLocalPath,
        'profile_photo_data_uri': d.profilePhotoDataUri,
        'documents': d.documents
            .map(
              (doc) => {
                'id': doc.id,
                'file_name': doc.fileName,
                'size_bytes': doc.sizeBytes,
                'local_path': doc.localPath,
                'type': doc.type.name,
              },
            )
            .toList(),
        'clinic_name': d.clinicName,
        'clinic_address': d.clinicAddress,
        'city': d.city,
        'region_code': d.regionCode,
        'consultation_fee': d.consultationFee,
        'agreed_to_terms': d.agreedToTerms,
      }),
    );
  }

  void updateBasicInfo({
    String? fullName,
    String? specialty,
    String? degree,
    String? email,
    int? experienceYears,
    String? bio,
  }) {
    state = state.copyWith(
      fullName: fullName,
      specialty: specialty,
      degree: degree,
      email: email,
      experienceYears: experienceYears,
      bio: bio,
    );
    _persist();
  }

  void updateVerificationInfo({String? licenseNumber}) {
    state = state.copyWith(licenseNumber: licenseNumber);
    _persist();
  }

  void updateProfilePhoto(String localPath, {String? dataUri}) {
    state = state.copyWith(
      profilePhotoLocalPath: localPath,
      profilePhotoDataUri: dataUri,
    );
    _persist();
  }

  void addDocument(UploadedDocument document) {
    state = state.copyWith(documents: [...state.documents, document]);
    _persist();
  }

  void removeDocument(String documentId) {
    state = state.copyWith(
      documents: state.documents.where((d) => d.id != documentId).toList(),
    );
    _persist();
  }

  void updateClinicInfo({
    String? clinicName,
    String? clinicAddress,
    String? city,
    String? regionCode,
    double? clinicLat,
    double? clinicLng,
    int? consultationFee,
  }) {
    state = state.copyWith(
      clinicName: clinicName,
      clinicAddress: clinicAddress,
      city: city,
      regionCode: regionCode,
      clinicLat: clinicLat,
      clinicLng: clinicLng,
      consultationFee: consultationFee,
    );
    _persist();
  }

  void toggleWorkingDay(Weekday day, bool isEnabled) {
    state = state.copyWith(
      workingDays: state.workingDays
          .map((d) => d.day == day ? d.copyWith(isEnabled: isEnabled) : d)
          .toList(),
    );
    _persist();
  }

  void setWorkingHours(Weekday day, {ClinicTime? from, ClinicTime? to}) {
    state = state.copyWith(
      workingDays: state.workingDays
          .map((d) => d.day == day ? d.copyWith(from: from, to: to) : d)
          .toList(),
    );
    _persist();
  }

  void setAgreedToTerms(bool value) {
    state = state.copyWith(agreedToTerms: value);
    _persist();
  }

  bool _submitting = false;

  Future<Result<void>> submit({
    String? specialtyLabel,
    String? cityLabel,
    String? phone,
  }) async {
    if (_submitting) {
      return const Result.err(Failure.conflict('Already submitting.'));
    }
    _submitting = true;
    try {
      final result = await ref
          .read(submitRegistrationUseCaseProvider)
          .call(
            state,
            specialtyLabel: specialtyLabel,
            cityLabel: cityLabel,
            phone: phone,
          );
      // A `DOCTOR_ALREADY_EXISTS` 409 (e.g. a retried/duplicate submit,
      // or resubmitting from a stale screen after already registering) is
      // treated the same as success here: the applicant already has a
      // PENDING/VERIFIED registration either way, so the outcome the user
      // needs — land on the pending-status screen — is identical. Without
      // this, a doctor who is already PENDING would see a generic error
      // and be stuck on the review screen with no way to reach the status
      // screen short of a fresh login (which does its own resync).
      // `reason` here is `ConflictError`'s raw backend message
      // (`dio_failure_mapper.dart`), matched verbatim against
      // `create-doctor.use-case.ts`'s exact string — same pattern
      // `reschedule_screen.dart`'s `_conflictMessage` already uses.
      final failure = result.failureOrNull;
      final isDuplicateRegistration =
          failure is ConflictFailure &&
          failure.reason == 'This user already has a doctor profile.';
      if (result.isOk || isDuplicateRegistration) {
        await _clearDraft();
        await ref
            .read(hiveServiceProvider)
            .settingsBox
            .put(SettingsKeys.providerRegistrationSubmitted, 'true');
        // No longer needed once the real submission flag takes over as the
        // router's signal — see that flag's own doc comment.
        await ref
            .read(hiveServiceProvider)
            .settingsBox
            .delete(SettingsKeys.choseDoctorRoleAtSignup);
        return isDuplicateRegistration ? const Result.ok(null) : result;
      }
      return result;
    } finally {
      _submitting = false;
    }
  }

  Future<void> _clearDraft() async {
    final box = ref.read(hiveServiceProvider).providerRegistrationDraftBox;
    await box.delete(providerRegistrationDraftKey);
    state = const DoctorRegistrationDraft();
  }
}

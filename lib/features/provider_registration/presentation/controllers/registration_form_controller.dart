import 'dart:convert';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:med_super/core/constants/storage_keys.dart';
import 'package:med_super/core/di/core_providers.dart';
import 'package:med_super/core/error/result.dart';
import 'package:med_super/features/provider_registration/data/datasources/remote/provider_registration_remote_datasource.dart';
import 'package:med_super/features/provider_registration/data/repositories/provider_registration_repository_impl.dart';
import 'package:med_super/features/provider_registration/domain/entities/clinic_working_day.dart';
import 'package:med_super/features/provider_registration/domain/entities/doctor_registration_draft.dart';
import 'package:med_super/features/provider_registration/domain/entities/uploaded_document.dart';
import 'package:med_super/features/provider_registration/domain/repositories/provider_registration_repository.dart';
import 'package:med_super/features/provider_registration/domain/usecases/submit_registration_usecase.dart';

part 'registration_form_controller.g.dart';

const _draftKey = 'draft';

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

/// Holds the in-progress multi-step draft, auto-saved to Hive on every change
/// so the flow survives an app restart before final submission.
@Riverpod(keepAlive: true)
class RegistrationFormController extends _$RegistrationFormController {
  @override
  DoctorRegistrationDraft build() =>
      _loadDraft() ?? const DoctorRegistrationDraft();

  DoctorRegistrationDraft? _loadDraft() {
    final box = ref.read(hiveServiceProvider).providerRegistrationDraftBox;
    final raw = box.get(_draftKey);
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
      _draftKey,
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

  Future<Result<void>> submit({
    String? specialtyLabel,
    String? cityLabel,
    String? phone,
  }) async {
    final result = await ref
        .read(submitRegistrationUseCaseProvider)
        .call(
          state,
          specialtyLabel: specialtyLabel,
          cityLabel: cityLabel,
          phone: phone,
        );
    if (result.isOk) {
      await _clearDraft();
      await ref
          .read(hiveServiceProvider)
          .settingsBox
          .put(SettingsKeys.providerRegistrationSubmitted, 'true');
    }
    return result;
  }

  Future<void> _clearDraft() async {
    final box = ref.read(hiveServiceProvider).providerRegistrationDraftBox;
    await box.delete(_draftKey);
    state = const DoctorRegistrationDraft();
  }
}

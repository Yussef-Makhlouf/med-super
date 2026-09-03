import 'package:med_super/core/error/result.dart';
import 'package:med_super/features/provider_registration/domain/entities/doctor_registration_draft.dart';
import 'package:med_super/features/provider_registration/domain/entities/doctor_registration_status.dart';

abstract class ProviderRegistrationRepository {
  Future<Result<void>> submit(
    DoctorRegistrationDraft draft, {
    String? specialtyLabel,
    String? cityLabel,
    String? phone,
  });

  /// `null` means the caller never self-registered as a doctor at all.
  Future<Result<DoctorRegistrationStatus?>> getMyStatus();
}

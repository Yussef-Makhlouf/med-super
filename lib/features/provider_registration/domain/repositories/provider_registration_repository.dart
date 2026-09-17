import 'package:med_super/core/error/result.dart';
import 'package:med_super/features/provider_registration/domain/entities/doctor_registration_draft.dart';
import 'package:med_super/features/provider_registration/domain/entities/doctor_registration_status.dart';

abstract class ProviderRegistrationRepository {
  /// Submits the registration, then uploads `draft.documents` for real
  /// against the newly created `doctorId` (File 12 Part 48) — a single
  /// `Result` covering both steps, since a document failing to upload after
  /// a successful registration still leaves the applicant with a real,
  /// submitted PENDING application; the caller decides how to surface that.
  Future<Result<void>> submit(
    DoctorRegistrationDraft draft, {
    String? specialtyLabel,
    String? cityLabel,
    String? phone,
  });

  /// `null` means the caller never self-registered as a doctor at all.
  Future<Result<DoctorRegistrationStatus?>> getMyStatus();
}

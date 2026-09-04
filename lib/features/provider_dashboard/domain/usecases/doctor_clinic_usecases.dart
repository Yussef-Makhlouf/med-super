import 'package:med_super/core/error/result.dart';
import '../entities/doctor_clinic.dart';
import '../repositories/provider_dashboard_repository.dart';

/// `GET /v1/doctors/me/clinics` — every clinic/branch the caller practises
/// at. Replaces the mock-only single-clinic "clinic settings" read.
class GetMyClinicsUseCase {
  const GetMyClinicsUseCase(this._repository);

  final ProviderDashboardRepository _repository;

  Future<Result<List<DoctorClinic>>> call() => _repository.getMyClinics();
}

/// `PATCH /v1/doctors/me/clinics/branches/{branchId}` — operational fields
/// only. Verification status, region/country codes and the clinic's legal
/// details are Admin-controlled and not accepted here.
class UpdateMyClinicBranchUseCase {
  const UpdateMyClinicBranchUseCase(this._repository);

  final ProviderDashboardRepository _repository;

  Future<Result<DoctorClinic>> call({
    required String branchId,
    String? phone,
    String? ianaTimezone,
    String? addressLine1,
    String? addressCity,
  }) {
    return _repository.updateMyClinicBranch(
      branchId: branchId,
      phone: phone,
      ianaTimezone: ianaTimezone,
      addressLine1: addressLine1,
      addressCity: addressCity,
    );
  }
}

/// `PATCH /v1/doctors/me/clinics/affiliations/{affiliationId}` — pause or
/// resume practising at a branch.
///
/// Pausing stops **future** slot generation only. Appointments patients have
/// already booked are untouched and must still be honoured or cancelled
/// individually — this is not a way to clear a calendar.
class SetMyAffiliationActiveUseCase {
  const SetMyAffiliationActiveUseCase(this._repository);

  final ProviderDashboardRepository _repository;

  Future<Result<DoctorClinic>> call({
    required String affiliationId,
    required bool active,
  }) {
    return _repository.setMyAffiliationActive(
      affiliationId: affiliationId,
      active: active,
    );
  }
}

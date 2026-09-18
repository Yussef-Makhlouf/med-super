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

/// `POST /v1/doctors/me/clinics/{clinicId}/branches` — add another branch
/// under a clinic the caller is already affiliated with. This does not
/// create a brand-new clinic; `clinicId` must be one the doctor already
/// practises at.
class CreateMyClinicBranchUseCase {
  const CreateMyClinicBranchUseCase(this._repository);

  final ProviderDashboardRepository _repository;

  Future<Result<DoctorClinic>> call({
    required String clinicId,
    required String phone,
    required String ianaTimezone,
    required String addressLine1,
    required String addressCity,
    required String regionCode,
    required String countryCode,
    required double consultFee,
  }) {
    return _repository.createMyClinicBranch(
      clinicId: clinicId,
      phone: phone,
      ianaTimezone: ianaTimezone,
      addressLine1: addressLine1,
      addressCity: addressCity,
      regionCode: regionCode,
      countryCode: countryCode,
      consultFee: consultFee,
    );
  }
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
/// resume practising at a branch, and/or change the consultation fee. The
/// doctor owns this fee commercially; the Admin only verifies license and
/// documents, never the price.
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
    double? consultFee,
  }) {
    return _repository.setMyAffiliationActive(
      affiliationId: affiliationId,
      active: active,
      consultFee: consultFee,
    );
  }
}

/// `DELETE /v1/doctors/me/clinics/branches/{branchId}` — remove the caller's
/// relationship to a branch.
///
/// Never a raw table delete from the caller's point of view: if the branch is
/// shared with another doctor, only this doctor's affiliation is detached and
/// the branch survives for them; if not shared, the branch and its address
/// are removed too. Blocked with a `BRANCH_HAS_BOOKINGS` conflict (surfaced
/// via [providerFailureMessage]) while the affiliation still has `HELD` or
/// `CONFIRMED` appointments — the doctor must resolve those first.
class DeleteMyClinicBranchUseCase {
  const DeleteMyClinicBranchUseCase(this._repository);

  final ProviderDashboardRepository _repository;

  Future<Result<void>> call({required String branchId}) {
    return _repository.deleteMyClinicBranch(branchId: branchId);
  }
}

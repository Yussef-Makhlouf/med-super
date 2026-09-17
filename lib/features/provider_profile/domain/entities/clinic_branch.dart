/// Mirrors the backend's `ProviderStatus` Prisma enum (PENDING / VERIFIED /
/// SUSPENDED) — shared by both `Clinic.status` and `ClinicBranch.status`.
enum ClinicBranchStatus { pending, verified, suspended }

/// The branch's physical address — from the backend's `Address` relation
/// (`clinic-branch.repository.ts`'s `BRANCH_WITH_RELATIONS` include).
class ClinicBranchAddress {
  const ClinicBranchAddress({
    required this.line1,
    required this.city,
    required this.regionCode,
    required this.countryCode,
    this.geoLat,
    this.geoLng,
  });

  final String line1;
  final String city;
  final String regionCode;
  final String countryCode;
  final double? geoLat;
  final double? geoLng;
}

/// The parent clinic — from the backend's `Clinic` relation (same include).
class ClinicSummary {
  const ClinicSummary({
    required this.id,
    required this.legalName,
    required this.brandName,
    required this.status,
    this.taxId,
    this.regionCode,
  });

  final String id;
  final String legalName;
  final String brandName;
  final ClinicBranchStatus status;
  final String? taxId;
  final String? regionCode;
}

/// Clinic branch detail — pure domain.
///
/// Backed by `GET /v1/clinic-branches/:branchId`
/// (`clinic-reservations/src/modules/provider-directory/api/clinic-branches.controller.ts`),
/// optional auth. The backend returns the raw Prisma `ClinicBranch` row plus
/// its `address`/`clinic` relations (`ClinicBranchWithRelations` —
/// `clinic-branch.repository.ts:18`), so the wire shape is snake_case, not a
/// hand-shaped DTO.
class ClinicBranch {
  const ClinicBranch({
    required this.id,
    required this.clinicId,
    required this.phone,
    required this.ianaTimezone,
    required this.status,
    required this.address,
    required this.clinic,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String clinicId;
  final String phone;
  final String ianaTimezone;
  final ClinicBranchStatus status;
  final ClinicBranchAddress address;
  final ClinicSummary clinic;
  final DateTime? createdAt;
  final DateTime? updatedAt;
}

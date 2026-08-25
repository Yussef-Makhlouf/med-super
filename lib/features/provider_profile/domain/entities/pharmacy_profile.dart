/// Physical address of a [PharmacyBranchInfo] — raw Prisma `Address` fields
/// (see clinic-reservations' `provider-directory` module schema), snake_case
/// on the wire. Structurally identical to `ClinicAddress`
/// (`clinic_profile.dart`) — both branch kinds share the same backend
/// `Address` model — but kept as its own type since `PharmacyProfile` is its
/// own feature slice, not a variant of `ClinicProfile`.
class PharmacyAddress {
  const PharmacyAddress({
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

/// One physical branch of a [PharmacyProfile], from the `branches` array of
/// `GET /v1/pharmacies/{pharmacyId}` (raw Prisma `PharmacyBranch` + `address`
/// include — clinic-reservations' `PharmacyRepository.findByIdWithBranches`).
///
/// Unlike `ClinicBranchInfo`, this carries [deliveryCapable] —
/// `PharmacyBranch.delivery_capable` has no equivalent on `ClinicBranch`,
/// which is the one real field-level divergence between the two provider
/// types confirmed against `prisma/schema/provider-directory.prisma`.
class PharmacyBranchInfo {
  const PharmacyBranchInfo({
    required this.id,
    required this.phone,
    required this.ianaTimezone,
    required this.deliveryCapable,
    required this.status,
    required this.address,
  });

  final String id;
  final String phone;
  final String ianaTimezone;
  final bool deliveryCapable;
  final String status;
  final PharmacyAddress address;
}

/// Public pharmacy detail — pure domain entity for
/// `GET /v1/pharmacies/{pharmacyId}` (optional auth; VERIFIED-only unless
/// caller is Admin — see `GetPharmacyUseCase`). The real backend returns the
/// raw Prisma `Pharmacy` row (snake_case, no dedicated response DTO) plus its
/// `branches` include — the same "raw Prisma leak" pattern already mirrored
/// by `DoctorProfileDto` (doctor-detail) and `ClinicProfileDto`
/// (clinic-detail).
class PharmacyProfile {
  const PharmacyProfile({
    required this.id,
    required this.legalName,
    required this.brandName,
    required this.status,
    required this.branches,
    this.taxId,
    this.regionCode,
  });

  final String id;
  final String legalName;
  final String brandName;
  final String status;
  final String? taxId;
  final String? regionCode;
  final List<PharmacyBranchInfo> branches;
}

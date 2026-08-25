/// Physical address of a [ClinicBranchInfo] — raw Prisma `Address` fields
/// (see clinic-reservations' `provider-directory` module schema), snake_case
/// on the wire.
class ClinicAddress {
  const ClinicAddress({
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

/// One physical branch of a [ClinicProfile], from the `branches` array of
/// `GET /v1/clinics/{clinicId}` (raw Prisma `ClinicBranch` + `address`
/// include — clinic-reservations' `ClinicRepository.findByIdWithBranches`).
class ClinicBranchInfo {
  const ClinicBranchInfo({
    required this.id,
    required this.phone,
    required this.ianaTimezone,
    required this.status,
    required this.address,
  });

  final String id;
  final String phone;
  final String ianaTimezone;
  final String status;
  final ClinicAddress address;
}

/// Public clinic detail — pure domain entity for `GET /v1/clinics/{clinicId}`
/// (optional auth; VERIFIED-only unless caller is Admin — see
/// `GetClinicUseCase`). The real backend returns the raw Prisma `Clinic` row
/// (snake_case, no dedicated response DTO) plus its `branches` include —
/// the same "raw Prisma leak" pattern already mirrored by
/// `DoctorProfileDto` for the doctor-detail endpoint.
class ClinicProfile {
  const ClinicProfile({
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
  final List<ClinicBranchInfo> branches;
}

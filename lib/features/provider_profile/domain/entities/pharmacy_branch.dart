/// One pharmacy branch's address — from the real backend's `address`
/// relation (`GET /v1/pharmacy-branches/{branchId}`).
class PharmacyBranchAddress {
  const PharmacyBranchAddress({
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

/// Full public pharmacy-branch detail — pure domain.
///
/// Mirrors the real backend's `PharmacyBranchWithRelations`
/// (`PharmacyBranchesController.get`, `GET /v1/pharmacy-branches/{branchId}`,
/// optional auth — VERIFIED-only unless the caller is Admin, enforced
/// server-side by `GetPharmacyBranchUseCase`).
class PharmacyBranch {
  const PharmacyBranch({
    required this.id,
    required this.pharmacyId,
    required this.pharmacyName,
    required this.phone,
    required this.ianaTimezone,
    required this.deliveryCapable,
    required this.status,
    required this.address,
  });

  final String id;
  final String pharmacyId;

  /// `pharmacy.brand_name`, falling back to `pharmacy.legal_name` — see
  /// `PharmacyBranchDto.fromJson`.
  final String pharmacyName;
  final String phone;
  final String ianaTimezone;
  final bool deliveryCapable;

  /// One of `PENDING` / `VERIFIED` / `SUSPENDED` (backend
  /// `ProviderStatus` enum) — kept as the raw string rather than a Dart enum
  /// since the UI only ever needs the `VERIFIED` check below.
  final String status;
  final PharmacyBranchAddress address;

  bool get isVerified => status == 'VERIFIED';
}

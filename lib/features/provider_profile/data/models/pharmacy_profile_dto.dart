import 'package:med_super/features/provider_profile/domain/entities/pharmacy_profile.dart';

/// Parses a numeric field that may arrive as a JSON number OR as a string —
/// Prisma's `Decimal` (used for `Address.geo_lat`/`geo_lng`) serializes to a
/// string via its own `toJSON`, while a hand-written mock may send a plain
/// double. Returns null for a missing/unparseable value rather than
/// throwing. Mirrors `ClinicProfileDto`'s `_toDoubleOrNull`.
double? _toDoubleOrNull(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  return double.tryParse('$value');
}

class PharmacyAddressDto {
  const PharmacyAddressDto({
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

  /// The real backend (`PharmacyRepository.findByIdWithBranches`'s `address`
  /// include) returns the raw Prisma `Address` row, snake_case. Real-backend
  /// keys are tried first, falling back to a hypothetical camelCase mock
  /// shape — mirrors `ClinicAddressDto`'s dual-key parsing style.
  factory PharmacyAddressDto.fromJson(Map<String, dynamic> json) =>
      PharmacyAddressDto(
        line1: json['line1'] as String? ?? '',
        city: json['city'] as String? ?? '',
        regionCode:
            (json['region_code'] ?? json['regionCode']) as String? ?? '',
        countryCode:
            (json['country_code'] ?? json['countryCode']) as String? ?? '',
        geoLat: _toDoubleOrNull(json['geo_lat'] ?? json['geoLat']),
        geoLng: _toDoubleOrNull(json['geo_lng'] ?? json['geoLng']),
      );

  PharmacyAddress toEntity() => PharmacyAddress(
    line1: line1,
    city: city,
    regionCode: regionCode,
    countryCode: countryCode,
    geoLat: geoLat,
    geoLng: geoLng,
  );
}

class PharmacyBranchInfoDto {
  const PharmacyBranchInfoDto({
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
  final PharmacyAddressDto address;

  /// The real backend (`PharmacyRepository`'s `PHARMACY_WITH_BRANCHES`
  /// include) returns the raw Prisma `PharmacyBranch` row, snake_case, with a
  /// nested `address` object (never absent — `address_id` is a required FK)
  /// — but this still falls back to an empty address rather than throwing if
  /// a mock omits it. `delivery_capable` is the one field `ClinicBranch`
  /// doesn't have (verified against `prisma/schema/provider-directory.prisma`),
  /// defaulting to `false` when missing.
  factory PharmacyBranchInfoDto.fromJson(Map<String, dynamic> json) =>
      PharmacyBranchInfoDto(
        id: json['id'] as String? ?? '',
        phone: json['phone'] as String? ?? '',
        ianaTimezone:
            (json['iana_timezone'] ?? json['ianaTimezone']) as String? ?? '',
        deliveryCapable:
            (json['delivery_capable'] ?? json['deliveryCapable']) as bool? ??
            false,
        status: json['status'] as String? ?? 'PENDING',
        address: PharmacyAddressDto.fromJson(
          (json['address'] as Map<String, dynamic>?) ?? const {},
        ),
      );

  PharmacyBranchInfo toEntity() => PharmacyBranchInfo(
    id: id,
    phone: phone,
    ianaTimezone: ianaTimezone,
    deliveryCapable: deliveryCapable,
    status: status,
    address: address.toEntity(),
  );
}

class PharmacyProfileDto {
  const PharmacyProfileDto({
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
  final List<PharmacyBranchInfoDto> branches;

  /// The real backend (`GetPharmacyUseCase` / `GET /v1/pharmacies/{pharmacyId}`)
  /// returns the raw Prisma `Pharmacy` row — snake_case, no dedicated
  /// response DTO — plus its `branches` include. Real-backend keys are tried
  /// first, falling back to a hypothetical camelCase mock shape, matching
  /// `ClinicProfileDto.fromJson`'s dual-key parsing style. Missing/malformed
  /// fields default rather than throw, so a partial mock never crashes the
  /// screen.
  factory PharmacyProfileDto.fromJson(Map<String, dynamic> json) {
    final branches = (json['branches'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(PharmacyBranchInfoDto.fromJson)
        .toList();

    return PharmacyProfileDto(
      id: json['id'] as String? ?? '',
      legalName: (json['legal_name'] ?? json['legalName']) as String? ?? '',
      brandName: (json['brand_name'] ?? json['brandName']) as String? ?? '',
      status: json['status'] as String? ?? 'PENDING',
      taxId: (json['tax_id'] ?? json['taxId']) as String?,
      regionCode: (json['region_code'] ?? json['regionCode']) as String?,
      branches: branches,
    );
  }

  PharmacyProfile toEntity() => PharmacyProfile(
    id: id,
    legalName: legalName,
    brandName: brandName,
    status: status,
    taxId: taxId,
    regionCode: regionCode,
    branches: branches.map((b) => b.toEntity()).toList(),
  );
}

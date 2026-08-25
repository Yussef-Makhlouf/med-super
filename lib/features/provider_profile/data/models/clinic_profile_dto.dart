import 'package:med_super/features/provider_profile/domain/entities/clinic_profile.dart';

/// Parses a numeric field that may arrive as a JSON number OR as a string —
/// Prisma's `Decimal` (used for `Address.geo_lat`/`geo_lng`) serializes to a
/// string via its own `toJSON`, while a hand-written mock may send a plain
/// double. Returns null for a missing/unparseable value rather than
/// throwing.
double? _toDoubleOrNull(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  return double.tryParse('$value');
}

class ClinicAddressDto {
  const ClinicAddressDto({
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

  /// The real backend (`ClinicRepository.findByIdWithBranches`'s `address`
  /// include) returns the raw Prisma `Address` row, snake_case. Real-backend
  /// keys are tried first, falling back to a hypothetical camelCase mock
  /// shape — mirrors `DoctorProfileDto`'s dual-key parsing style.
  factory ClinicAddressDto.fromJson(Map<String, dynamic> json) =>
      ClinicAddressDto(
        line1: json['line1'] as String? ?? '',
        city: json['city'] as String? ?? '',
        regionCode:
            (json['region_code'] ?? json['regionCode']) as String? ?? '',
        countryCode:
            (json['country_code'] ?? json['countryCode']) as String? ?? '',
        geoLat: _toDoubleOrNull(json['geo_lat'] ?? json['geoLat']),
        geoLng: _toDoubleOrNull(json['geo_lng'] ?? json['geoLng']),
      );

  ClinicAddress toEntity() => ClinicAddress(
    line1: line1,
    city: city,
    regionCode: regionCode,
    countryCode: countryCode,
    geoLat: geoLat,
    geoLng: geoLng,
  );
}

class ClinicBranchInfoDto {
  const ClinicBranchInfoDto({
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
  final ClinicAddressDto address;

  /// The real backend (`ClinicRepository`'s `CLINIC_WITH_BRANCHES` include)
  /// returns the raw Prisma `ClinicBranch` row, snake_case, with a nested
  /// `address` object (never absent — `address_id` is a required FK) — but
  /// this still falls back to an empty address rather than throwing if a
  /// mock omits it.
  factory ClinicBranchInfoDto.fromJson(Map<String, dynamic> json) =>
      ClinicBranchInfoDto(
        id: json['id'] as String? ?? '',
        phone: json['phone'] as String? ?? '',
        ianaTimezone:
            (json['iana_timezone'] ?? json['ianaTimezone']) as String? ?? '',
        status: json['status'] as String? ?? 'PENDING',
        address: ClinicAddressDto.fromJson(
          (json['address'] as Map<String, dynamic>?) ?? const {},
        ),
      );

  ClinicBranchInfo toEntity() => ClinicBranchInfo(
    id: id,
    phone: phone,
    ianaTimezone: ianaTimezone,
    status: status,
    address: address.toEntity(),
  );
}

class ClinicProfileDto {
  const ClinicProfileDto({
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
  final List<ClinicBranchInfoDto> branches;

  /// The real backend (`GetClinicUseCase` / `GET /v1/clinics/{clinicId}`)
  /// returns the raw Prisma `Clinic` row — snake_case, no dedicated response
  /// DTO — plus its `branches` include. Real-backend keys are tried first,
  /// falling back to a hypothetical camelCase mock shape, matching
  /// `DoctorProfileDto.fromJson`'s dual-key parsing style. Missing/malformed
  /// fields default rather than throw, so a partial mock never crashes the
  /// screen.
  factory ClinicProfileDto.fromJson(Map<String, dynamic> json) {
    final branches = (json['branches'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(ClinicBranchInfoDto.fromJson)
        .toList();

    return ClinicProfileDto(
      id: json['id'] as String? ?? '',
      legalName:
          (json['legal_name'] ?? json['legalName']) as String? ?? '',
      brandName:
          (json['brand_name'] ?? json['brandName']) as String? ?? '',
      status: json['status'] as String? ?? 'PENDING',
      taxId: (json['tax_id'] ?? json['taxId']) as String?,
      regionCode: (json['region_code'] ?? json['regionCode']) as String?,
      branches: branches,
    );
  }

  ClinicProfile toEntity() => ClinicProfile(
    id: id,
    legalName: legalName,
    brandName: brandName,
    status: status,
    taxId: taxId,
    regionCode: regionCode,
    branches: branches.map((b) => b.toEntity()).toList(),
  );
}

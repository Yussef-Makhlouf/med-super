import 'package:med_super/features/provider_profile/domain/entities/clinic_branch.dart';

double? _parseDecimal(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  return double.tryParse('$value');
}

ClinicBranchStatus _statusFromJson(dynamic value) {
  switch ('$value'.toUpperCase()) {
    case 'VERIFIED':
      return ClinicBranchStatus.verified;
    case 'SUSPENDED':
      return ClinicBranchStatus.suspended;
    case 'PENDING':
    default:
      return ClinicBranchStatus.pending;
  }
}

class ClinicBranchAddressDto {
  const ClinicBranchAddressDto({
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

  /// Raw Prisma `Address` row, snake_case — see `prisma/schema/provider-directory.prisma`.
  /// `geo_lat`/`geo_lng` are Prisma `Decimal` columns, serialized as JSON
  /// strings (e.g. `"30.0561"`), not numbers — parse via `num.tryParse`
  /// rather than an `as num?` cast, which throws on a `String` value.
  factory ClinicBranchAddressDto.fromJson(Map<String, dynamic> json) =>
      ClinicBranchAddressDto(
        line1: json['line1'] as String? ?? '',
        city: json['city'] as String? ?? '',
        regionCode: json['region_code'] as String? ?? '',
        countryCode: json['country_code'] as String? ?? '',
        geoLat: _parseDecimal(json['geo_lat']),
        geoLng: _parseDecimal(json['geo_lng']),
      );

  ClinicBranchAddress toEntity() => ClinicBranchAddress(
    line1: line1,
    city: city,
    regionCode: regionCode,
    countryCode: countryCode,
    geoLat: geoLat,
    geoLng: geoLng,
  );
}

class ClinicSummaryDto {
  const ClinicSummaryDto({
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

  /// Raw Prisma `Clinic` row, snake_case.
  factory ClinicSummaryDto.fromJson(Map<String, dynamic> json) =>
      ClinicSummaryDto(
        id: json['id'] as String? ?? '',
        legalName: json['legal_name'] as String? ?? '',
        brandName: json['brand_name'] as String? ?? '',
        status: _statusFromJson(json['status']),
        taxId: json['tax_id'] as String?,
        regionCode: json['region_code'] as String?,
      );

  ClinicSummary toEntity() => ClinicSummary(
    id: id,
    legalName: legalName,
    brandName: brandName,
    status: status,
    taxId: taxId,
    regionCode: regionCode,
  );
}

/// Parses the raw Prisma `ClinicBranchWithRelations` shape returned by
/// `GET /v1/clinic-branches/:branchId`
/// (`clinic-branch.repository.ts:18` — `ClinicBranch` + `address`/`clinic`
/// relations, all snake_case, unlike the doctor-profile endpoint's flat
/// camelCase). Every field beyond `id` falls back to a safe default so a
/// partial/mock payload never throws.
class ClinicBranchDto {
  const ClinicBranchDto({
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
  final ClinicBranchAddressDto address;
  final ClinicSummaryDto clinic;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory ClinicBranchDto.fromJson(Map<String, dynamic> json) {
    final addressJson = json['address'] as Map<String, dynamic>?;
    final clinicJson = json['clinic'] as Map<String, dynamic>?;

    return ClinicBranchDto(
      id: json['id'] as String? ?? '',
      clinicId: json['clinic_id'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      ianaTimezone: json['iana_timezone'] as String? ?? '',
      status: _statusFromJson(json['status']),
      address: addressJson != null
          ? ClinicBranchAddressDto.fromJson(addressJson)
          : const ClinicBranchAddressDto(
              line1: '',
              city: '',
              regionCode: '',
              countryCode: '',
            ),
      clinic: clinicJson != null
          ? ClinicSummaryDto.fromJson(clinicJson)
          : const ClinicSummaryDto(
              id: '',
              legalName: '',
              brandName: '',
              status: ClinicBranchStatus.pending,
            ),
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? ''),
      updatedAt: DateTime.tryParse(json['updated_at'] as String? ?? ''),
    );
  }

  ClinicBranch toEntity() => ClinicBranch(
    id: id,
    clinicId: clinicId,
    phone: phone,
    ianaTimezone: ianaTimezone,
    status: status,
    address: address.toEntity(),
    clinic: clinic.toEntity(),
    createdAt: createdAt,
    updatedAt: updatedAt,
  );
}

import 'package:med_super/features/provider_profile/domain/entities/pharmacy_branch.dart';

/// Parses `GET /v1/pharmacy-branches/{branchId}`'s response.
///
/// Unlike the doctor-detail endpoint (which returns a bespoke flat camelCase
/// shape), this controller returns the raw Prisma `PharmacyBranchWithRelations`
/// object as-is — every field name here is the backend's actual snake_case
/// model field (verified against
/// `clinic-reservations/prisma/schema/provider-directory.prisma`'s
/// `PharmacyBranch`/`Pharmacy`/`Address` models and
/// `GetPharmacyBranchUseCase`/`PharmacyBranchRepository.findByIdWithRelations`),
/// not a guess. Every field still falls back to a safe default so a
/// partially-shaped mock or a future backend tweak doesn't crash parsing.
class PharmacyBranchDto {
  const PharmacyBranchDto({
    required this.id,
    required this.pharmacyId,
    required this.pharmacyName,
    required this.phone,
    required this.ianaTimezone,
    required this.deliveryCapable,
    required this.status,
    required this.addressLine1,
    required this.addressCity,
    required this.addressRegionCode,
    required this.addressCountryCode,
    this.geoLat,
    this.geoLng,
  });

  final String id;
  final String pharmacyId;
  final String pharmacyName;
  final String phone;
  final String ianaTimezone;
  final bool deliveryCapable;
  final String status;
  final String addressLine1;
  final String addressCity;
  final String addressRegionCode;
  final String addressCountryCode;
  final double? geoLat;
  final double? geoLng;

  factory PharmacyBranchDto.fromJson(Map<String, dynamic> json) {
    final pharmacy = json['pharmacy'] as Map<String, dynamic>? ?? const {};
    final address = json['address'] as Map<String, dynamic>? ?? const {};

    return PharmacyBranchDto(
      id: json['id'] as String? ?? '',
      pharmacyId:
          json['pharmacy_id'] as String? ?? pharmacy['id'] as String? ?? '',
      // `brand_name` is the public-facing name; `legal_name` is the
      // registration name — prefer brand, fall back to legal.
      pharmacyName:
          pharmacy['brand_name'] as String? ??
          pharmacy['legal_name'] as String? ??
          '',
      phone: json['phone'] as String? ?? '',
      ianaTimezone: json['iana_timezone'] as String? ?? '',
      deliveryCapable: json['delivery_capable'] as bool? ?? false,
      status: json['status'] as String? ?? 'PENDING',
      addressLine1: address['line1'] as String? ?? '',
      addressCity: address['city'] as String? ?? '',
      addressRegionCode: address['region_code'] as String? ?? '',
      addressCountryCode: address['country_code'] as String? ?? '',
      geoLat: (address['geo_lat'] as num?)?.toDouble(),
      geoLng: (address['geo_lng'] as num?)?.toDouble(),
    );
  }

  PharmacyBranch toEntity() => PharmacyBranch(
    id: id,
    pharmacyId: pharmacyId,
    pharmacyName: pharmacyName,
    phone: phone,
    ianaTimezone: ianaTimezone,
    deliveryCapable: deliveryCapable,
    status: status,
    address: PharmacyBranchAddress(
      line1: addressLine1,
      city: addressCity,
      regionCode: addressRegionCode,
      countryCode: addressCountryCode,
      geoLat: geoLat,
      geoLng: geoLng,
    ),
  );
}

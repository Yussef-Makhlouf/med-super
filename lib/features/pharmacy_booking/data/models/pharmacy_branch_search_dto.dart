import 'package:med_super/features/pharmacy_booking/domain/entities/pharmacy.dart';

/// Parses one item of `GET /v1/pharmacy-branches/search`'s response
/// (`clinic-reservations` `SearchPharmacyBranchItem`, File 12 Part 37) — a
/// dedicated camelCase response shape (unlike the branch-detail endpoint's
/// raw Prisma passthrough), so field names here match that use-case's
/// `toSearchItem` mapping directly.
class PharmacyBranchSearchItemDto {
  const PharmacyBranchSearchItemDto({
    required this.branchId,
    required this.brandName,
    required this.addressLine1,
    required this.geoLat,
    required this.geoLng,
    required this.deliveryCapable,
    this.distanceKm,
  });

  final String branchId;
  final String brandName;
  final String addressLine1;
  final double? geoLat;
  final double? geoLng;
  final bool deliveryCapable;
  final double? distanceKm;

  factory PharmacyBranchSearchItemDto.fromJson(Map<String, dynamic> json) {
    final address = json['address'] as Map<String, dynamic>? ?? const {};
    return PharmacyBranchSearchItemDto(
      branchId: json['branchId'] as String? ?? '',
      brandName: json['brandName'] as String? ?? '',
      addressLine1: address['line1'] as String? ?? '',
      geoLat: (address['geoLat'] as num?)?.toDouble(),
      geoLng: (address['geoLng'] as num?)?.toDouble(),
      deliveryCapable: json['deliveryCapable'] as bool? ?? false,
      distanceKm: (json['distanceKm'] as num?)?.toDouble(),
    );
  }

  /// A branch can still be selected when its address has no coordinates; it
  /// is simply omitted from the map by [PharmacyMapView].
  Pharmacy? toEntity() {
    return Pharmacy(
      id: branchId,
      name: brandName,
      address: addressLine1,
      latitude: geoLat,
      longitude: geoLng,
      deliveryCapable: deliveryCapable,
      distanceKm: distanceKm,
    );
  }
}

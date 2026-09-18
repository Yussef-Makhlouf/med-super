import 'package:med_super/features/lab_booking/domain/entities/lab_branch.dart';

/// Parses one item of `GET /v1/lab-branches/search`'s response
/// (`clinic-reservations` `SearchLabBranchItem`) — a dedicated camelCase
/// response shape (unlike the branch-detail endpoint's raw Prisma
/// passthrough), so field names here match that use-case's `toSearchItem`
/// mapping directly. Mirrors `PharmacyBranchSearchItemDto`.
class LabBranchDto {
  const LabBranchDto({
    required this.branchId,
    required this.brandName,
    required this.addressLine1,
    required this.geoLat,
    required this.geoLng,
    required this.homeCollectionCapable,
    this.distanceKm,
  });

  final String branchId;
  final String brandName;
  final String addressLine1;
  final double? geoLat;
  final double? geoLng;
  final bool homeCollectionCapable;
  final double? distanceKm;

  factory LabBranchDto.fromJson(Map<String, dynamic> json) {
    final address = json['address'] as Map<String, dynamic>? ?? const {};
    return LabBranchDto(
      branchId: json['branchId'] as String? ?? '',
      brandName: json['brandName'] as String? ?? '',
      addressLine1: address['line1'] as String? ?? '',
      geoLat: (address['geoLat'] as num?)?.toDouble(),
      geoLng: (address['geoLng'] as num?)?.toDouble(),
      homeCollectionCapable: json['homeCollectionCapable'] as bool? ?? false,
      distanceKm: (json['distanceKm'] as num?)?.toDouble(),
    );
  }

  /// A branch can still be selected when its address has no coordinates; it
  /// is simply omitted from the map by [LabBranchesMapView].
  LabBranch toEntity() => LabBranch(
    id: branchId,
    name: brandName,
    address: addressLine1,
    latitude: geoLat,
    longitude: geoLng,
    homeCollectionCapable: homeCollectionCapable,
    distanceKm: distanceKm,
  );
}

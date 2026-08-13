import 'package:med_super/features/lab_booking/domain/entities/lab_partner.dart';
import 'package:med_super/features/lab_booking/domain/entities/lab_partner_status.dart';

class LabPartnerDto {
  const LabPartnerDto({
    required this.id,
    required this.name,
    required this.address,
    required this.distanceKm,
    required this.rating,
    required this.ratingCount,
    required this.startingPrice,
    required this.latitude,
    required this.longitude,
    required this.status,
  });

  final String id;
  final String name;
  final String address;
  final double distanceKm;
  final double rating;
  final int ratingCount;
  final int startingPrice;
  final double latitude;
  final double longitude;
  final LabPartnerStatus status;

  factory LabPartnerDto.fromJson(Map<String, dynamic> json) => LabPartnerDto(
    id: json['id'] as String,
    name: json['name'] as String,
    address: json['address'] as String? ?? '',
    distanceKm: (json['distance_km'] as num?)?.toDouble() ?? 0,
    rating: (json['rating'] as num?)?.toDouble() ?? 0,
    ratingCount: json['rating_count'] as int? ?? 0,
    startingPrice: json['starting_price'] as int? ?? 0,
    latitude: (json['latitude'] as num?)?.toDouble() ?? 0,
    longitude: (json['longitude'] as num?)?.toDouble() ?? 0,
    status: LabPartnerStatus.fromApiValue(json['status'] as String?),
  );

  LabPartner toEntity() => LabPartner(
    id: id,
    name: name,
    address: address,
    distanceKm: distanceKm,
    rating: rating,
    ratingCount: ratingCount,
    startingPrice: startingPrice,
    latitude: latitude,
    longitude: longitude,
    status: status,
  );
}

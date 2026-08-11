import 'package:med_super/features/lab_booking/domain/entities/lab_partner.dart';

class LabPartnerDto {
  const LabPartnerDto({
    required this.id,
    required this.name,
    required this.distanceKm,
    required this.rating,
    required this.ratingCount,
    required this.totalPrice,
    required this.latitude,
    required this.longitude,
  });

  final String id;
  final String name;
  final double distanceKm;
  final double rating;
  final int ratingCount;
  final int totalPrice;
  final double latitude;
  final double longitude;

  factory LabPartnerDto.fromJson(Map<String, dynamic> json) => LabPartnerDto(
    id: json['id'] as String,
    name: json['name'] as String,
    distanceKm: (json['distance_km'] as num?)?.toDouble() ?? 0,
    rating: (json['rating'] as num?)?.toDouble() ?? 0,
    ratingCount: json['rating_count'] as int? ?? 0,
    totalPrice: json['total_price'] as int? ?? 0,
    latitude: (json['latitude'] as num?)?.toDouble() ?? 0,
    longitude: (json['longitude'] as num?)?.toDouble() ?? 0,
  );

  LabPartner toEntity() => LabPartner(
    id: id,
    name: name,
    distanceKm: distanceKm,
    rating: rating,
    ratingCount: ratingCount,
    totalPrice: totalPrice,
    latitude: latitude,
    longitude: longitude,
  );
}

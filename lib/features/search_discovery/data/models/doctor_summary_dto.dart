import 'package:med_super/features/search_discovery/domain/entities/doctor_summary.dart';

class DoctorSummaryDto {
  const DoctorSummaryDto({
    required this.id,
    required this.name,
    required this.specialty,
    required this.experienceYears,
    required this.rating,
    required this.reviewCount,
    required this.locationLabel,
    required this.distanceKm,
    required this.consultationFee,
    required this.currency,
    required this.isVerified,
    this.photoUrl,
    this.specialtyKey,
  });

  final String id;
  final String name;
  final String specialty;
  final String? specialtyKey;
  final int experienceYears;
  final double rating;
  final int reviewCount;
  final String locationLabel;
  final double distanceKm;
  final int consultationFee;
  final String currency;
  final bool isVerified;
  final String? photoUrl;

  factory DoctorSummaryDto.fromJson(Map<String, dynamic> json) =>
      DoctorSummaryDto(
        id: json['id'] as String,
        name: json['name'] as String,
        specialty: json['specialty'] as String,
        specialtyKey: json['specialty_key'] as String?,
        experienceYears: json['experience_years'] as int? ?? 0,
        rating: (json['rating'] as num?)?.toDouble() ?? 0,
        reviewCount: json['review_count'] as int? ?? 0,
        locationLabel: json['location_label'] as String? ?? '',
        distanceKm: (json['distance_km'] as num?)?.toDouble() ?? 0,
        consultationFee: json['consultation_fee'] as int? ?? 0,
        currency: json['currency'] as String? ?? 'EGP',
        isVerified: json['is_verified'] as bool? ?? false,
        photoUrl: json['photo_url'] as String?,
      );

  DoctorSummary toEntity() => DoctorSummary(
        id: id,
        name: name,
        specialty: specialty,
        specialtyKey: specialtyKey,
        experienceYears: experienceYears,
        rating: rating,
        reviewCount: reviewCount,
        locationLabel: locationLabel,
        distanceKm: distanceKm,
        consultationFee: consultationFee,
        currency: currency,
        isVerified: isVerified,
        photoUrl: photoUrl,
      );
}

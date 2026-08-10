/// Compact doctor row for search results — pure domain.
class DoctorSummary {
  const DoctorSummary({
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
}

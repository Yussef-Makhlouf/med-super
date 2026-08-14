import 'available_day.dart';

/// Full public doctor profile — pure domain.
class DoctorProfile {
  const DoctorProfile({
    required this.id,
    required this.name,
    required this.specialty,
    required this.experienceYears,
    required this.rating,
    required this.reviewCount,
    required this.clinicName,
    required this.languages,
    required this.bio,
    required this.qualifications,
    required this.fellowships,
    required this.consultationFee,
    required this.currency,
    required this.isVerified,
    required this.isOnline,
    required this.availableDays,
    this.photoUrl,
    this.specialtyKey,
    this.clinicBranchId,
    this.ianaTimezone,
  });

  final String id;
  final String name;
  final String specialty;
  final String? specialtyKey;
  final int experienceYears;
  final double rating;
  final int reviewCount;
  final String clinicName;
  final List<String> languages;
  final String bio;
  final List<String> qualifications;
  final List<String> fellowships;
  final int consultationFee;
  final String currency;
  final bool isVerified;
  final bool isOnline;
  final String? photoUrl;
  final List<AvailableDay> availableDays;

  /// Needed to call the real Phase 3 slots endpoint
  /// (`GET /v1/doctors/{doctorId}/slots?clinicBranchId=`). Null means the
  /// caller falls back to [availableDays] (mock-only fake data) — see
  /// med-super/docs/backend_frontend_parity_matrix.md for why the real
  /// doctor-detail backend endpoint doesn't cleanly expose this yet.
  final String? clinicBranchId;
  final String? ianaTimezone;
}

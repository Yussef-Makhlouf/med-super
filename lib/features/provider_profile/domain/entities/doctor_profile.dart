import 'available_day.dart';

/// One of a doctor's clinic-branch affiliations, from the real backend's
/// `affiliations` array (`GET /v1/doctors/{id}`) — lets a caller show/pick
/// among more than one branch instead of only the top-level "primary" one.
class DoctorAffiliation {
  const DoctorAffiliation({
    required this.affiliationId,
    required this.clinicBranchId,
    required this.clinicName,
    required this.addressLine1,
    required this.city,
    required this.consultationFee,
    required this.currency,
    required this.ianaTimezone,
  });

  final String affiliationId;
  final String clinicBranchId;
  final String clinicName;

  /// The branch's own street address — distinct from [clinicName] (the
  /// clinic brand, shared by every branch of the same doctor), used as the
  /// branch picker's title so branches read as distinct places rather than
  /// N identical-looking rows.
  final String addressLine1;
  final String city;
  final String consultationFee;
  final String currency;
  final String ianaTimezone;
}

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
    required this.bio,
    required this.qualifications,
    required this.consultationFee,
    required this.currency,
    required this.isVerified,
    required this.availableDays,
    required this.affiliations,
    this.photoUrl,
    this.specialtyKey,
    this.clinicBranchId,
    this.ianaTimezone,
    this.affiliationId,
  });

  final String id;
  final String name;
  final String specialty;
  final String? specialtyKey;
  final int experienceYears;
  final double rating;
  final int reviewCount;
  final String clinicName;
  final String bio;
  final List<String> qualifications;
  final int consultationFee;
  final String currency;
  final bool isVerified;
  final String? photoUrl;
  final List<AvailableDay> availableDays;

  /// Every clinic-branch this doctor is affiliated with — real backend data
  /// (`GET /v1/doctors/{id}`'s `affiliations` array), not mock-only.
  final List<DoctorAffiliation> affiliations;

  /// Needed to call the real Phase 3 slots endpoint
  /// (`GET /v1/doctors/{doctorId}/slots?clinicBranchId=`) — parsed from the
  /// real backend's `affiliations[0].clinic_branch.id`
  /// (`DoctorProfileDto._fromRealJson`) or the mock's flat `clinic_branch_id`.
  /// Null only when a doctor genuinely has no (visible) affiliation, in
  /// which case the caller falls back to [availableDays] (mock-only fake
  /// data — a doctor with zero real affiliations has nothing to show here
  /// against a live backend either way).
  final String? clinicBranchId;
  final String? ianaTimezone;

  /// `doctorClinicAffiliationId` — required by the real Phase 4 hold
  /// contract (`POST /v1/appointments/hold`, File 10 §2.3). Parsed from the
  /// real backend's `affiliations[0].id`, or the mock's flat
  /// `affiliation_id`. Null means "don't offer booking" (no visible
  /// affiliation), not a parsing gap. See `lib/features/appointments/STATUS.md`.
  final String? affiliationId;
}

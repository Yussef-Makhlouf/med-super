import 'package:med_super/features/search_discovery/domain/entities/doctor_summary.dart';

class DoctorSummaryDto {
  const DoctorSummaryDto({
    required this.id,
    required this.name,
    required this.specialty,
    required this.locationLabel,
    required this.consultationFee,
    required this.currency,
    this.distanceKm,
    this.photoUrl,
    this.specialtyKey,
  });

  final String id;
  final String name;
  final String specialty;
  final String? specialtyKey;
  final String locationLabel;
  final double? distanceKm;
  final int consultationFee;
  final String currency;
  final String? photoUrl;

  /// The real backend's `GET /v1/doctors/search` item shape
  /// (`SearchDoctorItem`, `search-doctors.use-case.ts`) doesn't match the
  /// mock's field names 1:1 — `doctorId` not `id`, `consultFee` not
  /// `consultation_fee`, no `location_label` at all. Real-backend keys are
  /// tried first, falling back to the mock's shape. `experienceYears`/
  /// `rating`/`reviewCount`/`isVerified` were removed entirely
  /// (2026-09-03) — the real endpoint never returns the first two at all,
  /// and the latter two are real columns that are permanently zero/false
  /// with no reviews feature ever writing to them; none of the four were
  /// ever a meaningful signal here. `distanceKm` is null unless the caller
  /// passed `lat`/`lng` (the real backend never fabricates a distance
  /// without them) — not defaulted to `0`, which would read as "0 km away"
  /// instead of "unknown." `photoUrl` came back as `photo_url` from the
  /// mock's shape only — the real endpoint returns camelCase `photoUrl`
  /// like every other field here (added alongside `doctorId`/`consultFee`
  /// once the search query started projecting it).
  factory DoctorSummaryDto.fromJson(Map<String, dynamic> json) =>
      DoctorSummaryDto(
        id: (json['doctorId'] ?? json['id']) as String,
        name: json['name'] as String,
        specialty: json['specialty'] as String,
        specialtyKey:
            (json['specialtyKey'] ?? json['specialty_key']) as String?,
        locationLabel:
            (json['clinicName'] ?? json['location_label']) as String? ?? '',
        distanceKm: ((json['distanceKm'] ?? json['distance_km']) as num?)
            ?.toDouble(),
        consultationFee:
            double.tryParse('${json['consultFee'] ?? ''}')?.round() ??
            json['consultation_fee'] as int? ??
            0,
        currency: json['currency'] as String? ?? 'EGP',
        photoUrl: (json['photoUrl'] ?? json['photo_url']) as String?,
      );

  DoctorSummary toEntity() => DoctorSummary(
    id: id,
    name: name,
    specialty: specialty,
    specialtyKey: specialtyKey,
    locationLabel: locationLabel,
    distanceKm: distanceKm,
    consultationFee: consultationFee,
    currency: currency,
    photoUrl: photoUrl,
  );
}

import 'package:med_super/features/provider_profile/domain/entities/available_day.dart';
import 'package:med_super/features/provider_profile/domain/entities/doctor_profile.dart';
import 'package:med_super/features/provider_profile/domain/entities/time_slot.dart';

class DoctorAffiliationDto {
  const DoctorAffiliationDto({
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
  final String addressLine1;
  final String city;
  final String consultationFee;
  final String currency;
  final String ianaTimezone;

  /// Matches both the real backend's `DoctorAffiliationSummary`
  /// (`get-doctor.use-case.ts`) and the mock's shape — both are already
  /// flat camelCase with the same field names.
  factory DoctorAffiliationDto.fromJson(Map<String, dynamic> json) =>
      DoctorAffiliationDto(
        affiliationId: json['affiliationId'] as String? ?? '',
        clinicBranchId: json['clinicBranchId'] as String? ?? '',
        clinicName: json['clinicName'] as String? ?? '',
        addressLine1: json['addressLine1'] as String? ?? '',
        city: json['city'] as String? ?? '',
        consultationFee: '${json['consultationFee'] ?? ''}',
        currency: json['currency'] as String? ?? 'EGP',
        ianaTimezone: json['ianaTimezone'] as String? ?? 'Africa/Cairo',
      );

  DoctorAffiliation toEntity() => DoctorAffiliation(
    affiliationId: affiliationId,
    clinicBranchId: clinicBranchId,
    clinicName: clinicName,
    addressLine1: addressLine1,
    city: city,
    consultationFee: consultationFee,
    currency: currency,
    ianaTimezone: ianaTimezone,
  );
}

class DoctorProfileDto {
  const DoctorProfileDto({
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
  final List<DoctorAffiliationDto> affiliations;
  final String? clinicBranchId;
  final String? ianaTimezone;
  final String? affiliationId;

  /// Dispatches on shape: the real `GET /v1/doctors/{id}` response
  /// (`GetDoctorUseCase`, `provider-directory` module) is a **flat**
  /// camelCase object (`{id, name, specialty, experienceYears,
  /// affiliationId, clinicBranchId, affiliations: [...], ...}`) — not
  /// nested under a `doctor` key as an earlier reconciliation pass wrongly
  /// assumed (that shape never matched any real backend response; every
  /// real call silently fell through to `_fromMockJson` instead). The mock
  /// (`_mockDoctorDetail` in `mock_responses.dart`) already used this same
  /// flat shape, so `fromJson` no longer needs to dispatch on structure at
  /// all — one parser handles both, real and mock, keyed only by which
  /// optional fields happen to be present.
  ///
  /// `languages`/`fellowships`/`isOnline` were removed entirely (2026-09-03)
  /// — no backend column backs any of them (`GetDoctorUseCase`'s own doc
  /// comment), so they always rendered empty/false and the UI that showed
  /// them was deleted rather than kept permanently dead. `bio`/
  /// `experienceYears` are real (ADR-005 Part 34.2); `degree` has no
  /// dedicated UI field, so it's folded into `qualifications` as one entry.
  factory DoctorProfileDto.fromJson(Map<String, dynamic> json) {
    final days = (json['available_days'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(_dayFromJson)
        .toList();

    final affiliations = (json['affiliations'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(DoctorAffiliationDto.fromJson)
        .toList();

    return DoctorProfileDto(
      id: json['id'] as String,
      name: json['name'] as String,
      specialty: json['specialty'] as String,
      specialtyKey: (json['specialtyKey'] ?? json['specialty_key']) as String?,
      experienceYears: json['experienceYears'] as int? ?? 0,
      rating: (json['rating'] as num?)?.toDouble() ?? 0,
      reviewCount: json['reviewCount'] as int? ?? 0,
      clinicName: json['clinicName'] as String? ?? '',
      bio: json['bio'] as String? ?? '',
      qualifications: [
        if (json['degree'] != null) '${json['degree']}',
        ...(json['qualifications'] as List<dynamic>? ?? const []).map(
          (e) => '$e',
        ),
      ],
      consultationFee:
          double.tryParse('${json['consultationFee'] ?? ''}')?.round() ?? 0,
      currency: json['currency'] as String? ?? 'EGP',
      isVerified: json['isVerified'] as bool? ?? false,
      photoUrl: json['photoUrl'] as String?,
      availableDays: days,
      affiliations: affiliations,
      clinicBranchId: json['clinicBranchId'] as String?,
      ianaTimezone: json['ianaTimezone'] as String?,
      affiliationId: json['affiliationId'] as String?,
    );
  }

  static AvailableDay _dayFromJson(Map<String, dynamic> json) => AvailableDay(
    id: json['id'] as String,
    label: json['label'] as String,
    dayNumber: json['day_number'] as int? ?? 0,
    slots: (json['slots'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(
          (s) => TimeSlot(
            id: s['id'] as String,
            label: s['label'] as String,
            available: s['available'] as bool? ?? true,
          ),
        )
        .toList(),
  );

  DoctorProfile toEntity() => DoctorProfile(
    id: id,
    name: name,
    specialty: specialty,
    specialtyKey: specialtyKey,
    experienceYears: experienceYears,
    rating: rating,
    reviewCount: reviewCount,
    clinicName: clinicName,
    bio: bio,
    qualifications: qualifications,
    consultationFee: consultationFee,
    currency: currency,
    isVerified: isVerified,
    photoUrl: photoUrl,
    availableDays: availableDays,
    affiliations: affiliations.map((a) => a.toEntity()).toList(),
    clinicBranchId: clinicBranchId,
    ianaTimezone: ianaTimezone,
    affiliationId: affiliationId,
  );
}

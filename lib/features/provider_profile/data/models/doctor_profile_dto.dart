import 'package:med_super/features/provider_profile/domain/entities/available_day.dart';
import 'package:med_super/features/provider_profile/domain/entities/doctor_profile.dart';
import 'package:med_super/features/provider_profile/domain/entities/time_slot.dart';

class DoctorAffiliationDto {
  const DoctorAffiliationDto({
    required this.clinicBranchId,
    required this.clinicName,
    required this.consultationFee,
    required this.currency,
    required this.ianaTimezone,
  });

  final String clinicBranchId;
  final String clinicName;
  final String consultationFee;
  final String currency;
  final String ianaTimezone;

  factory DoctorAffiliationDto.fromJson(Map<String, dynamic> json) => DoctorAffiliationDto(
    clinicBranchId: json['clinicBranchId'] as String,
    clinicName: json['clinicName'] as String,
    consultationFee: '${json['consultationFee']}',
    currency: json['currency'] as String,
    ianaTimezone: json['ianaTimezone'] as String,
  );

  DoctorAffiliation toEntity() => DoctorAffiliation(
    clinicBranchId: clinicBranchId,
    clinicName: clinicName,
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
    required this.languages,
    required this.bio,
    required this.qualifications,
    required this.fellowships,
    required this.consultationFee,
    required this.currency,
    required this.isVerified,
    required this.isOnline,
    required this.availableDays,
    required this.affiliations,
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
  final List<DoctorAffiliationDto> affiliations;
  final String? clinicBranchId;
  final String? ianaTimezone;

  /// The real backend (`GetDoctorUseCase`) returns a flat camelCase shape.
  /// `bio`/`experienceYears` are real since ADR-005 Part 34.2 added
  /// `Doctor.bio`/`experience_years`; `degree` (also added then) has no
  /// dedicated UI field here, so it's folded into `qualifications` as one
  /// entry. `qualifications` (beyond `degree`)/`fellowships`/`languages`/
  /// `isOnline` still have no backend column at all (File 12 Part 32) and
  /// default to empty/false rather than being invented. `affiliations` is
  /// the real backend's full per-branch list (used to be dropped entirely).
  /// Real-backend keys are tried first, falling back to the mock's
  /// snake_case shape.
  factory DoctorProfileDto.fromJson(Map<String, dynamic> json) {
    final days = (json['available_days'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(_dayFromJson)
        .toList();

    return DoctorProfileDto(
      id: json['id'] as String,
      name: json['name'] as String,
      specialty: json['specialty'] as String,
      specialtyKey:
          (json['specialtyKey'] ?? json['specialty_key']) as String?,
      experienceYears:
          (json['experienceYears'] ?? json['experience_years']) as int? ?? 0,
      rating: (json['rating'] as num?)?.toDouble() ?? 0,
      reviewCount:
          (json['reviewCount'] ?? json['review_count']) as int? ?? 0,
      clinicName:
          (json['clinicName'] ?? json['clinic_name']) as String? ?? '',
      languages: (json['languages'] as List<dynamic>? ?? const [])
          .map((e) => '$e')
          .toList(),
      bio: json['bio'] as String? ?? '',
      qualifications: [
        if (json['degree'] != null) '${json['degree']}',
        ...(json['qualifications'] as List<dynamic>? ?? const []).map(
          (e) => '$e',
        ),
      ],
      fellowships: (json['fellowships'] as List<dynamic>? ?? const [])
          .map((e) => '$e')
          .toList(),
      consultationFee:
          double.tryParse('${json['consultationFee'] ?? ''}')?.round() ??
          json['consultation_fee'] as int? ??
          0,
      currency: json['currency'] as String? ?? 'EGP',
      isVerified:
          (json['isVerified'] ?? json['is_verified']) as bool? ?? false,
      isOnline: json['is_online'] as bool? ?? false,
      photoUrl: (json['photoUrl'] ?? json['photo_url']) as String?,
      availableDays: days,
      affiliations: (json['affiliations'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(DoctorAffiliationDto.fromJson)
          .toList(),
      clinicBranchId:
          (json['clinicBranchId'] ?? json['clinic_branch_id']) as String?,
      ianaTimezone:
          (json['ianaTimezone'] ?? json['iana_timezone']) as String?,
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
    languages: languages,
    bio: bio,
    qualifications: qualifications,
    fellowships: fellowships,
    consultationFee: consultationFee,
    currency: currency,
    isVerified: isVerified,
    isOnline: isOnline,
    photoUrl: photoUrl,
    availableDays: availableDays,
    affiliations: affiliations.map((a) => a.toEntity()).toList(),
    clinicBranchId: clinicBranchId,
    ianaTimezone: ianaTimezone,
  );
}

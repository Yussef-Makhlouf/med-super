import 'package:med_super/features/provider_profile/domain/entities/available_day.dart';
import 'package:med_super/features/provider_profile/domain/entities/doctor_profile.dart';
import 'package:med_super/features/provider_profile/domain/entities/time_slot.dart';

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
  final String? clinicBranchId;
  final String? ianaTimezone;

  /// The real backend (`GetDoctorUseCase`) returns a flat camelCase shape
  /// with only fields that actually exist in the schema — no bio,
  /// qualifications, fellowships, languages, experienceYears or isOnline
  /// column exists yet (File 12 Part 32), and availableDays comes from the
  /// separate `/slots` endpoint, not this one. Those fields default to
  /// empty/false here rather than being invented. Real-backend keys are
  /// tried first, falling back to the mock's snake_case shape.
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
      experienceYears: json['experience_years'] as int? ?? 0,
      rating: (json['rating'] as num?)?.toDouble() ?? 0,
      reviewCount:
          (json['reviewCount'] ?? json['review_count']) as int? ?? 0,
      clinicName:
          (json['clinicName'] ?? json['clinic_name']) as String? ?? '',
      languages: (json['languages'] as List<dynamic>? ?? const [])
          .map((e) => '$e')
          .toList(),
      bio: json['bio'] as String? ?? '',
      qualifications: (json['qualifications'] as List<dynamic>? ?? const [])
          .map((e) => '$e')
          .toList(),
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
    clinicBranchId: clinicBranchId,
    ianaTimezone: ianaTimezone,
  );
}

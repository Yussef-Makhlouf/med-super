import '../../domain/entities/doctor_account_profile.dart';

/// Parses `GET`/`PATCH /v1/doctors/me`'s response
/// (`clinic-reservations`' `MyDoctorProfile`, camelCase, no
/// class-transformer casing rewrite in that backend).
class DoctorAccountProfileDto {
  const DoctorAccountProfileDto({
    required this.id,
    required this.name,
    required this.specialty,
    required this.licenseNumber,
    required this.phone,
    this.email,
    this.avatarUrl,
    this.degree,
    this.yearsOfExperience,
    this.bio = '',
    this.isVerified = false,
  });

  factory DoctorAccountProfileDto.fromJson(Map<String, dynamic> json) {
    return DoctorAccountProfileDto(
      id: json['id'] as String? ?? '',
      name: json['displayName'] as String? ?? '',
      specialty: json['specialty'] as String? ?? '',
      licenseNumber: json['licenseNumber'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      email: json['email'] as String?,
      avatarUrl: json['photoUrl'] as String?,
      degree: json['degree'] as String?,
      yearsOfExperience: json['experienceYears'] as int?,
      bio: json['bio'] as String? ?? '',
      isVerified: json['isVerified'] as bool? ?? false,
    );
  }

  final String id;
  final String name;
  final String specialty;
  final String licenseNumber;
  final String phone;
  final String? email;
  final String? avatarUrl;
  final String? degree;
  final int? yearsOfExperience;
  final String bio;
  final bool isVerified;

  DoctorAccountProfile toEntity() {
    return DoctorAccountProfile(
      id: id,
      name: name,
      specialty: specialty,
      licenseNumber: licenseNumber,
      phone: phone,
      email: email,
      avatarUrl: avatarUrl,
      degree: degree,
      yearsOfExperience: yearsOfExperience,
      bio: bio,
      isVerified: isVerified,
    );
  }
}

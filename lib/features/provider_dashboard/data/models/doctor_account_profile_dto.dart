import '../../domain/entities/doctor_account_profile.dart';

class DoctorAccountProfileDto {
  const DoctorAccountProfileDto({
    required this.id,
    required this.name,
    required this.specialty,
    required this.hospitalName,
    this.avatarUrl,
  });

  factory DoctorAccountProfileDto.fromJson(Map<String, dynamic> json) {
    return DoctorAccountProfileDto(
      id: json['id'] as String,
      name: json['name'] as String,
      specialty: json['specialty'] as String,
      hospitalName: json['hospital_name'] as String,
      avatarUrl: json['avatar_url'] as String?,
    );
  }

  final String id;
  final String name;
  final String specialty;
  final String hospitalName;
  final String? avatarUrl;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'specialty': specialty,
        'hospital_name': hospitalName,
        'avatar_url': avatarUrl,
      };

  DoctorAccountProfile toEntity() {
    return DoctorAccountProfile(
      id: id,
      name: name,
      specialty: specialty,
      hospitalName: hospitalName,
      avatarUrl: avatarUrl,
    );
  }
}

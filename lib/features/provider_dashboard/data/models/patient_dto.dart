import '../../domain/entities/patient.dart';

class PatientDto {
  const PatientDto({
    required this.id,
    required this.name,
    required this.medId,
    this.avatarUrl,
    required this.status,
    required this.nextAppointment,
  });

  factory PatientDto.fromJson(Map<String, dynamic> json) {
    return PatientDto(
      id: json['id'] as String,
      name: json['name'] as String,
      medId: json['med_id'] as String,
      avatarUrl: json['avatar_url'] as String?,
      status: json['status'] as String? ?? 'مؤكد',
      nextAppointment: DateTime.parse(json['next_appointment'] as String),
    );
  }

  final String id;
  final String name;
  final String medId;
  final String? avatarUrl;
  final String status;
  final DateTime nextAppointment;

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'med_id': medId,
    'avatar_url': avatarUrl,
    'status': status,
    'next_appointment': nextAppointment.toIso8601String(),
  };

  Patient toEntity() {
    return Patient(
      id: id,
      name: name,
      medId: medId,
      avatarUrl: avatarUrl,
      status: status,
      nextAppointment: nextAppointment,
    );
  }
}

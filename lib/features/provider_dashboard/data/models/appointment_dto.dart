import '../../domain/entities/appointment.dart';

class AppointmentDto {
  const AppointmentDto({
    required this.id,
    required this.patientName,
    this.patientAvatarUrl,
    required this.scheduledStart,
    required this.scheduledEnd,
    required this.locationStatus,
    required this.medId,
    required this.status,
  });

  factory AppointmentDto.fromJson(Map<String, dynamic> json) {
    return AppointmentDto(
      id: json['id'] as String,
      patientName: json['patient_name'] as String,
      patientAvatarUrl: json['patient_avatar_url'] as String?,
      scheduledStart: DateTime.parse(json['scheduled_start'] as String),
      scheduledEnd: DateTime.parse(json['scheduled_end'] as String),
      locationStatus: json['location_status'] as String? ?? 'في العيادة',
      medId: json['med_id'] as String,
      status: json['status'] as String,
    );
  }

  final String id;
  final String patientName;
  final String? patientAvatarUrl;
  final DateTime scheduledStart;
  final DateTime scheduledEnd;
  final String locationStatus;
  final String medId;
  final String status;

  Map<String, dynamic> toJson() => {
        'id': id,
        'patient_name': patientName,
        'patient_avatar_url': patientAvatarUrl,
        'scheduled_start': scheduledStart.toIso8601String(),
        'scheduled_end': scheduledEnd.toIso8601String(),
        'location_status': locationStatus,
        'med_id': medId,
        'status': status,
      };

  Appointment toEntity() {
    return Appointment(
      id: id,
      patientName: patientName,
      patientAvatarUrl: patientAvatarUrl,
      scheduledStart: scheduledStart,
      scheduledEnd: scheduledEnd,
      locationStatus: locationStatus,
      medId: medId,
      status: switch (status.toLowerCase()) {
        'confirmed' => AppointmentStatus.confirmed,
        'cancelled' => AppointmentStatus.cancelled,
        'completed' => AppointmentStatus.completed,
        _ => AppointmentStatus.pending,
      },
    );
  }
}

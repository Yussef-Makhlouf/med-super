enum AppointmentStatus {
  pending,
  confirmed,
  cancelled,
  completed,
}

class Appointment {
  const Appointment({
    required this.id,
    required this.patientName,
    this.patientAvatarUrl,
    required this.scheduledStart,
    required this.scheduledEnd,
    required this.locationStatus,
    required this.medId,
    required this.status,
  });

  final String id;
  final String patientName;
  final String? patientAvatarUrl;
  final DateTime scheduledStart;
  final DateTime scheduledEnd;
  final String locationStatus;
  final String medId;
  final AppointmentStatus status;

  Appointment copyWith({
    String? id,
    String? patientName,
    String? patientAvatarUrl,
    DateTime? scheduledStart,
    DateTime? scheduledEnd,
    String? locationStatus,
    String? medId,
    AppointmentStatus? status,
  }) {
    return Appointment(
      id: id ?? this.id,
      patientName: patientName ?? this.patientName,
      patientAvatarUrl: patientAvatarUrl ?? this.patientAvatarUrl,
      scheduledStart: scheduledStart ?? this.scheduledStart,
      scheduledEnd: scheduledEnd ?? this.scheduledEnd,
      locationStatus: locationStatus ?? this.locationStatus,
      medId: medId ?? this.medId,
      status: status ?? this.status,
    );
  }
}

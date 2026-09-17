import 'package:med_super/features/appointments/domain/entities/confirmed_appointment.dart';

/// `{ appointmentId, status }` — File 10 §2.3's `POST
/// /v1/appointments/{holdId}/confirm` response.
class ConfirmedAppointmentDto {
  const ConfirmedAppointmentDto({required this.appointmentId, required this.status});

  final String appointmentId;
  final String status;

  factory ConfirmedAppointmentDto.fromJson(Map<String, dynamic> json) =>
      ConfirmedAppointmentDto(
        appointmentId: json['appointmentId'] as String,
        status: json['status'] as String,
      );

  ConfirmedAppointment toEntity() =>
      ConfirmedAppointment(appointmentId: appointmentId, status: status);
}

import 'package:med_super/features/appointments/domain/entities/rescheduled_appointment.dart';

/// `POST /v1/appointments/{appointmentId}/reschedule` →
/// `{ status: 'CONFIRMED', appointmentId, slotId, previousAppointmentId }`
/// (`RescheduleAppointmentUseCase`, backend `894cba6`).
class RescheduledAppointmentDto {
  const RescheduledAppointmentDto({
    required this.appointmentId,
    required this.slotId,
    required this.previousAppointmentId,
  });

  final String appointmentId;
  final String slotId;
  final String previousAppointmentId;

  factory RescheduledAppointmentDto.fromJson(Map<String, dynamic> json) =>
      RescheduledAppointmentDto(
        appointmentId: json['appointmentId'] as String,
        slotId: json['slotId'] as String,
        previousAppointmentId: json['previousAppointmentId'] as String,
      );

  RescheduledAppointment toEntity() => RescheduledAppointment(
    appointmentId: appointmentId,
    slotId: slotId,
    previousAppointmentId: previousAppointmentId,
  );
}

import 'package:med_super/features/appointments/domain/entities/appointment_hold.dart';

/// `{ holdId, slotId, expiresAt, status }` — File 10 §2.3's `POST
/// /v1/appointments/hold` response, camelCase (this is the use-case's own
/// TS interface, not a raw Prisma row — unlike the doctor-detail endpoint).
/// `POST .../reschedule`'s response mirrors this exact shape plus
/// `previousAppointmentId` (File 12 Part 35.12).
class AppointmentHoldDto {
  const AppointmentHoldDto({
    required this.holdId,
    required this.slotId,
    required this.expiresAt,
    this.previousAppointmentId,
  });

  final String holdId;
  final String slotId;
  final DateTime expiresAt;
  final String? previousAppointmentId;

  factory AppointmentHoldDto.fromJson(Map<String, dynamic> json) =>
      AppointmentHoldDto(
        holdId: json['holdId'] as String,
        slotId: json['slotId'] as String,
        expiresAt: DateTime.parse(json['expiresAt'] as String).toUtc(),
        previousAppointmentId: json['previousAppointmentId'] as String?,
      );

  AppointmentHold toEntity() => AppointmentHold(
    holdId: holdId,
    slotId: slotId,
    expiresAt: expiresAt,
    previousAppointmentId: previousAppointmentId,
  );
}

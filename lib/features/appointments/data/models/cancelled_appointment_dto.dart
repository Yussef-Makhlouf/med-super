import 'package:med_super/features/appointments/domain/repositories/appointment_repository.dart';

/// `{ status, refundAmount, feeApplied }` — File 10 §2.3's `POST
/// /v1/appointments/{id}/cancel` response. Both amounts are always `0` in
/// this backend phase (File 12 Part 35.7) — not a client-side assumption.
class CancelledAppointmentDto {
  const CancelledAppointmentDto({
    required this.status,
    required this.refundAmount,
    required this.feeApplied,
  });

  final String status;
  final num refundAmount;
  final num feeApplied;

  factory CancelledAppointmentDto.fromJson(Map<String, dynamic> json) =>
      CancelledAppointmentDto(
        status: json['status'] as String,
        refundAmount: json['refundAmount'] as num? ?? 0,
        feeApplied: json['feeApplied'] as num? ?? 0,
      );

  CancelledAppointment toEntity() => CancelledAppointment(
    status: status,
    refundAmount: refundAmount,
    feeApplied: feeApplied,
  );
}

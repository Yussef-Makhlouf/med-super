/// A temporary 5-minute claim on a slot, from the real Phase 4
/// `POST /v1/appointments/hold` (File 10 §2.3). Must be confirmed via
/// [ConfirmedAppointment] before it expires, or the slot silently reopens.
class AppointmentHold {
  const AppointmentHold({
    required this.holdId,
    required this.slotId,
    required this.expiresAt,
    required this.previousAppointmentId,
    this.fullAmount,
    this.currency,
    this.minPaymentAmount,
  });

  final String holdId;
  final String slotId;
  final DateTime expiresAt;

  /// Non-null only when this hold was created by a reschedule
  /// (`POST /v1/appointments/{appointmentId}/reschedule`) rather than a
  /// fresh `POST /v1/appointments/hold`.
  final String? previousAppointmentId;

  /// Server-side consult fee for this slot. `null` on a reschedule hold.
  final num? fullAmount;
  final String? currency;

  /// Smallest partial amount the server accepts — `min(policy, fee)`,
  /// normally 50 EGP. `null` when the `MIN_APPOINTMENT_PAYMENT` policy is not
  /// configured (only a full payment works then) or on a reschedule hold.
  final num? minPaymentAmount;
}

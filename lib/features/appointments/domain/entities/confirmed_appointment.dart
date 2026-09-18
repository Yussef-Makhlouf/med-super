/// Result of `POST /v1/appointments/{holdId}/confirm` (File 10 §2.3) — a
/// real `Appointment` row now exists, straight to `CONFIRMED` (pay-at-clinic
/// only; File 12 Part 35.4 — no Payments module yet).
class ConfirmedAppointment {
  const ConfirmedAppointment({required this.appointmentId, required this.status});

  final String appointmentId;
  final String status;
}

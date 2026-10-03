/// Result of a patient reschedule. The backend completes it in one
/// transaction: the old appointment becomes `RESCHEDULED` and a new
/// `CONFIRMED` appointment on the new slot carries the original payment
/// over, so there is no hold to confirm and nothing to pay again.
class RescheduledAppointment {
  const RescheduledAppointment({
    required this.appointmentId,
    required this.slotId,
    required this.previousAppointmentId,
  });

  final String appointmentId;
  final String slotId;
  final String previousAppointmentId;
}

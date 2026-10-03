import 'entities/doctor_appointment.dart';

/// Presentation-safe reflection of the backend live-visit contract.
///
/// The API remains authoritative when this derived state is stale.
enum DoctorAppointmentVisitActionAvailability {
  available,

  /// Waiting patient, but today is not the appointment's local day: the
  /// backend refuses to start the visit (PM-APPT-03).
  notOnAppointmentDay,
  terminal,
  unavailable,
}

/// PM-APPT-03 ("B+"): a visit may only be *started* (`WAITING ->
/// IN_DOCTOR_ROOM`) on the appointment's calendar day in the branch's IANA
/// zone, so a future-day or old past-day appointment is not changed by
/// accident. Once started it can always be finished (`-> LEFT`), even after
/// midnight. Never uses the device timezone.
class DoctorAppointmentVisitActionPolicy {
  const DoctorAppointmentVisitActionPolicy();

  static const standard = DoctorAppointmentVisitActionPolicy();

  DoctorAppointmentVisitActionAvailability evaluate(
    DoctorAppointment appointment, {
    DateTime? nowUtc,
  }) {
    if (!appointment.isActionable) {
      return DoctorAppointmentVisitActionAvailability.unavailable;
    }
    if (appointment.visitStatus.next == null) {
      return DoctorAppointmentVisitActionAvailability.terminal;
    }
    if (appointment.visitStatus == DoctorVisitStatus.waiting &&
        !appointment.isOnAppointmentDay(nowUtc ?? DateTime.now().toUtc())) {
      return DoctorAppointmentVisitActionAvailability.notOnAppointmentDay;
    }

    return DoctorAppointmentVisitActionAvailability.available;
  }
}

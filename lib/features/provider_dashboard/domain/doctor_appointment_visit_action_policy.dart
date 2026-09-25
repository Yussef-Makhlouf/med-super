import 'entities/doctor_appointment.dart';

/// Presentation-safe reflection of the backend live-visit timing contract.
///
/// API timestamps and [now] are compared as UTC instants, never as calendar
/// dates in the device timezone. The API remains authoritative when this
/// derived state is stale.
enum DoctorAppointmentVisitActionAvailability {
  available,
  terminal,
  unavailable,
}

/// Visit transitions belong to an individual confirmed appointment, not its
/// scheduled slot time. A short visit or an early arrival must not be blocked
/// by the calendar. The backend remains authoritative for scope, version, and
/// valid transition order.
class DoctorAppointmentVisitActionPolicy {
  const DoctorAppointmentVisitActionPolicy();

  static const standard = DoctorAppointmentVisitActionPolicy();

  DoctorAppointmentVisitActionAvailability evaluate(
    DoctorAppointment appointment,
  ) {
    if (!appointment.isActionable) {
      return DoctorAppointmentVisitActionAvailability.unavailable;
    }
    if (appointment.visitStatus.next == null) {
      return DoctorAppointmentVisitActionAvailability.terminal;
    }

    return DoctorAppointmentVisitActionAvailability.available;
  }
}

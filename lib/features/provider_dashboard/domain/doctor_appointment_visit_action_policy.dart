import 'entities/doctor_appointment.dart';

/// Presentation-safe reflection of the backend live-visit timing contract.
///
/// API timestamps and [now] are compared as UTC instants, never as calendar
/// dates in the device timezone. The API remains authoritative when this
/// derived state is stale.
enum DoctorAppointmentVisitActionAvailability {
  available,
  tooEarly,
  outsideWindow,
  terminal,
  unavailable,
}

class DoctorAppointmentVisitActionPolicy {
  const DoctorAppointmentVisitActionPolicy({
    this.earlyArrivalWindow = const Duration(minutes: 30),
  });

  static const standard = DoctorAppointmentVisitActionPolicy();

  final Duration earlyArrivalWindow;

  DoctorAppointmentVisitActionAvailability evaluate(
    DoctorAppointment appointment,
    DateTime now,
  ) {
    if (!appointment.isActionable) {
      return DoctorAppointmentVisitActionAvailability.unavailable;
    }
    if (appointment.visitStatus.next == null) {
      return DoctorAppointmentVisitActionAvailability.terminal;
    }

    final current = now.toUtc();
    final opensAt = appointment.startAt.toUtc().subtract(earlyArrivalWindow);
    if (current.isBefore(opensAt)) {
      return DoctorAppointmentVisitActionAvailability.tooEarly;
    }
    if (current.isAfter(appointment.endAt.toUtc())) {
      return DoctorAppointmentVisitActionAvailability.outsideWindow;
    }
    return DoctorAppointmentVisitActionAvailability.available;
  }
}

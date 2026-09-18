/// One item from `GET /v1/appointments` or `GET /v1/appointments/{id}`
/// (File 12 Part 35.17's response shape, extended with `doctorId`/
/// `doctorName`/`clinicBranchId`/`clinicName`/`clinicAddressLine1`/
/// `clinicCity`/`clinicPhone` for display — see the backend's
/// `feature/appointment-summary-doctor-clinic-details` branch). `status` is
/// a raw backend `AppointmentStatus` value (`CONFIRMED`, `CANCELLED`,
/// `RESCHEDULED`, ...).
class AppointmentSummary {
  const AppointmentSummary({
    required this.appointmentId,
    required this.status,
    required this.slotId,
    required this.startAt,
    required this.endAt,
    required this.doctorClinicAffiliationId,
    required this.doctorId,
    required this.doctorName,
    required this.clinicBranchId,
    required this.clinicName,
    required this.clinicAddressLine1,
    required this.clinicCity,
    required this.clinicPhone,
    this.cancelledReason,
    this.rescheduledFromAppointmentId,
    this.visitStatus = 'WAITING',
  });

  final String appointmentId;
  final String status;
  final String slotId;
  final DateTime startAt;
  final DateTime endAt;
  final String doctorClinicAffiliationId;
  final String doctorId;
  final String doctorName;
  final String clinicBranchId;
  final String clinicName;
  final String clinicAddressLine1;
  final String clinicCity;
  final String clinicPhone;
  final String? cancelledReason;
  final String? rescheduledFromAppointmentId;

  /// Live clinic-flow state (`WAITING`, `IN_DOCTOR_ROOM`, `LEFT`).
  final String visitStatus;

  /// Drives both cancel and reschedule: only a confirmed appointment whose
  /// patient hasn't entered the doctor's room yet — the backend rejects both
  /// with `APPOINTMENT_VISIT_IN_PROGRESS` after that.
  bool get isCancellable => status == 'CONFIRMED' && visitStatus == 'WAITING';
}

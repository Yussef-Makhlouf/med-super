/// What the patient owes/already paid for one appointment — same shape as
/// the Doctor Dashboard's `DoctorAppointmentPayment`, kept as a separate
/// class per this codebase's convention of not sharing entities across
/// features, since the two surfaces evolve independently.
class AppointmentPayment {
  const AppointmentPayment({
    required this.method,
    required this.currency,
    required this.fullAmount,
    required this.paidAmount,
    required this.remainingBalance,
  });

  /// Wire value: `PAY_AT_CLINIC`, `INTERNAL_WALLET`, `FAWRY`, `CARD`,
  /// `MOBILE_WALLET`.
  final String method;
  final String currency;
  final num fullAmount;
  final num paidAmount;
  final num remainingBalance;

  bool get isFullyPaid => remainingBalance <= 0;
}

/// One item from `GET /v1/appointments` or `GET /v1/appointments/{id}`
/// (File 12 Part 35.17's response shape, extended with `doctorId`/
/// `doctorName`/`clinicBranchId`/`clinicName`/`clinicAddressLine1`/
/// `clinicCity`/`clinicPhone` for display). `status` is
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
    this.payment,
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

  /// `null` only when the appointment has no payment intent on record.
  final AppointmentPayment? payment;

  /// Drives both cancel and reschedule: only a confirmed appointment whose
  /// patient hasn't entered the doctor's room yet — the backend rejects both
  /// with `APPOINTMENT_VISIT_IN_PROGRESS` after that.
  bool get isCancellable => status == 'CONFIRMED' && visitStatus == 'WAITING';
}

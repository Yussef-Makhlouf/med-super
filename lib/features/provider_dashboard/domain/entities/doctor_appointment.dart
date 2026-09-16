/// The appointment lifecycle the backend actually persists
/// (`appointments_status_enum`). `HELD`/`EXPIRED` are pre-confirmation
/// booking-funnel states — an `Appointment` row is only created at confirm
/// time, so a doctor never sees them; they are folded into [other] rather
/// than pretended away.
///
/// There is deliberately no `pending` state: the old mock contract had the
/// doctor "accept"/"reject" a request, but a real appointment is already
/// `CONFIRMED` the moment the patient confirms their hold and pays. The
/// doctor's actions are cancel and reschedule, not accept.
enum DoctorAppointmentStatus { confirmed, cancelled, rescheduled, completed, other }

/// Live, operational clinic-flow state for a confirmed appointment.
/// Separate from [DoctorAppointmentStatus], which represents the booking
/// lifecycle rather than where the patient is inside the clinic.
enum DoctorVisitStatus { waiting, inDoctorRoom, left }

extension DoctorVisitStatusX on DoctorVisitStatus {
  String get wireValue => switch (this) {
    DoctorVisitStatus.waiting => 'WAITING',
    DoctorVisitStatus.inDoctorRoom => 'IN_DOCTOR_ROOM',
    DoctorVisitStatus.left => 'LEFT',
  };

  DoctorVisitStatus? get next => switch (this) {
    DoctorVisitStatus.waiting => DoctorVisitStatus.inDoctorRoom,
    DoctorVisitStatus.inDoctorRoom => DoctorVisitStatus.left,
    DoctorVisitStatus.left => null,
  };

  static DoctorVisitStatus fromWire(String? value) => switch (value?.toUpperCase()) {
    'IN_DOCTOR_ROOM' => DoctorVisitStatus.inDoctorRoom,
    'LEFT' => DoctorVisitStatus.left,
    _ => DoctorVisitStatus.waiting,
  };
}

extension DoctorAppointmentStatusX on DoctorAppointmentStatus {
  /// The wire value `GET /v1/doctors/me/appointments?status=` expects.
  /// `other` has none — it is a display-only bucket.
  String? get wireValue => switch (this) {
    DoctorAppointmentStatus.confirmed => 'CONFIRMED',
    DoctorAppointmentStatus.cancelled => 'CANCELLED',
    DoctorAppointmentStatus.rescheduled => 'RESCHEDULED',
    DoctorAppointmentStatus.completed => 'COMPLETED',
    DoctorAppointmentStatus.other => null,
  };

  static DoctorAppointmentStatus fromWire(String? value) =>
      switch (value?.toUpperCase()) {
        'CONFIRMED' => DoctorAppointmentStatus.confirmed,
        'CANCELLED' => DoctorAppointmentStatus.cancelled,
        'RESCHEDULED' => DoctorAppointmentStatus.rescheduled,
        'COMPLETED' => DoctorAppointmentStatus.completed,
        _ => DoctorAppointmentStatus.other,
      };
}

/// One appointment as the Doctor Dashboard sees it
/// (`GET /v1/doctors/me/appointments`, File 12 Part 49.7).
///
/// Every field here is backed by a real column. The old mock entity's
/// `medId` and `locationStatus` are gone — neither existed anywhere in the
/// schema.
class DoctorAppointment {
  const DoctorAppointment({
    required this.appointmentId,
    required this.status,
    required this.slotId,
    required this.startAt,
    required this.endAt,
    required this.doctorClinicAffiliationId,
    required this.clinicId,
    required this.clinicName,
    required this.clinicBranchId,
    required this.clinicBranchPhone,
    required this.clinicAddressLine1,
    required this.clinicCity,
    required this.ianaTimezone,
    required this.patientId,
    required this.patientName,
    required this.patientPhone,
    required this.createdAt,
    this.visitStatus = DoctorVisitStatus.waiting,
    this.version = 1,
    this.cancelledReason,
    this.rescheduledFromAppointmentId,
  });

  final String appointmentId;
  final DoctorAppointmentStatus status;
  final String slotId;

  /// UTC, per File 11 Part 04 — render against [ianaTimezone], never the
  /// device zone, or a doctor travelling shows the wrong clinic day.
  final DateTime startAt;
  final DateTime endAt;

  final String doctorClinicAffiliationId;
  final String clinicId;
  final String clinicName;
  final String clinicBranchId;
  final String clinicBranchPhone;
  final String clinicAddressLine1;
  final String clinicCity;
  final String ianaTimezone;

  final String patientId;
  final String patientName;
  final String patientPhone;

  final DoctorVisitStatus visitStatus;
  final int version;

  final DateTime createdAt;
  final String? cancelledReason;
  final String? rescheduledFromAppointmentId;

  /// Only a `CONFIRMED` appointment can be cancelled or rescheduled — the
  /// backend enforces this with `422 APPOINTMENT_NOT_CANCELLABLE` /
  /// `APPOINTMENT_NOT_RESCHEDULABLE`; mirroring it here keeps the UI from
  /// offering an action that is guaranteed to fail.
  bool get isActionable => status == DoctorAppointmentStatus.confirmed;

  bool get canAdvanceVisit => isActionable && visitStatus.next != null;
}

/// One page of the cursor-paginated doctor appointment list.
class DoctorAppointmentPage {
  const DoctorAppointmentPage({required this.items, this.nextCursor});

  final List<DoctorAppointment> items;
  final String? nextCursor;

  bool get hasMore => nextCursor != null;
}

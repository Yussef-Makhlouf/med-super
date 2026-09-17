/// A patient as derived purely from the doctor's own appointment history
/// (`GET /v1/doctors/me/appointments`) — there is no `/v1/provider/patients`
/// backend route, and there never was a real one backing the old mock
/// `Patient` entity's `medId`/free-text `status` fields, so this shape
/// carries only what an appointment row actually contains.
///
/// [lastAppointmentAt]/[nextAppointmentAt] are computed by
/// `GetProviderPatientsUseCase` from every appointment seen for this
/// `patientId` within its bounded window — not separate backend fields.
class Patient {
  const Patient({
    required this.patientId,
    required this.patientName,
    required this.patientPhone,
    this.lastAppointmentAt,
    this.nextAppointmentAt,
  });

  final String patientId;
  final String patientName;
  final String patientPhone;

  /// The most recent past-or-present appointment's `startAt` seen for this
  /// patient within the query window, if any.
  final DateTime? lastAppointmentAt;

  /// The nearest future appointment's `startAt` seen for this patient within
  /// the query window, if any.
  final DateTime? nextAppointmentAt;
}

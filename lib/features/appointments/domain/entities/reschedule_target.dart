/// Carries just enough of an [AppointmentSummary] into [RescheduleScreen] to
/// call `RescheduleAppointmentUseCase` — passed via `GoRouterState.extra`
/// from `PatientAppointmentsScreen`. `doctorId` is real now (backend
/// `feature/appointment-summary-doctor-clinic-details`), so the screen no
/// longer needs the mock-only `affiliation-{doctorId}` convention to
/// resolve it.
class RescheduleTarget {
  const RescheduleTarget({
    required this.appointmentId,
    required this.doctorClinicAffiliationId,
    required this.doctorId,
    required this.currentStartAt,
  });

  final String appointmentId;
  final String doctorClinicAffiliationId;
  final String doctorId;
  final DateTime currentStartAt;
}

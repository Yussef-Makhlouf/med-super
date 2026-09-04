import 'package:med_super/core/error/result.dart';
import '../entities/doctor_appointment.dart';
import '../repositories/provider_dashboard_repository.dart';

/// `GET /v1/doctors/me/appointments` — the doctor's own queue. Scope comes
/// from the JWT; every argument here only ever *narrows* it.
class GetDoctorAppointmentsUseCase {
  const GetDoctorAppointmentsUseCase(this._repository);

  final ProviderDashboardRepository _repository;

  Future<Result<DoctorAppointmentPage>> call({
    DateTime? from,
    DateTime? to,
    DoctorAppointmentStatus? status,
    String? clinicBranchId,
    String? cursor,
    int? limit,
  }) {
    return _repository.getMyAppointments(
      from: from,
      to: to,
      status: status,
      clinicBranchId: clinicBranchId,
      cursor: cursor,
      limit: limit,
    );
  }
}

/// `GET /v1/doctors/me/appointments/{id}`.
class GetDoctorAppointmentUseCase {
  const GetDoctorAppointmentUseCase(this._repository);

  final ProviderDashboardRepository _repository;

  Future<Result<DoctorAppointment>> call(String appointmentId) {
    return _repository.getMyAppointment(appointmentId);
  }
}

/// `POST /v1/doctors/me/appointments/{id}/cancel`.
///
/// Always sends `PROVIDER_REQUEST`, which waives the cancellation fee — the
/// clinic cancelled, so the patient is refunded in full. The backend rejects
/// any other reason on this route.
class CancelDoctorAppointmentUseCase {
  const CancelDoctorAppointmentUseCase(this._repository);

  final ProviderDashboardRepository _repository;

  Future<Result<CancelAppointmentOutcome>> call({
    required String appointmentId,
    String? note,
  }) {
    return _repository.cancelMyAppointment(
      appointmentId: appointmentId,
      note: note,
    );
  }
}

/// `POST /v1/doctors/me/appointments/{id}/reschedule`.
///
/// [newSlotId] must be an `OPEN` slot on the **same** affiliation — the
/// backend 404s anything else, so a doctor can never move a patient onto
/// another provider's calendar.
class RescheduleDoctorAppointmentUseCase {
  const RescheduleDoctorAppointmentUseCase(this._repository);

  final ProviderDashboardRepository _repository;

  Future<Result<RescheduleAppointmentOutcome>> call({
    required String appointmentId,
    required String newSlotId,
  }) {
    return _repository.rescheduleMyAppointment(
      appointmentId: appointmentId,
      newSlotId: newSlotId,
    );
  }
}

/// `POST /v1/doctors/me/appointments/branch/{clinicBranchId}/create` —
/// walk-in booking, callable by DOCTOR or CLINIC_STAFF.
///
/// Exactly one of [patientId] or [patientPhone] must be supplied (the
/// backend validates this and 400s otherwise, via
/// `ExactlyOnePatientIdentifierConstraint`); [patientName] only applies on
/// the find-or-create-by-phone path and only names a *new* patient.
class BookWalkInAppointmentUseCase {
  const BookWalkInAppointmentUseCase(this._repository);

  final ProviderDashboardRepository _repository;

  Future<Result<DoctorAppointment>> call({
    required String clinicBranchId,
    required String slotId,
    String? patientId,
    String? patientPhone,
    String? patientName,
  }) {
    return _repository.bookWalkInAppointment(
      clinicBranchId: clinicBranchId,
      slotId: slotId,
      patientId: patientId,
      patientPhone: patientPhone,
      patientName: patientName,
    );
  }
}

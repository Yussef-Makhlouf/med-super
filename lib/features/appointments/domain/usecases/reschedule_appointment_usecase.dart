import 'package:med_super/core/error/result.dart';
import 'package:med_super/features/appointments/domain/entities/rescheduled_appointment.dart';
import 'package:med_super/features/appointments/domain/repositories/appointment_repository.dart';

/// Moves a confirmed appointment to another slot of the same clinic in one
/// step. The backend confirms the new appointment and carries the original
/// payment over, so the caller must not start a new hold or payment.
class RescheduleAppointmentUseCase {
  const RescheduleAppointmentUseCase(this._repository);

  final AppointmentRepository _repository;

  Future<Result<RescheduledAppointment>> call({
    required String appointmentId,
    required String newSlotId,
  }) => _repository.reschedule(appointmentId: appointmentId, newSlotId: newSlotId);
}

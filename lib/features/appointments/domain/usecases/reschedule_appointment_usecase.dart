import 'package:med_super/core/error/result.dart';
import 'package:med_super/features/appointments/domain/repositories/appointment_repository.dart';

/// Moves a confirmed appointment to a new slot of the same doctor/branch. The
/// backend completes it in one step and carries the payment over, so there is
/// no hold to confirm and nothing to pay. Resolves to the new appointment id.
class RescheduleAppointmentUseCase {
  const RescheduleAppointmentUseCase(this._repository);

  final AppointmentRepository _repository;

  Future<Result<String>> call({
    required String appointmentId,
    required String newSlotId,
  }) => _repository.reschedule(appointmentId: appointmentId, newSlotId: newSlotId);
}

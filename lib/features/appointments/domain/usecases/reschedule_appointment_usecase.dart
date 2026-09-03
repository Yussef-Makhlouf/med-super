import 'package:med_super/core/error/result.dart';
import 'package:med_super/features/appointments/domain/entities/appointment_hold.dart';
import 'package:med_super/features/appointments/domain/repositories/appointment_repository.dart';

/// Returns a fresh [AppointmentHold] on the new slot — the caller still has
/// to call [ConfirmAppointmentUseCase] on it (File 12 Part 35.10).
class RescheduleAppointmentUseCase {
  const RescheduleAppointmentUseCase(this._repository);

  final AppointmentRepository _repository;

  Future<Result<AppointmentHold>> call({
    required String appointmentId,
    required String newSlotId,
  }) => _repository.reschedule(appointmentId: appointmentId, newSlotId: newSlotId);
}

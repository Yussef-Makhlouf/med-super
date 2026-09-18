import 'package:med_super/core/error/result.dart';
import 'package:med_super/features/appointments/domain/repositories/appointment_repository.dart';

class CancelAppointmentUseCase {
  const CancelAppointmentUseCase(this._repository);

  final AppointmentRepository _repository;

  Future<Result<CancelledAppointment>> call({
    required String appointmentId,
    required String reason,
    String? note,
  }) => _repository.cancel(appointmentId: appointmentId, reason: reason, note: note);
}

import 'package:med_super/core/error/result.dart';
import 'package:med_super/features/appointments/domain/entities/appointment_summary.dart';
import 'package:med_super/features/appointments/domain/repositories/appointment_repository.dart';

class GetAppointmentUseCase {
  const GetAppointmentUseCase(this._repository);

  final AppointmentRepository _repository;

  Future<Result<AppointmentSummary>> call(String appointmentId) =>
      _repository.getById(appointmentId);
}

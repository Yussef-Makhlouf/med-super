import 'package:med_super/core/error/result.dart';
import 'package:med_super/features/appointments/domain/repositories/appointment_repository.dart';

class ListMyAppointmentsUseCase {
  const ListMyAppointmentsUseCase(this._repository);

  final AppointmentRepository _repository;

  Future<Result<AppointmentSummaryPage>> call({
    String? status,
    String? cursor,
    int? limit,
  }) => _repository.listMine(status: status, cursor: cursor, limit: limit);
}

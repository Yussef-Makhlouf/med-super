import 'package:med_super/core/error/result.dart';
import '../entities/appointment.dart';
import '../repositories/provider_dashboard_repository.dart';

class GetAppointmentsUseCase {
  const GetAppointmentsUseCase(this._repository);
  final ProviderDashboardRepository _repository;

  Future<Result<List<Appointment>>> call({DateTime? date, String? status}) {
    return _repository.getAppointments(date: date, status: status);
  }
}

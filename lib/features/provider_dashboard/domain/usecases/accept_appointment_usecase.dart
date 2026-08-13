import 'package:med_super/core/error/result.dart';
import '../entities/appointment.dart';
import '../repositories/provider_dashboard_repository.dart';

class AcceptAppointmentUseCase {
  const AcceptAppointmentUseCase(this._repository);
  final ProviderDashboardRepository _repository;

  Future<Result<Appointment>> call(String id) {
    return _repository.acceptAppointment(id);
  }
}

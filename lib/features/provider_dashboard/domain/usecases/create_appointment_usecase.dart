import 'package:med_super/core/error/result.dart';
import '../entities/appointment.dart';
import '../repositories/provider_dashboard_repository.dart';

class CreateAppointmentUseCase {
  const CreateAppointmentUseCase(this._repository);
  final ProviderDashboardRepository _repository;

  Future<Result<Appointment>> call({
    required String patientName,
    required DateTime scheduledStart,
    required DateTime scheduledEnd,
  }) {
    return _repository.createAppointment(
      patientName: patientName,
      scheduledStart: scheduledStart,
      scheduledEnd: scheduledEnd,
    );
  }
}

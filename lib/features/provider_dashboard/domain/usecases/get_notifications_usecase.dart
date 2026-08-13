import 'package:med_super/core/error/result.dart';
import '../entities/doctor_notification.dart';
import '../repositories/provider_dashboard_repository.dart';

class GetNotificationsUseCase {
  const GetNotificationsUseCase(this._repository);
  final ProviderDashboardRepository _repository;

  Future<Result<List<DoctorNotification>>> call() {
    return _repository.getNotifications();
  }
}

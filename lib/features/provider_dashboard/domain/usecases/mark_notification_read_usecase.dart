import 'package:med_super/core/error/result.dart';
import '../repositories/provider_dashboard_repository.dart';

class MarkNotificationReadUseCase {
  const MarkNotificationReadUseCase(this._repository);
  final ProviderDashboardRepository _repository;

  Future<Result<void>> call(String id) {
    return _repository.markNotificationRead(id);
  }
}

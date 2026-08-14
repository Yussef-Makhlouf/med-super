import 'package:med_super/core/error/result.dart';
import '../repositories/provider_dashboard_repository.dart';

class ChangePasswordUseCase {
  ChangePasswordUseCase(this._repository);

  final ProviderDashboardRepository _repository;

  Future<Result<void>> call({
    required String currentPassword,
    required String newPassword,
  }) {
    return _repository.changePassword(
      currentPassword: currentPassword,
      newPassword: newPassword,
    );
  }
}

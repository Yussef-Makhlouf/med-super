import 'package:med_super/core/error/result.dart';
import '../entities/doctor_account_profile.dart';
import '../repositories/provider_dashboard_repository.dart';

class UploadAvatarUseCase {
  UploadAvatarUseCase(this._repository);

  final ProviderDashboardRepository _repository;

  Future<Result<DoctorAccountProfile>> call(String filePath) {
    return _repository.uploadAvatar(filePath);
  }
}

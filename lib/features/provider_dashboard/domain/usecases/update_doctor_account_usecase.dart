import 'package:med_super/core/error/result.dart';
import '../entities/doctor_account_profile.dart';
import '../repositories/provider_dashboard_repository.dart';

class UpdateDoctorAccountUseCase {
  UpdateDoctorAccountUseCase(this._repository);

  final ProviderDashboardRepository _repository;

  Future<Result<DoctorAccountProfile>> call({
    String? bio,
    String? degree,
    int? yearsOfExperience,
  }) {
    return _repository.updateDoctorAccount(
      bio: bio,
      degree: degree,
      yearsOfExperience: yearsOfExperience,
    );
  }
}

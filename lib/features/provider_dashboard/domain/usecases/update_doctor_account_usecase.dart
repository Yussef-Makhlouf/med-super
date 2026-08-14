import 'package:med_super/core/error/result.dart';
import '../entities/doctor_account_profile.dart';
import '../repositories/provider_dashboard_repository.dart';

class UpdateDoctorAccountUseCase {
  UpdateDoctorAccountUseCase(this._repository);

  final ProviderDashboardRepository _repository;

  Future<Result<DoctorAccountProfile>> call({
    required String name,
    required String specialty,
    required int yearsOfExperience,
    required String bio,
  }) {
    return _repository.updateDoctorAccount(
      name: name,
      specialty: specialty,
      yearsOfExperience: yearsOfExperience,
      bio: bio,
    );
  }
}

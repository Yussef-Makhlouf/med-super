import 'package:med_super/core/error/result.dart';
import '../entities/doctor_account_profile.dart';
import '../repositories/provider_dashboard_repository.dart';

class GetDoctorAccountUseCase {
  const GetDoctorAccountUseCase(this._repository);
  final ProviderDashboardRepository _repository;

  Future<Result<DoctorAccountProfile>> call() {
    return _repository.getDoctorAccount();
  }
}

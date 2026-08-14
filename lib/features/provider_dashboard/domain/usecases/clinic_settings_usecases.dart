import 'package:med_super/core/error/result.dart';
import '../entities/clinic_settings.dart';
import '../repositories/provider_dashboard_repository.dart';

class GetClinicSettingsUseCase {
  GetClinicSettingsUseCase(this._repository);

  final ProviderDashboardRepository _repository;

  Future<Result<ClinicSettings>> call() {
    return _repository.getClinicSettings();
  }
}

class UpdateClinicSettingsUseCase {
  UpdateClinicSettingsUseCase(this._repository);

  final ProviderDashboardRepository _repository;

  Future<Result<ClinicSettings>> call(ClinicSettings settings) {
    return _repository.updateClinicSettings(settings);
  }
}

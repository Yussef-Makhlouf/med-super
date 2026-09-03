import 'package:med_super/core/error/result.dart';
import 'package:med_super/features/provider_registration/domain/entities/clinic_working_day.dart';
import '../repositories/provider_dashboard_repository.dart';

class GetDoctorScheduleUseCase {
  GetDoctorScheduleUseCase(this._repository);

  final ProviderDashboardRepository _repository;

  Future<Result<List<ClinicWorkingDay>>> call() {
    return _repository.getDoctorSchedule();
  }
}

class UpdateDoctorScheduleUseCase {
  UpdateDoctorScheduleUseCase(this._repository);

  final ProviderDashboardRepository _repository;

  Future<Result<List<ClinicWorkingDay>>> call(
    List<ClinicWorkingDay> workingDays,
  ) {
    return _repository.updateDoctorSchedule(workingDays);
  }
}

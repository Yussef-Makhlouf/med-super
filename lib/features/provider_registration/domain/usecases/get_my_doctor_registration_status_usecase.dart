import 'package:med_super/core/error/result.dart';
import 'package:med_super/features/provider_registration/domain/entities/doctor_registration_status.dart';
import 'package:med_super/features/provider_registration/domain/repositories/provider_registration_repository.dart';

class GetMyDoctorRegistrationStatusUseCase {
  const GetMyDoctorRegistrationStatusUseCase(this._repository);

  final ProviderRegistrationRepository _repository;

  Future<Result<DoctorRegistrationStatus?>> call() =>
      _repository.getMyStatus();
}

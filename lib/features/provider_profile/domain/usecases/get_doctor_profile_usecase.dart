import 'package:med_super/core/error/result.dart';
import 'package:med_super/features/provider_profile/domain/entities/doctor_profile.dart';
import 'package:med_super/features/provider_profile/domain/repositories/doctor_profile_repository.dart';

class GetDoctorProfileUseCase {
  const GetDoctorProfileUseCase(this._repository);

  final DoctorProfileRepository _repository;

  Future<Result<DoctorProfile>> call(String doctorId) =>
      _repository.getDoctorProfile(doctorId);
}

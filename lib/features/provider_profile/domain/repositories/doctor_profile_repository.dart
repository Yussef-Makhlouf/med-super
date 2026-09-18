import 'package:med_super/core/error/result.dart';
import 'package:med_super/features/provider_profile/domain/entities/doctor_profile.dart';

abstract class DoctorProfileRepository {
  Future<Result<DoctorProfile>> getDoctorProfile(String doctorId);
}

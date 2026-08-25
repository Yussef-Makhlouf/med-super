import 'package:med_super/core/error/result.dart';
import 'package:med_super/features/provider_profile/domain/entities/clinic_profile.dart';

abstract class ClinicRepository {
  Future<Result<ClinicProfile>> getClinicProfile(String clinicId);
}

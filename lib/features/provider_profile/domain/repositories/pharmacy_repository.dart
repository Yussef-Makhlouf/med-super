import 'package:med_super/core/error/result.dart';
import 'package:med_super/features/provider_profile/domain/entities/pharmacy_profile.dart';

abstract class PharmacyRepository {
  Future<Result<PharmacyProfile>> getPharmacyProfile(String pharmacyId);
}

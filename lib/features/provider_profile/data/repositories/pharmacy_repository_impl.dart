import 'package:med_super/core/error/dio_failure_mapper.dart';
import 'package:med_super/core/error/result.dart';
import 'package:med_super/features/provider_profile/data/datasources/remote/pharmacy_remote_datasource.dart';
import 'package:med_super/features/provider_profile/domain/entities/pharmacy_profile.dart';
import 'package:med_super/features/provider_profile/domain/repositories/pharmacy_repository.dart';

class PharmacyRepositoryImpl implements PharmacyRepository {
  PharmacyRepositoryImpl({required PharmacyRemoteDatasource remote})
    : _remote = remote;

  final PharmacyRemoteDatasource _remote;

  @override
  Future<Result<PharmacyProfile>> getPharmacyProfile(
    String pharmacyId,
  ) async {
    try {
      final profile = await _remote.getPharmacyProfile(pharmacyId);
      return Result.ok(profile);
    } catch (e, st) {
      return Result.err(mapDioToFailure(e, st));
    }
  }
}

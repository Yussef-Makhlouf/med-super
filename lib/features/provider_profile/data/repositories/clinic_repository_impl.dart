import 'package:med_super/core/error/dio_failure_mapper.dart';
import 'package:med_super/core/error/result.dart';
import 'package:med_super/features/provider_profile/data/datasources/remote/clinic_remote_datasource.dart';
import 'package:med_super/features/provider_profile/domain/entities/clinic_profile.dart';
import 'package:med_super/features/provider_profile/domain/repositories/clinic_repository.dart';

class ClinicRepositoryImpl implements ClinicRepository {
  ClinicRepositoryImpl({required ClinicRemoteDatasource remote})
    : _remote = remote;

  final ClinicRemoteDatasource _remote;

  @override
  Future<Result<ClinicProfile>> getClinicProfile(String clinicId) async {
    try {
      final profile = await _remote.getClinicProfile(clinicId);
      return Result.ok(profile);
    } catch (e, st) {
      return Result.err(mapDioToFailure(e, st));
    }
  }
}

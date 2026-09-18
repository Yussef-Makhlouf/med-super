import 'package:med_super/core/error/dio_failure_mapper.dart';
import 'package:med_super/core/error/result.dart';
import 'package:med_super/features/provider_profile/data/datasources/remote/doctor_profile_remote_datasource.dart';
import 'package:med_super/features/provider_profile/domain/entities/doctor_profile.dart';
import 'package:med_super/features/provider_profile/domain/repositories/doctor_profile_repository.dart';

class DoctorProfileRepositoryImpl implements DoctorProfileRepository {
  DoctorProfileRepositoryImpl({required DoctorProfileRemoteDatasource remote})
    : _remote = remote;

  final DoctorProfileRemoteDatasource _remote;

  @override
  Future<Result<DoctorProfile>> getDoctorProfile(String doctorId) async {
    try {
      final profile = await _remote.getDoctorProfile(doctorId);
      return Result.ok(profile);
    } catch (e, st) {
      return Result.err(mapDioToFailure(e, st));
    }
  }
}

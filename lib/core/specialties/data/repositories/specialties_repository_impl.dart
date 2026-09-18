import 'package:med_super/core/error/dio_failure_mapper.dart';
import 'package:med_super/core/error/result.dart';
import 'package:med_super/core/specialties/data/datasources/remote/specialties_remote_datasource.dart';
import 'package:med_super/core/specialties/domain/entities/specialty.dart';
import 'package:med_super/core/specialties/domain/repositories/specialties_repository.dart';

class SpecialtiesRepositoryImpl implements SpecialtiesRepository {
  SpecialtiesRepositoryImpl({required SpecialtiesRemoteDatasource remote})
    : _remote = remote;

  final SpecialtiesRemoteDatasource _remote;

  @override
  Future<Result<List<Specialty>>> getSpecialties() async {
    try {
      final specialties = await _remote.getSpecialties();
      return Result.ok(specialties);
    } catch (e, st) {
      return Result.err(mapDioToFailure(e, st));
    }
  }
}

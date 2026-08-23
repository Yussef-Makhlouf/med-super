import 'package:med_super/core/error/dio_failure_mapper.dart';
import 'package:med_super/core/error/result.dart';
import 'package:med_super/features/search_discovery/data/datasources/remote/doctor_search_remote_datasource.dart';
import 'package:med_super/features/search_discovery/domain/entities/doctor_search_result.dart';
import 'package:med_super/features/search_discovery/domain/entities/doctor_sort.dart';
import 'package:med_super/features/search_discovery/domain/repositories/doctor_search_repository.dart';

class DoctorSearchRepositoryImpl implements DoctorSearchRepository {
  DoctorSearchRepositoryImpl({required DoctorSearchRemoteDatasource remote})
    : _remote = remote;

  final DoctorSearchRemoteDatasource _remote;

  @override
  Future<Result<DoctorSearchResult>> searchDoctors({
    String? query,
    String? specialty,
    DoctorSort sort = DoctorSort.topRated,
    double? latitude,
    double? longitude,
    double? radiusKm,
    DateTime? date,
    String? cursor,
    int limit = 20,
  }) async {
    try {
      final result = await _remote.searchDoctors(
        query: query,
        specialty: specialty,
        sort: sort,
        latitude: latitude,
        longitude: longitude,
        radiusKm: radiusKm,
        date: date,
        cursor: cursor,
        limit: limit,
      );
      return Result.ok(result);
    } catch (e, st) {
      return Result.err(mapDioToFailure(e, st));
    }
  }
}

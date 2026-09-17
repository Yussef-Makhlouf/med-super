import 'package:med_super/core/error/result.dart';
import 'package:med_super/features/search_discovery/domain/entities/doctor_search_result.dart';
import 'package:med_super/features/search_discovery/domain/entities/doctor_sort.dart';
import 'package:med_super/features/search_discovery/domain/repositories/doctor_search_repository.dart';

class SearchDoctorsUseCase {
  const SearchDoctorsUseCase(this._repository);

  final DoctorSearchRepository _repository;

  Future<Result<DoctorSearchResult>> call({
    String? query,
    String? specialty,
    DoctorSort sort = DoctorSort.topRated,
    double? latitude,
    double? longitude,
    String? cursor,
    int limit = 20,
  }) => _repository.searchDoctors(
    query: query,
    specialty: specialty,
    sort: sort,
    latitude: latitude,
    longitude: longitude,
    cursor: cursor,
    limit: limit,
  );
}

import 'package:med_super/core/error/result.dart';
import 'package:med_super/features/search_discovery/domain/entities/doctor_search_result.dart';
import 'package:med_super/features/search_discovery/domain/entities/doctor_sort.dart';

abstract class DoctorSearchRepository {
  Future<Result<DoctorSearchResult>> searchDoctors({
    String? query,
    String? specialty,
    DoctorSort sort = DoctorSort.topRated,
  });
}

import 'package:dio/dio.dart';
import 'package:med_super/core/constants/api_paths.dart';
import 'package:med_super/features/search_discovery/data/models/doctor_summary_dto.dart';
import 'package:med_super/features/search_discovery/domain/entities/doctor_search_result.dart';
import 'package:med_super/features/search_discovery/domain/entities/doctor_sort.dart';

class DoctorSearchRemoteDatasource {
  DoctorSearchRemoteDatasource(this._dio);

  final Dio _dio;

  Future<DoctorSearchResult> searchDoctors({
    String? query,
    String? specialty,
    DoctorSort sort = DoctorSort.topRated,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      ApiPaths.searchDoctors,
      queryParameters: {
        if (query != null && query.trim().isNotEmpty) 'q': query.trim(),
        if (specialty != null && specialty.isNotEmpty) 'specialty': specialty,
        'sort': sort.apiValue,
      },
    );
    final data = response.data ?? const <String, dynamic>{};
    final list = (data['doctors'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(DoctorSummaryDto.fromJson)
        .map((d) => d.toEntity())
        .toList();
    return DoctorSearchResult(
      doctors: list,
      totalCount: data['total_count'] as int? ?? list.length,
    );
  }
}

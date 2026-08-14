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
    double? latitude,
    double? longitude,
    double? radiusKm,
    DateTime? date,
    String? cursor,
    int limit = 20,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      ApiPaths.searchDoctors,
      queryParameters: {
        if (query != null && query.trim().isNotEmpty) 'q': query.trim(),
        if (specialty != null && specialty.isNotEmpty) 'specialty': specialty,
        'sort': sort.apiValue,
        if (latitude != null) 'lat': latitude,
        if (longitude != null) 'lng': longitude,
        if (radiusKm != null) 'radiusKm': radiusKm,
        if (date != null) 'date': _isoDate(date),
        if (cursor != null) 'cursor': cursor,
        'limit': limit,
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
      nextCursor: data['next_cursor'] as String?,
    );
  }

  /// `YYYY-MM-DD`, matching 05_API_RULES.md's ISO-8601 date convention.
  String _isoDate(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
}

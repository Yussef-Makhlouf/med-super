import 'package:dio/dio.dart';
import 'package:med_super/core/constants/api_paths.dart';
import 'package:med_super/features/lab_booking/data/models/lab_branch_dto.dart';
import 'package:med_super/features/lab_booking/domain/entities/lab_branch.dart';

/// One page of `GET /v1/lab-branches/search` — `nextCursor` is null once
/// there's nothing more to load. Mirrors `PharmacyBranchSearchPage`.
class LabBranchSearchPage {
  const LabBranchSearchPage({required this.items, required this.nextCursor});

  final List<LabBranch> items;
  final String? nextCursor;
}

class LabBranchSearchRemoteDatasource {
  LabBranchSearchRemoteDatasource(this._dio);

  final Dio _dio;

  /// `GET /v1/lab-branches/search` (`clinic-reservations`, added 2026-09-05
  /// to un-block this feature) — public, `@OptionalAuth()`, cursor-paginated.
  Future<LabBranchSearchPage> search({
    String? query,
    double? latitude,
    double? longitude,
    double? radiusKm,
    String? cursor,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '${ApiPaths.labBranches}/search',
      queryParameters: {
        if (query != null && query.trim().isNotEmpty) 'q': query.trim(),
        if (latitude != null) 'lat': latitude,
        if (longitude != null) 'lng': longitude,
        if (radiusKm != null) 'radiusKm': radiusKm,
        if (cursor != null) 'cursor': cursor,
      },
    );
    final data = response.data ?? const <String, dynamic>{};
    final items = (data['items'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(LabBranchDto.fromJson)
        .map((dto) => dto.toEntity())
        .toList();
    return LabBranchSearchPage(
      items: items,
      nextCursor: data['nextCursor'] as String?,
    );
  }
}

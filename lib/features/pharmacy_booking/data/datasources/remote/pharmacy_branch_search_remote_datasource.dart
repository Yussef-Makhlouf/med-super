import 'package:dio/dio.dart';
import 'package:med_super/core/constants/api_paths.dart';
import 'package:med_super/features/pharmacy_booking/data/models/pharmacy_branch_search_dto.dart';
import 'package:med_super/features/pharmacy_booking/domain/entities/pharmacy.dart';

class PharmacyBranchSearchRemoteDatasource {
  PharmacyBranchSearchRemoteDatasource(this._dio);

  final Dio _dio;

  /// `GET /v1/pharmacy-branches/search` (`clinic-reservations` File 12 Part
  /// 37) — public, `@OptionalAuth()`, cursor-paginated. This screen never
  /// paginates past the first page (no "load more" affordance exists yet),
  /// so `cursor`/`nextCursor` aren't threaded through here.
  Future<List<Pharmacy>> search({
    String? query,
    double? latitude,
    double? longitude,
    double? radiusKm,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '${ApiPaths.pharmacyBranches}/search',
      queryParameters: {
        if (query != null && query.trim().isNotEmpty) 'q': query.trim(),
        if (latitude != null) 'lat': latitude,
        if (longitude != null) 'lng': longitude,
        if (radiusKm != null) 'radiusKm': radiusKm,
      },
    );
    final data = response.data ?? const <String, dynamic>{};
    final items = (data['items'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(PharmacyBranchSearchItemDto.fromJson)
        .map((dto) => dto.toEntity())
        .whereType<Pharmacy>()
        .toList();
    return items;
  }
}

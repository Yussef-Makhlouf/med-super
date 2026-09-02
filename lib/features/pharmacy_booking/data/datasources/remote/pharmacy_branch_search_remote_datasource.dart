import 'package:dio/dio.dart';
import 'package:med_super/core/constants/api_paths.dart';
import 'package:med_super/features/pharmacy_booking/data/models/pharmacy_branch_search_dto.dart';
import 'package:med_super/features/pharmacy_booking/domain/entities/pharmacy.dart';

/// One page of `GET /v1/pharmacy-branches/search` — `nextCursor` is null
/// once there's nothing more to load, which is exactly the signal a "load
/// more" affordance needs to know whether to render at all.
class PharmacyBranchSearchPage {
  const PharmacyBranchSearchPage({required this.items, required this.nextCursor});

  final List<Pharmacy> items;
  final String? nextCursor;
}

class PharmacyBranchSearchRemoteDatasource {
  PharmacyBranchSearchRemoteDatasource(this._dio);

  final Dio _dio;

  /// `GET /v1/pharmacy-branches/search` (`clinic-reservations` File 12 Part
  /// 37) — public, `@OptionalAuth()`, cursor-paginated.
  Future<PharmacyBranchSearchPage> search({
    String? query,
    double? latitude,
    double? longitude,
    double? radiusKm,
    String? cursor,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '${ApiPaths.pharmacyBranches}/search',
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
        .map(PharmacyBranchSearchItemDto.fromJson)
        .map((dto) => dto.toEntity())
        .whereType<Pharmacy>()
        .toList();
    return PharmacyBranchSearchPage(
      items: items,
      nextCursor: data['nextCursor'] as String?,
    );
  }
}

import 'package:dio/dio.dart';
import 'package:med_super/core/constants/api_paths.dart';
import 'package:med_super/core/specialties/data/models/specialty_dto.dart';
import 'package:med_super/core/specialties/domain/entities/specialty.dart';

/// `GET /v1/specialties` — public (`@Public()`), no auth required.
/// `SpecialtiesController.list()` returns the raw `Specialty[]` array as
/// the envelope's `data` field directly (no `{items: [...]}` wrapper,
/// unlike most other list endpoints in this codebase) — so once
/// `ResponseEnvelopeInterceptor` unwraps the envelope, `response.data` is
/// itself a JSON array.
///
/// The mock interceptor (`mock_interceptor.dart`) can only hand back a
/// `Map` as a handler's `data` field, so the dev mock wraps the same array
/// under a `specialties` key — this datasource accepts either shape.
class SpecialtiesRemoteDatasource {
  SpecialtiesRemoteDatasource(this._dio);

  final Dio _dio;

  Future<List<Specialty>> getSpecialties() async {
    final response = await _dio.get<dynamic>(ApiPaths.specialties);
    final raw = response.data;
    final list = raw is List<dynamic>
        ? raw
        : raw is Map<String, dynamic>
        ? (raw['specialties'] as List<dynamic>? ??
              raw['items'] as List<dynamic>? ??
              const [])
        : const [];
    return list
        .whereType<Map<String, dynamic>>()
        .map(SpecialtyDto.fromJson)
        .map((d) => d.toEntity())
        .toList();
  }
}

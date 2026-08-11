import 'package:dio/dio.dart';
import 'package:med_super/core/constants/api_paths.dart';
import 'package:med_super/features/lab_booking/data/models/lab_catalog_dto.dart';
import 'package:med_super/features/lab_booking/domain/entities/lab_catalog.dart';

class LabCatalogRemoteDatasource {
  LabCatalogRemoteDatasource(this._dio);

  final Dio _dio;

  Future<LabCatalog> getCatalog({String? query, String? categoryId}) async {
    final response = await _dio.get<Map<String, dynamic>>(
      ApiPaths.labTests,
      queryParameters: {
        if (query != null && query.trim().isNotEmpty) 'q': query.trim(),
        if (categoryId != null && categoryId.isNotEmpty) 'category': categoryId,
      },
    );
    return LabCatalogDto.fromJson(response.data ?? const {}).toEntity();
  }
}

import 'package:med_super/core/error/dio_failure_mapper.dart';
import 'package:med_super/core/error/result.dart';
import 'package:med_super/features/lab_booking/data/datasources/remote/lab_catalog_remote_datasource.dart';
import 'package:med_super/features/lab_booking/domain/entities/lab_catalog.dart';
import 'package:med_super/features/lab_booking/domain/repositories/lab_catalog_repository.dart';

class LabCatalogRepositoryImpl implements LabCatalogRepository {
  LabCatalogRepositoryImpl({required LabCatalogRemoteDatasource remote})
    : _remote = remote;

  final LabCatalogRemoteDatasource _remote;

  @override
  Future<Result<LabCatalog>> getCatalog({
    String? query,
    String? categoryId,
  }) async {
    try {
      final result = await _remote.getCatalog(
        query: query,
        categoryId: categoryId,
      );
      return Result.ok(result);
    } catch (e, st) {
      return Result.err(mapDioToFailure(e, st));
    }
  }
}

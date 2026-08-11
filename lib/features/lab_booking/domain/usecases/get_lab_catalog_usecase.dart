import 'package:med_super/core/error/result.dart';
import 'package:med_super/features/lab_booking/domain/entities/lab_catalog.dart';
import 'package:med_super/features/lab_booking/domain/repositories/lab_catalog_repository.dart';

class GetLabCatalogUseCase {
  const GetLabCatalogUseCase(this._repository);

  final LabCatalogRepository _repository;

  Future<Result<LabCatalog>> call({String? query, String? categoryId}) =>
      _repository.getCatalog(query: query, categoryId: categoryId);
}

import 'package:med_super/core/error/result.dart';
import 'package:med_super/features/lab_booking/domain/entities/lab_catalog.dart';

abstract class LabCatalogRepository {
  Future<Result<LabCatalog>> getCatalog({String? query, String? categoryId});
}

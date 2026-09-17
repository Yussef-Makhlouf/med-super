import 'package:med_super/core/error/result.dart';
import 'package:med_super/core/specialties/domain/entities/specialty.dart';

abstract class SpecialtiesRepository {
  Future<Result<List<Specialty>>> getSpecialties();
}

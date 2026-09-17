import 'package:med_super/core/error/result.dart';
import 'package:med_super/core/specialties/domain/entities/specialty.dart';
import 'package:med_super/core/specialties/domain/repositories/specialties_repository.dart';

class ListSpecialtiesUseCase {
  const ListSpecialtiesUseCase(this._repository);

  final SpecialtiesRepository _repository;

  Future<Result<List<Specialty>>> call() => _repository.getSpecialties();
}

import 'package:med_super/core/error/result.dart';
import '../entities/patient.dart';
import '../repositories/provider_dashboard_repository.dart';

class GetPatientsUseCase {
  const GetPatientsUseCase(this._repository);
  final ProviderDashboardRepository _repository;

  Future<Result<List<Patient>>> call({String? query, String? filter}) {
    return _repository.getPatients(query: query, filter: filter);
  }
}

import 'package:med_super/core/error/result.dart';
import 'package:med_super/features/provider_profile/domain/entities/clinic_branch.dart';
import 'package:med_super/features/provider_profile/domain/repositories/clinic_branch_repository.dart';

class GetClinicBranchUseCase {
  const GetClinicBranchUseCase(this._repository);

  final ClinicBranchRepository _repository;

  Future<Result<ClinicBranch>> call(String branchId) =>
      _repository.getClinicBranch(branchId);
}

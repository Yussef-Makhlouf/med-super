import 'package:med_super/core/error/result.dart';
import 'package:med_super/features/provider_profile/domain/entities/pharmacy_branch.dart';
import 'package:med_super/features/provider_profile/domain/repositories/pharmacy_branch_repository.dart';

class GetPharmacyBranchUseCase {
  const GetPharmacyBranchUseCase(this._repository);

  final PharmacyBranchRepository _repository;

  Future<Result<PharmacyBranch>> call(String branchId) =>
      _repository.getPharmacyBranch(branchId);
}

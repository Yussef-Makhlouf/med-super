import 'package:med_super/core/error/result.dart';
import 'package:med_super/features/provider_profile/domain/entities/pharmacy_branch.dart';

abstract class PharmacyBranchRepository {
  Future<Result<PharmacyBranch>> getPharmacyBranch(String branchId);
}

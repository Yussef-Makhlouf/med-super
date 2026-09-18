import 'package:med_super/core/error/result.dart';
import 'package:med_super/features/provider_profile/domain/entities/clinic_branch.dart';

abstract class ClinicBranchRepository {
  Future<Result<ClinicBranch>> getClinicBranch(String branchId);
}

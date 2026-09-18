import 'package:med_super/core/error/dio_failure_mapper.dart';
import 'package:med_super/core/error/result.dart';
import 'package:med_super/features/provider_profile/data/datasources/remote/pharmacy_branch_remote_datasource.dart';
import 'package:med_super/features/provider_profile/domain/entities/pharmacy_branch.dart';
import 'package:med_super/features/provider_profile/domain/repositories/pharmacy_branch_repository.dart';

class PharmacyBranchRepositoryImpl implements PharmacyBranchRepository {
  PharmacyBranchRepositoryImpl({
    required PharmacyBranchRemoteDatasource remote,
  }) : _remote = remote;

  final PharmacyBranchRemoteDatasource _remote;

  @override
  Future<Result<PharmacyBranch>> getPharmacyBranch(String branchId) async {
    try {
      final branch = await _remote.getPharmacyBranch(branchId);
      return Result.ok(branch);
    } catch (e, st) {
      return Result.err(mapDioToFailure(e, st));
    }
  }
}

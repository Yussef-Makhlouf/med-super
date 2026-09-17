import 'package:med_super/core/error/dio_failure_mapper.dart';
import 'package:med_super/core/error/result.dart';
import 'package:med_super/features/provider_profile/data/datasources/remote/clinic_branch_remote_datasource.dart';
import 'package:med_super/features/provider_profile/domain/entities/clinic_branch.dart';
import 'package:med_super/features/provider_profile/domain/repositories/clinic_branch_repository.dart';

class ClinicBranchRepositoryImpl implements ClinicBranchRepository {
  ClinicBranchRepositoryImpl({required ClinicBranchRemoteDatasource remote})
    : _remote = remote;

  final ClinicBranchRemoteDatasource _remote;

  @override
  Future<Result<ClinicBranch>> getClinicBranch(String branchId) async {
    try {
      final branch = await _remote.getClinicBranch(branchId);
      return Result.ok(branch);
    } catch (e, st) {
      return Result.err(mapDioToFailure(e, st));
    }
  }
}

import 'package:dio/dio.dart';
import 'package:med_super/core/constants/api_paths.dart';
import 'package:med_super/features/provider_profile/data/models/clinic_branch_dto.dart';
import 'package:med_super/features/provider_profile/domain/entities/clinic_branch.dart';

/// `GET /v1/clinic-branches/:branchId` — optional auth (VERIFIED-only unless
/// the caller is an Admin, enforced server-side by `GetClinicBranchUseCase`).
class ClinicBranchRemoteDatasource {
  ClinicBranchRemoteDatasource(this._dio);

  final Dio _dio;

  Future<ClinicBranch> getClinicBranch(String branchId) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '${ApiPaths.clinicBranches}/$branchId',
    );
    return ClinicBranchDto.fromJson(
      response.data ?? const <String, dynamic>{},
    ).toEntity();
  }
}

import 'package:dio/dio.dart';
import 'package:med_super/core/constants/api_paths.dart';
import 'package:med_super/features/provider_profile/data/models/pharmacy_branch_dto.dart';
import 'package:med_super/features/provider_profile/domain/entities/pharmacy_branch.dart';

class PharmacyBranchRemoteDatasource {
  PharmacyBranchRemoteDatasource(this._dio);

  final Dio _dio;

  Future<PharmacyBranch> getPharmacyBranch(String branchId) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '${ApiPaths.pharmacyBranches}/$branchId',
    );
    return PharmacyBranchDto.fromJson(
      response.data ?? const <String, dynamic>{},
    ).toEntity();
  }
}

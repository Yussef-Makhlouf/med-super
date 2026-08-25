import 'package:dio/dio.dart';
import 'package:med_super/core/constants/api_paths.dart';
import 'package:med_super/features/provider_profile/data/models/pharmacy_profile_dto.dart';
import 'package:med_super/features/provider_profile/domain/entities/pharmacy_profile.dart';

/// `GET /v1/pharmacies/{pharmacyId}` — optional auth (public VERIFIED-only
/// detail unless the caller is Admin; enforced server-side by
/// `GetPharmacyUseCase`, nothing extra to send from the client).
class PharmacyRemoteDatasource {
  PharmacyRemoteDatasource(this._dio);

  final Dio _dio;

  Future<PharmacyProfile> getPharmacyProfile(String pharmacyId) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '${ApiPaths.pharmacies}/$pharmacyId',
    );
    return PharmacyProfileDto.fromJson(
      response.data ?? const <String, dynamic>{},
    ).toEntity();
  }
}

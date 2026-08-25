import 'package:dio/dio.dart';
import 'package:med_super/core/constants/api_paths.dart';
import 'package:med_super/features/provider_profile/data/models/clinic_profile_dto.dart';
import 'package:med_super/features/provider_profile/domain/entities/clinic_profile.dart';

/// `GET /v1/clinics/{clinicId}` — optional auth (public VERIFIED-only detail
/// unless the caller is Admin; enforced server-side by `GetClinicUseCase`,
/// nothing extra to send from the client).
class ClinicRemoteDatasource {
  ClinicRemoteDatasource(this._dio);

  final Dio _dio;

  Future<ClinicProfile> getClinicProfile(String clinicId) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '${ApiPaths.clinics}/$clinicId',
    );
    return ClinicProfileDto.fromJson(
      response.data ?? const <String, dynamic>{},
    ).toEntity();
  }
}

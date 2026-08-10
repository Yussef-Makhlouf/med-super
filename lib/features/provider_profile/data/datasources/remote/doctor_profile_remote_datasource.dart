import 'package:dio/dio.dart';
import 'package:med_super/core/constants/api_paths.dart';
import 'package:med_super/features/provider_profile/data/models/doctor_profile_dto.dart';
import 'package:med_super/features/provider_profile/domain/entities/doctor_profile.dart';

class DoctorProfileRemoteDatasource {
  DoctorProfileRemoteDatasource(this._dio);

  final Dio _dio;

  Future<DoctorProfile> getDoctorProfile(String doctorId) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '${ApiPaths.doctors}/$doctorId',
    );
    return DoctorProfileDto.fromJson(response.data ?? const <String, dynamic>{})
        .toEntity();
  }
}

import 'package:dio/dio.dart';
import 'package:med_super/core/constants/api_paths.dart';
import 'package:med_super/features/auth/data/models/auth_tokens_dto.dart';
import 'package:med_super/features/auth/data/models/user_dto.dart';
import 'package:med_super/features/auth/domain/entities/otp_request_result.dart';
import 'package:med_super/features/auth/domain/entities/user_role.dart';

class AuthRemoteDatasource {
  AuthRemoteDatasource(this._dio);

  final Dio _dio;

  Future<OtpRequestResult> requestOtp({
    required String phone,
    required UserRole role,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      ApiPaths.otpRequest,
      data: {
        'phone': phone,
        'role': role.apiValue,
      },
    );
    final data = response.data ?? const <String, dynamic>{};
    return OtpRequestResult(
      requestId: data['request_id'] as String? ?? 'req-unknown',
      expiresInSeconds: data['expires_in'] as int? ?? 60,
    );
  }

  Future<AuthTokensDto> verifyOtp({
    required String phone,
    required String code,
    required UserRole role,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      ApiPaths.otpVerify,
      data: {
        'phone': phone,
        'code': code,
        'role': role.apiValue,
      },
    );
    return AuthTokensDto.fromJson(response.data ?? const <String, dynamic>{});
  }

  Future<UserDto> me() async {
    final response = await _dio.get<Map<String, dynamic>>(ApiPaths.me);
    return UserDto.fromJson(response.data ?? const <String, dynamic>{});
  }

  Future<UserDto> updateProfile({required String displayName}) async {
    final response = await _dio.patch<Map<String, dynamic>>(
      ApiPaths.me,
      data: {'display_name': displayName},
    );
    return UserDto.fromJson(response.data ?? const <String, dynamic>{});
  }

  Future<void> logout() async {
    await _dio.post<void>(ApiPaths.logout);
  }
}

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
      data: {'phone': phone, 'role': role.apiValue},
    );
    final data = response.data ?? const <String, dynamic>{};
    return OtpRequestResult(
      requestId:
          (data['requestId'] ?? data['request_id']) as String? ??
          'req-unknown',
      expiresInSeconds:
          (data['expiresInSeconds'] ?? data['expires_in']) as int? ?? 60,
    );
  }

  Future<AuthTokensDto> verifyOtp({
    required String requestId,
    required String phone,
    required String code,
    required UserRole role,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      ApiPaths.otpVerify,
      data: {
        'requestId': requestId,
        'phone': phone,
        'code': code,
        'role': role.apiValue,
      },
    );
    return AuthTokensDto.fromJson(response.data ?? const <String, dynamic>{});
  }

  /// Requires a valid JWT bearer token already attached by [AuthInterceptor]
  /// (the caller must already be logged in from the OTP-verify step). The
  /// real backend responds 204/no body, so unlike the other auth calls this
  /// doesn't return any tokens — the ones saved during OTP verify remain the
  /// session's tokens.
  Future<void> setPassword({required String password}) async {
    await _dio.post<void>(ApiPaths.passwordSet, data: {'password': password});
  }

  Future<OtpRequestResult> forgotPassword({required String phone}) async {
    final response = await _dio.post<Map<String, dynamic>>(
      ApiPaths.passwordForgot,
      data: {'phone': phone},
    );
    final data = response.data ?? const <String, dynamic>{};
    return OtpRequestResult(
      requestId:
          (data['requestId'] ?? data['request_id']) as String? ??
          'req-unknown',
      expiresInSeconds:
          (data['expiresInSeconds'] ?? data['expires_in']) as int? ?? 60,
    );
  }

  /// Checks-only: validates [code] against [requestId] with no side effects
  /// and no tokens issued — used to gate the password-entry step behind a
  /// real backend check, distinct from the final [resetPassword] call which
  /// re-validates the code itself and actually performs the reset.
  Future<void> verifyResetCode({
    required String requestId,
    required String code,
  }) async {
    await _dio.post<void>(
      ApiPaths.passwordResetVerifyCode,
      data: {'requestId': requestId, 'code': code},
    );
  }

  /// The real backend responds 204/no body and does not return tokens —
  /// unlike OTP-verify/password-login/password-set, resetting a password
  /// does not log the user in.
  Future<void> resetPassword({
    required String requestId,
    required String code,
    required String newPassword,
  }) async {
    await _dio.post<void>(
      ApiPaths.passwordReset,
      data: {
        'requestId': requestId,
        'code': code,
        'newPassword': newPassword,
      },
    );
  }

  Future<AuthTokensDto> loginWithPassword({
    required String phone,
    required String password,
    required UserRole role,
  }) async {
    // `role` isn't part of the real `POST /v1/auth/password/login` request
    // body ({phone, password} only) — the backend returns userId and the
    // caller resolves the actual role via GET /v1/auth/me afterward. Sent
    // as a query param (not body) purely so MockInterceptor can honor the
    // role-toggle UI in dev — the real controller only reads `@Body()`, so
    // an extra query param is silently ignored there, never validated or
    // rejected.
    final response = await _dio.post<Map<String, dynamic>>(
      ApiPaths.passwordLogin,
      queryParameters: {'role': role.apiValue},
      data: {'phone': phone, 'password': password},
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

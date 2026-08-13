import 'package:dio/dio.dart';
import 'package:med_super/core/constants/api_paths.dart';
import 'package:med_super/core/storage/secure_storage_service.dart';

/// Attaches bearer token from [SecureStorageService].
/// On 401, attempts a silent token refresh once (mutex-guarded) then retries.
class AuthInterceptor extends Interceptor {
  AuthInterceptor(this._storage, this._dio);

  final SecureStorageService _storage;
  final Dio _dio;

  bool _isRefreshing = false;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Skip auth header for auth endpoints.
    if (_isAuthPath(options.path)) {
      handler.next(options);
      return;
    }
    try {
      final token = await _storage.accessToken;
      if (token != null) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    } catch (_) {
      // Token read failed (e.g. secure storage unavailable) — proceed
      // unauthenticated rather than silently dropping the request.
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    // Don't attempt refresh on auth endpoints (e.g. invalid OTP → 401).
    if (err.response?.statusCode != 401 ||
        _isRefreshing ||
        _isAuthPath(err.requestOptions.path)) {
      handler.next(err);
      return;
    }

    _isRefreshing = true;
    try {
      final refreshToken = await _storage.refreshToken;
      if (refreshToken == null) {
        await _storage.clearTokens();
        handler.next(err);
        return;
      }

      final response = await _dio.post<Map<String, dynamic>>(
        ApiPaths.refresh,
        data: {'refresh_token': refreshToken},
      );

      final data = response.data;
      if (data != null) {
        final newAccess = data['access_token'] as String?;
        final newRefresh = data['refresh_token'] as String?;
        if (newAccess != null) {
          await _storage.saveTokens(
            accessToken: newAccess,
            refreshToken: newRefresh ?? refreshToken,
          );
          // Retry original request with new token.
          final retryOptions = err.requestOptions
            ..headers['Authorization'] = 'Bearer $newAccess';
          final retryResponse = await _dio.fetch<dynamic>(retryOptions);
          handler.resolve(retryResponse);
          return;
        }
      }
    } catch (_) {
      await _storage.clearTokens();
    } finally {
      _isRefreshing = false;
    }

    handler.next(err);
  }

  bool _isAuthPath(String path) =>
      path.contains(ApiPaths.otpRequest) ||
      path.contains(ApiPaths.otpVerify) ||
      path.contains(ApiPaths.refresh);
}

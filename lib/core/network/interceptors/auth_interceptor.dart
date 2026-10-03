import 'package:dio/dio.dart';
import 'package:med_super/core/constants/api_paths.dart';
import 'package:med_super/core/storage/secure_storage_service.dart';

/// Attaches bearer token from [SecureStorageService].
/// On 401, refreshes once (single-flight across concurrent requests) and
/// replays the original request with the new token.
class AuthInterceptor extends Interceptor {
  AuthInterceptor(this._storage, this._dio);

  final SecureStorageService _storage;
  final Dio _dio;

  Future<String?>? _refreshInFlight;

  static const _replayedKey = '_authReplayed';

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
    final options = err.requestOptions;
    // Don't attempt refresh on auth endpoints (e.g. invalid OTP → 401), and
    // never refresh twice for the same request (a replay that 401s again
    // means the new token is rejected too — refreshing again would loop).
    if (err.response?.statusCode != 401 ||
        _isAuthPath(options.path) ||
        options.extra[_replayedKey] == true) {
      handler.next(err);
      return;
    }

    final sentToken = _bearerOf(options);
    final storedToken = await _readAccessToken();
    // Another request already refreshed after this one left: just replay
    // with the current token instead of rotating the refresh token again.
    final newAccess = storedToken != null && storedToken != sentToken
        ? storedToken
        : await _refreshOnce();
    if (newAccess == null) {
      handler.next(err);
      return;
    }

    options
      ..headers['Authorization'] = 'Bearer $newAccess'
      ..extra[_replayedKey] = true;
    try {
      handler.resolve(await _dio.fetch<dynamic>(options));
    } on DioException catch (replayError) {
      // A failed replay (5xx, timeout, …) is that request's own error; it
      // must not clear a session the refresh just renewed.
      handler.next(replayError);
    }
  }

  /// Single-flight refresh: every 401 that arrives while a refresh is running
  /// awaits the same call. The backend rotates refresh tokens and treats a
  /// replayed (already-rotated) one as theft, revoking every session — so
  /// two parallel refreshes would log the user out everywhere.
  Future<String?> _refreshOnce() {
    return _refreshInFlight ??= _refresh().whenComplete(
      () => _refreshInFlight = null,
    );
  }

  Future<String?> _refresh() async {
    try {
      final refreshToken = await _storage.refreshToken;
      if (refreshToken == null) {
        await _storage.clearTokens();
        return null;
      }
      // Real `RefreshTokenDto.refreshToken` is camelCase — the backend's
      // global ValidationPipe (forbidNonWhitelisted:true) rejects this call
      // with 400 if sent as snake_case, since the required field is then
      // missing. Response fields are camelCase too (`accessToken`/
      // `refreshToken`), no snake_case fallback exists on the real backend.
      final response = await _dio.post<Map<String, dynamic>>(
        ApiPaths.refresh,
        data: {'refreshToken': refreshToken},
      );
      final data = response.data;
      final newAccess = data?['accessToken'] as String?;
      if (newAccess == null) {
        await _storage.clearTokens();
        return null;
      }
      await _storage.saveTokens(
        accessToken: newAccess,
        refreshToken: data?['refreshToken'] as String? ?? refreshToken,
      );
      return newAccess;
    } catch (_) {
      await _storage.clearTokens();
      return null;
    }
  }

  Future<String?> _readAccessToken() async {
    try {
      return await _storage.accessToken;
    } catch (_) {
      return null;
    }
  }

  static String? _bearerOf(RequestOptions options) {
    final header = options.headers['Authorization'] as String?;
    return header != null && header.startsWith('Bearer ')
        ? header.substring(7)
        : null;
  }

  bool _isAuthPath(String path) =>
      path.contains(ApiPaths.otpRequest) ||
      path.contains(ApiPaths.otpVerify) ||
      path.contains(ApiPaths.refresh);
}

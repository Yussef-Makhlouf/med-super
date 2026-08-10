import 'package:dio/dio.dart';
import 'package:med_super/core/constants/durations.dart';

/// Exponential-backoff retry for safely retryable requests: GETs and POSTs
/// that already carry an Idempotency-Key. Max [AppDurations.retryMaxAttempts].
class RetryInterceptor extends Interceptor {
  RetryInterceptor(this._dio);

  final Dio _dio;

  static const _attemptKey = '_retryAttempt';
  static const _idempotencyHeader = 'Idempotency-Key';

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final options = err.requestOptions;
    final method = options.method.toUpperCase();
    final hasIdempotencyKey = options.headers.containsKey(_idempotencyHeader);
    final isRetryable = method == 'GET' || (method == 'POST' && hasIdempotencyKey);

    if (!isRetryable) {
      handler.next(err);
      return;
    }

    // Only retry on network errors or 5xx.
    final shouldRetry = err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.receiveTimeout ||
        err.type == DioExceptionType.connectionError ||
        (err.response?.statusCode != null &&
            err.response!.statusCode! >= 500);

    if (!shouldRetry) {
      handler.next(err);
      return;
    }

    final attempt = (options.extra[_attemptKey] as int? ?? 0) + 1;
    if (attempt > AppDurations.retryMaxAttempts) {
      handler.next(err);
      return;
    }

    final delay = AppDurations.retryBaseDelay * (1 << (attempt - 1));
    await Future<void>.delayed(delay);

    options.extra[_attemptKey] = attempt;
    try {
      final response = await _dio.fetch<dynamic>(options);
      handler.resolve(response);
    } on DioException catch (e) {
      handler.next(e);
    }
  }
}

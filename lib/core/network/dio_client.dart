import 'package:dio/dio.dart';
import 'package:med_super/core/constants/durations.dart';
import 'package:med_super/core/network/interceptors/auth_interceptor.dart';
import 'package:med_super/core/network/interceptors/correlation_id_interceptor.dart';
import 'package:med_super/core/network/interceptors/error_interceptor.dart';
import 'package:med_super/core/network/interceptors/idempotency_key_interceptor.dart';
import 'package:med_super/core/network/interceptors/logging_interceptor.dart';
import 'package:med_super/core/network/interceptors/retry_interceptor.dart';
import 'package:med_super/core/network/mock/mock_interceptor.dart';
import 'package:med_super/core/network/mock/mock_responses.dart';
import 'package:med_super/core/storage/secure_storage_service.dart';
import 'package:med_super/core/config/app_config.dart';

/// Configured Dio instance with the full interceptor chain:
/// Auth → Mock (dev) / CorrelationId+Idempotency → Logging → Error → Retry.
///
/// Auth runs before Mock so `/me` receives a Bearer token in mock mode.
Dio buildDioClient({required SecureStorageService storage}) {
  final config = AppConfig.instance;
  final dio = Dio(
    BaseOptions(
      baseUrl: config.baseUrl,
      connectTimeout: AppDurations.httpTimeout,
      receiveTimeout: AppDurations.httpTimeout,
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
    ),
  );

  // Attach bearer before mock short-circuit so authenticated mocks work.
  dio.interceptors.add(AuthInterceptor(storage, dio));

  if (config.isMock) {
    final mock = MockInterceptor();
    registerFoundationMocks(mock);
    registerSearchMocks(mock);
    registerLabBookingMocks(mock);
    registerProviderRegistrationMocks(mock);
    dio.interceptors.add(mock);
  } else {
    dio.interceptors.addAll([
      CorrelationIdInterceptor(),
      IdempotencyKeyInterceptor(),
      RetryInterceptor(dio),
    ]);
  }

  if (config.isDebug) {
    dio.interceptors.add(LoggingInterceptor());
  }
  dio.interceptors.add(ErrorInterceptor());

  return dio;
}

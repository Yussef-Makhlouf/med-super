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

import 'package:med_super/core/network/interceptors/response_envelope_interceptor.dart';

/// Configured Dio instance with the full interceptor chain, matching
/// 04_API_CONTRACT.md's documented order: Correlation ID → Auth →
/// Idempotency → (Mock short-circuit, dev only) → Debug logging → Response envelope unwrap → Error
/// normalization → Safe retry.
///
/// Request-side interceptors run in add-order; error-side interceptors run
/// in *reverse* add-order (Dio semantics) — so this same list also yields
/// the error chain Retry → Error → Auth(401 refresh-and-retry, last, as the
/// final fallback after generic retry has been exhausted).
///
/// Correlation ID / Idempotency / Retry previously only ran when
/// `!config.isMock`, meaning the default dev mode never exercised this
/// logic at all. They're now unconditional — Mock handlers can see (and,
/// for retry, meaningfully react to) the same headers/behavior a real
/// backend would, per the backend/frontend parity audit
/// (med-super/docs/backend_frontend_parity_matrix.md).
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

  dio.interceptors.add(CorrelationIdInterceptor());

  // Attach bearer before the mock short-circuit so authenticated mocks work.
  dio.interceptors.add(AuthInterceptor(storage, dio));

  dio.interceptors.add(IdempotencyKeyInterceptor());

  if (config.isMock) {
    final mock = MockInterceptor();
    registerFoundationMocks(mock);
    registerSpecialtiesMocks(mock);
    // Before registerSearchMocks: its doctor-detail handler matches any
    // '/v1/doctors/...' path by prefix, which would otherwise swallow
    // '/v1/doctors/{id}/slots' too (see registerAvailabilityMocks' docstring).
    registerAvailabilityMocks(mock);
    registerAppointmentMocks(mock);
    registerDoctorMeMocks(mock);
    registerSearchMocks(mock);
    registerClinicBranchMocks(mock);
    registerPharmacyBranchSearchMocks(mock);
    registerPharmacyBranchMocks(mock);
    registerLabBookingMocks(mock);
    registerPrescriptionMocks(mock);
    registerPharmacyOrderMocks(mock);
    registerProviderRegistrationMocks(mock);
    registerProviderDashboardMocks(mock);
    registerWalletMocks(mock);
    registerAssistantMocks(mock);
    dio.interceptors.add(mock);
  }

  dio.interceptors.add(ResponseEnvelopeInterceptor());

  if (config.isDebug) {
    dio.interceptors.add(LoggingInterceptor());
  }

  dio.interceptors.add(ErrorInterceptor());
  dio.interceptors.add(RetryInterceptor(dio));

  return dio;
}

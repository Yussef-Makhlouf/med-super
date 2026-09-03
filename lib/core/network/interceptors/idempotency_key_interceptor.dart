import 'dart:math';
import 'package:dio/dio.dart';

/// Attaches an Idempotency-Key header on mutating requests (POST/PUT/PATCH)
/// that don't already carry one. Retries of the same request reuse the key
/// stored in [RequestOptions.extra].
class IdempotencyKeyInterceptor extends Interceptor {
  static const _headerName = 'Idempotency-Key';
  static const _extraKey = '_idempotencyKey';

  // Phase 4 (Appointments) is real now — hold/confirm/cancel/reschedule all
  // match `/appointments`, so this list is exercised for real by
  // `AppointmentsRemoteDatasource`. `/payment-intents` stays forward-looking
  // for Phase 5 (Payments), which still doesn't exist in the backend.
  static const _idempotentPaths = [
    '/appointments',
    '/payment-intents',
    '/appointments/hold',
    // Phase 6 (Prescriptions) — POST /v1/prescriptions/upload is guarded by
    // the backend's IdempotencyInterceptor (File 11 Part 11).
    '/prescriptions',
    // Phase 7 (Pharmacy Fulfillment) — POST /v1/pharmacy-orders is guarded
    // the same way.
    '/pharmacy-orders',
  ];

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final method = options.method.toUpperCase();
    final needsKey =
        (method == 'POST' || method == 'PUT' || method == 'PATCH') &&
        _idempotentPaths.any((p) => options.path.contains(p));

    if (needsKey && !options.headers.containsKey(_headerName)) {
      final key = options.extra[_extraKey] as String? ?? _generateKey();
      options.extra[_extraKey] = key;
      options.headers[_headerName] = key;
    }
    handler.next(options);
  }

  static String _generateKey() {
    final rng = Random.secure();
    final bytes = List<int>.generate(16, (_) => rng.nextInt(256));
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }
}

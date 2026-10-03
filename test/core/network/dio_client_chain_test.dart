import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:med_super/core/constants/storage_keys.dart';
import 'package:med_super/core/error/api_exception.dart';
import 'package:med_super/core/network/dio_client.dart';
import 'package:med_super/core/network/mock/mock_interceptor.dart';
import 'package:med_super/core/storage/secure_storage_service.dart';

/// Scripted transport: each call pops the next (status, body) pair and
/// records the request it saw.
class _ScriptedAdapter implements HttpClientAdapter {
  _ScriptedAdapter(this._script);

  final List<(int, Object?)> _script;
  final List<RequestOptions> seen = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    seen.add(options);
    final (status, body) = _script.removeAt(0);
    return ResponseBody.fromString(
      jsonEncode(body),
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

/// The production chain from [buildDioClient], minus the dev-only mock
/// short-circuit, talking to a scripted transport — i.e. exactly what a
/// real-backend build runs.
(Dio, _ScriptedAdapter) _realChain(List<(int, Object?)> script) {
  FlutterSecureStorage.setMockInitialValues({
    StorageKeys.accessToken: 'access-1',
    StorageKeys.refreshToken: 'refresh-1',
  });
  final storage = SecureStorageService(const FlutterSecureStorage());
  final dio = buildDioClient(storage: storage)
    ..interceptors.removeWhere((i) => i is MockInterceptor);
  final adapter = _ScriptedAdapter(script);
  dio.httpClientAdapter = adapter;
  return (dio, adapter);
}

Map<String, Object?> _error(String code) => {
  'success': false,
  'error': {'code': code, 'message': 'x', 'correlationId': 'c-1'},
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('a GET that hits 503 is retried and succeeds', () async {
    final (dio, adapter) = _realChain([
      (503, _error('UPSTREAM_UNAVAILABLE')),
      (200, {'success': true, 'data': {'ok': true}}),
    ]);

    final response = await dio.get<dynamic>('/v1/doctors');

    expect(adapter.seen, hasLength(2));
    expect(response.statusCode, 200);
  });

  test('an idempotent POST retried after 5xx reuses the same Idempotency-Key', () async {
    final (dio, adapter) = _realChain([
      (502, _error('BAD_GATEWAY')),
      (201, {'success': true, 'data': {'id': 'apt-1'}}),
    ]);

    await dio.post<dynamic>('/v1/appointments/hold', data: {'slotId': 's'});

    expect(adapter.seen, hasLength(2));
    final keys = adapter.seen.map((o) => o.headers['Idempotency-Key']).toSet();
    expect(keys, hasLength(1));
    expect(keys.single, isNotNull);
  });

  test('a POST without an Idempotency-Key is never retried (no duplicate write)', () async {
    final (dio, adapter) = _realChain([
      (503, _error('UPSTREAM_UNAVAILABLE')),
      (201, {'success': true, 'data': {}}),
    ]);

    await expectLater(
      dio.post<dynamic>('/v1/notifications/read-all'),
      throwsA(isA<DioException>()),
    );
    expect(adapter.seen, hasLength(1));
  });

  test('retries stop after the bounded attempt count and surface ApiException', () async {
    final (dio, adapter) = _realChain([
      for (var i = 0; i < 6; i++) (500, _error('INTERNAL')),
    ]);

    final error = await dio
        .get<dynamic>('/v1/doctors')
        .then<DioException?>((_) => null, onError: (Object e) => e as DioException);

    expect(adapter.seen, hasLength(4)); // 1 + retryMaxAttempts(3)
    expect(error!.error, isA<ApiException>());
    expect((error.error! as ApiException).code, 'INTERNAL');
  });

  test('a 4xx business error is never retried and is normalised to ApiException', () async {
    final (dio, adapter) = _realChain([
      (422, _error('APPOINTMENT_NOT_CANCELLABLE')),
    ]);

    final error = await dio
        .get<dynamic>('/v1/appointments/1')
        .then<DioException?>((_) => null, onError: (Object e) => e as DioException);

    expect(adapter.seen, hasLength(1));
    expect((error!.error! as ApiException).code, 'APPOINTMENT_NOT_CANCELLABLE');
    expect((error.error! as ApiException).statusCode, 422);
  });

  test('a 401 refreshes once, then replays the original request with the new token', () async {
    final (dio, adapter) = _realChain([
      (401, _error('UNAUTHORIZED')),
      (200, {'success': true, 'data': {'accessToken': 'access-2', 'refreshToken': 'refresh-2'}}),
      (200, {'success': true, 'data': {'ok': true}}),
    ]);

    final response = await dio.get<dynamic>('/v1/appointments');

    expect(response.statusCode, 200);
    expect(adapter.seen.map((o) => o.path), ['/v1/appointments', '/v1/auth/token/refresh', '/v1/appointments']);
    expect(adapter.seen.last.headers['Authorization'], 'Bearer access-2');
  });

  test('two requests that 401 together share one refresh and both succeed', () async {
    // A and B leave with the expired token and both come back 401 before
    // either refresh finishes (e.g. several screens loading on app resume).
    final (dio, adapter) = _realChain([
      (401, _error('UNAUTHORIZED')),
      (401, _error('UNAUTHORIZED')),
      (200, {'success': true, 'data': {'accessToken': 'access-2', 'refreshToken': 'refresh-2'}}),
      (200, {'success': true, 'data': {'a': true}}),
      (200, {'success': true, 'data': {'b': true}}),
    ]);

    final results = await Future.wait([
      dio.get<dynamic>('/v1/appointments'),
      dio.get<dynamic>('/v1/notifications'),
    ]);

    expect(results.map((r) => r.statusCode), [200, 200]);
    final refreshes = adapter.seen.where((o) => o.path == '/v1/auth/token/refresh');
    // Exactly one refresh: the backend revokes every session when a rotated
    // refresh token is replayed, so a second concurrent refresh would log
    // the user out everywhere.
    expect(refreshes, hasLength(1));
    expect(
      adapter.seen.skip(3).map((o) => o.headers['Authorization']),
      everyElement('Bearer access-2'),
    );
  });

  test('a replay that fails with 5xx keeps the renewed session (no logout on server error)', () async {
    final (dio, adapter) = _realChain([
      (401, _error('UNAUTHORIZED')),
      (200, {'success': true, 'data': {'accessToken': 'access-2', 'refreshToken': 'refresh-2'}}),
      for (var i = 0; i < 4; i++) (500, _error('INTERNAL')),
    ]);

    await expectLater(dio.get<dynamic>('/v1/appointments'), throwsA(isA<DioException>()));

    const storage = FlutterSecureStorage();
    expect(await storage.read(key: StorageKeys.accessToken), 'access-2');
    expect(await storage.read(key: StorageKeys.refreshToken), 'refresh-2');
  });

  test('a rejected refresh clears the session and surfaces the original 401', () async {
    final (dio, adapter) = _realChain([
      (401, _error('UNAUTHORIZED')),
      (401, _error('REFRESH_TOKEN_REVOKED')),
    ]);

    final error = await dio
        .get<dynamic>('/v1/appointments')
        .then<DioException?>((_) => null, onError: (Object e) => e as DioException);

    expect(error!.response?.statusCode, 401);
    expect(adapter.seen, hasLength(2));
    expect(await const FlutterSecureStorage().read(key: StorageKeys.accessToken), isNull);
  });

  test('a replay that is still 401 does not refresh again (no loop)', () async {
    final (dio, adapter) = _realChain([
      (401, _error('UNAUTHORIZED')),
      (200, {'success': true, 'data': {'accessToken': 'access-2', 'refreshToken': 'refresh-2'}}),
      (401, _error('UNAUTHORIZED')),
    ]);

    await expectLater(dio.get<dynamic>('/v1/appointments'), throwsA(isA<DioException>()));
    expect(adapter.seen.where((o) => o.path == '/v1/auth/token/refresh'), hasLength(1));
    expect(adapter.seen, hasLength(3));
  });
}


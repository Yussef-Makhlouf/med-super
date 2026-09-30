import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:med_super/core/network/interceptors/idempotency_key_interceptor.dart';

class _RecordingAdapter implements HttpClientAdapter {
  RequestOptions? lastRequest;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    lastRequest = options;
    return ResponseBody.fromString(
      jsonEncode({'success': true, 'data': {'ok': true}}),
      200,
      headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  test('adds backend-required idempotency keys to provider clinical writes', () async {
    final adapter = _RecordingAdapter();
    final dio = Dio(BaseOptions(baseUrl: 'https://api.example.test'))
      ..httpClientAdapter = adapter
      ..interceptors.add(IdempotencyKeyInterceptor());

    for (final path in [
      '/v1/lab-orders/provider',
      '/v1/prescriptions/provider/upload',
      '/v1/pharmacy-orders/provider',
    ]) {
      await dio.post<void>(path, data: const {'test': true});
      final key = adapter.lastRequest!.headers['Idempotency-Key'] as String?;
      expect(key, isNotNull, reason: '$path requires an idempotency key');
      expect(key, matches(RegExp(r'^[0-9a-f]{32}$')));
    }

    dio.close();
  });
}

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

typedef MockHandler = Map<String, dynamic>? Function(RequestOptions options);

/// Short-circuits matching requests with in-memory responses.
/// Active by default when AppConfig.isMock == true.
/// Add per-feature responses by calling [register].
class MockInterceptor extends Interceptor {
  final Map<String, MockHandler> _handlers = {};

  void register(String method, String pathPattern, MockHandler handler) {
    _handlers['${method.toUpperCase()}:$pathPattern'] = handler;
  }

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final response = _findResponse(options);
    if (response != null) {
      if (kDebugMode) debugPrint('[MOCK] ${options.method} ${options.path}');
      final statusCode = response['statusCode'] as int? ?? 200;
      final data = response['data'] as Map<String, dynamic>?;
      final mockResponse = Response<Map<String, dynamic>>(
        requestOptions: options,
        statusCode: statusCode,
        data: data,
      );

      // Non-2xx → reject so ErrorInterceptor can map to ApiException.
      if (statusCode >= 400) {
        handler.reject(
          DioException(
            requestOptions: options,
            response: mockResponse,
            type: DioExceptionType.badResponse,
            message: '[MOCK] HTTP $statusCode',
          ),
          true,
        );
        return;
      }

      handler.resolve(mockResponse, true);
      return;
    }

    // No handler matched — simulate no-network instead of hanging.
    handler.reject(
      DioException(
        requestOptions: options,
        type: DioExceptionType.connectionError,
        message: '[MOCK] No handler for ${options.method} ${options.path}',
      ),
      true,
    );
  }

  Map<String, dynamic>? _findResponse(RequestOptions options) {
    for (final entry in _handlers.entries) {
      final parts = entry.key.split(':');
      final method = parts[0];
      final pattern = parts.sublist(1).join(':');
      if (method == options.method.toUpperCase() &&
          options.path.contains(pattern)) {
        return entry.value(options);
      }
    }
    return null;
  }
}

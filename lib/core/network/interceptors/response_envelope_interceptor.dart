import 'package:dio/dio.dart';

/// Interceptor that automatically unwraps backend response envelopes.
///
/// The backend wraps successful JSON responses in a standard envelope:
/// ```json
/// {
///   "success": true,
///   "data": { ...actual payload... },
///   "requestId": "...",
///   "correlationId": "..."
/// }
/// ```
/// This interceptor extracts the inner `data` field and sets it as [Response.data]
/// for downstream datasources and DTOs.
class ResponseEnvelopeInterceptor extends Interceptor {
  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    final data = response.data;
    if (data is Map<String, dynamic>) {
      // Check if it matches the standard success envelope
      if (data.containsKey('success') && data.containsKey('data')) {
        final innerData = data['data'];
        response.data = innerData;
      }
    }
    handler.next(response);
  }
}

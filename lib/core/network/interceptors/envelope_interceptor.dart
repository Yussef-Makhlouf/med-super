import 'package:dio/dio.dart';

/// Unwraps the backend's global success envelope
/// (`{ success: true, data: {...}, requestId, correlationId }` —
/// `clinic-reservations/src/shared/core/http/response.interceptor.ts`,
/// applied to every 2xx response) so every datasource can keep reading the
/// inner payload directly, exactly as it already does today.
///
/// Nothing unwrapped this before — every datasource in this app currently
/// reads flat fields (e.g. `response.data['slots']`) that only exist once
/// this envelope is stripped. Against a real backend, every one of those
/// reads would silently return `null`. Mock responses are unaffected: they
/// have no `success` key (`MockInterceptor` already resolves with the flat
/// inner shape), so the check below simply doesn't match and leaves them
/// untouched.
class EnvelopeInterceptor extends Interceptor {
  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    final body = response.data;
    if (body is Map<String, dynamic> &&
        body['success'] == true &&
        body.containsKey('data')) {
      response.data = body['data'];
    }
    handler.next(response);
  }
}

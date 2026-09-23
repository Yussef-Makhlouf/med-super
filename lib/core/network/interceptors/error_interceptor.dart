import 'package:dio/dio.dart';
import 'package:med_super/core/error/api_exception.dart';

/// Normalizes any Dio failure into [ApiException] by parsing the backend's
/// standard error envelope: `{ error: { code, message, correlation_id } }`.
class ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final response = err.response;

    if (response != null) {
      final data = response.data;
      String code = 'UNKNOWN';
      String? message;
      String? correlationId;

      Map<String, dynamic>? details;
      if (data is Map<String, dynamic>) {
        final errorObj = data['error'] as Map<String, dynamic>?;
        if (errorObj != null) {
          code = errorObj['code'] as String? ?? code;
          message = errorObj['message'] as String?;
          correlationId =
              errorObj['correlationId'] as String? ??
              errorObj['correlation_id'] as String?;
          final rawDetails = errorObj['details'];
          if (rawDetails is Map<String, dynamic>) details = rawDetails;
        }
      }

      handler.reject(
        DioException(
          requestOptions: err.requestOptions,
          response: response,
          type: err.type,
          error: ApiException(
            statusCode: response.statusCode ?? 0,
            code: code,
            message: message,
            correlationId: correlationId,
            details: details,
          ),
        ),
      );
      return;
    }

    handler.next(err);
  }
}

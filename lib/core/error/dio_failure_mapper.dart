import 'package:dio/dio.dart';
import 'package:med_super/core/constants/api_paths.dart';
import 'package:med_super/core/error/api_exception.dart';
import 'package:med_super/core/error/failure.dart';

/// Maps Dio/network failures to [Failure] at the repository boundary.
Failure mapDioToFailure(Object error, [StackTrace? stackTrace]) {
  if (error is DioException) {
    final api = error.error;
    if (api is ApiException) {
      if (api.isUnauthorized) {
        // Login and OTP failures are 401 responses, but they are not an
        // expired session because the user has not established a session yet.
        if (_isCredentialFailure(api.code) ||
            (_isPasswordLoginPath(error) && api.code == 'UNAUTHENTICATED') ||
            api.code == 'OTP_INVALID' ||
            api.code == 'OTP_EXPIRED') {
          return Failure.server(
            statusCode: api.statusCode,
            code: _isPasswordLoginPath(error) && api.code == 'UNAUTHENTICATED'
                ? 'INVALID_CREDENTIALS'
                : api.code,
            message: api.message,
            correlationId: api.correlationId,
          );
        }
        return const Failure.auth();
      }
      if (api.isConflict) {
        return Failure.conflict(api.message ?? api.code, code: api.code);
      }
      if (api.isValidation) {
        // The backend sends one Arabic sentence per business rule; keep the
        // code alongside it so `failureMessage()` can prefer app-local copy.
        // Known `details` keys (`minAmount`, `fullAmount`) ride along so a
        // screen can show the server's number instead of guessing.
        return Failure.validation(
          _validationFieldErrors(api),
          code: api.code,
        );
      }
      return Failure.server(
        statusCode: api.statusCode,
        code: api.code,
        message: api.message,
        correlationId: api.correlationId,
      );
    }

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.connectionError:
        return const Failure.network();
      case DioExceptionType.badResponse:
        final status = error.response?.statusCode ?? 0;
        final data = error.response?.data;
        if (data is Map<String, dynamic>) {
          final envelope = data['error'] as Map<String, dynamic>?;
          if (envelope != null) {
            final code = envelope['code'] as String? ?? 'UNKNOWN';
            if (status == 401 &&
                !_isCredentialFailure(code) &&
                !(_isPasswordLoginPath(error) && code == 'UNAUTHENTICATED')) {
              return const Failure.auth();
            }
            if (status == 401 &&
                _isPasswordLoginPath(error) &&
                code == 'UNAUTHENTICATED') {
              return Failure.server(
                statusCode: status,
                code: 'INVALID_CREDENTIALS',
                message: envelope['message'] as String?,
                correlationId: envelope['correlation_id'] as String?,
              );
            }
            if (status == 409) {
              return Failure.conflict(
                envelope['message'] as String? ?? code,
                code: code,
              );
            }
            return Failure.server(
              statusCode: status,
              code: code,
              message: envelope['message'] as String?,
              correlationId: envelope['correlation_id'] as String?,
            );
          }
        }
        return Failure.server(
          statusCode: status,
          code: 'HTTP_$status',
          message: error.message,
        );
      default:
        break;
    }

    return Failure.unknown(error, stackTrace ?? error.stackTrace);
  }

  return Failure.unknown(error, stackTrace ?? StackTrace.current);
}

bool _isCredentialFailure(String code) => switch (code) {
  'INVALID_CREDENTIALS' || 'ACCOUNT_SUSPENDED' || 'ACCOUNT_NOT_FOUND' => true,
  _ => false,
};

bool _isPasswordLoginPath(DioException error) =>
    error.requestOptions.path.contains(ApiPaths.passwordLogin);

Map<String, String> _validationFieldErrors(ApiException api) {
  final fields = <String, String>{'form': api.message ?? api.code};
  final details = api.details;
  if (details == null) return fields;
  for (final key in const ['minAmount', 'fullAmount']) {
    final value = details[key];
    if (value != null) fields[key] = value.toString();
  }
  return fields;
}

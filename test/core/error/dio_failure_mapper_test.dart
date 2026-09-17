import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:med_super/core/error/api_exception.dart';
import 'package:med_super/core/error/dio_failure_mapper.dart';
import 'package:med_super/core/error/failure.dart';

void main() {
  DioException errorFor(
    String code, {
    String path = '/v1/auth/password/login',
  }) => DioException(
    requestOptions: RequestOptions(path: path),
    error: ApiException(statusCode: 401, code: code),
  );

  test('does not label invalid login credentials as an expired session', () {
    final failure = mapDioToFailure(errorFor('INVALID_CREDENTIALS'));

    expect(failure, isA<ServerFailure>());
    expect((failure as ServerFailure).code, 'INVALID_CREDENTIALS');
  });

  test('maps backend login UNAUTHENTICATED to invalid credentials', () {
    final failure = mapDioToFailure(errorFor('UNAUTHENTICATED'));

    expect(failure, isA<ServerFailure>());
    expect((failure as ServerFailure).code, 'INVALID_CREDENTIALS');
  });

  test('keeps unauthorized protected requests as authentication failures', () {
    final failure = mapDioToFailure(
      errorFor('UNAUTHENTICATED', path: '/v1/pharmacy-orders'),
    );

    expect(failure, isA<AuthFailure>());
  });
}

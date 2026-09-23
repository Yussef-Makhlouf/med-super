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

  test('carries payment-amount details on a 422 so the field can show the min',
      () {
    final failure = mapDioToFailure(
      DioException(
        requestOptions: RequestOptions(path: '/v1/appointments/hold-1/confirm'),
        error: const ApiException(
          statusCode: 422,
          code: 'PAYMENT_AMOUNT_BELOW_MINIMUM',
          message: 'المبلغ أقل من الحد الأدنى المسموح به للدفع.',
          details: {'minAmount': '50.00'},
        ),
      ),
    );

    expect(failure, isA<ValidationFailure>());
    final validation = failure as ValidationFailure;
    expect(validation.code, 'PAYMENT_AMOUNT_BELOW_MINIMUM');
    expect(validation.fieldErrors['minAmount'], '50.00');
  });
}

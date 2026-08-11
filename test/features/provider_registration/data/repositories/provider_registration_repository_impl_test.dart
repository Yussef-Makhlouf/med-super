import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:med_super/core/error/failure.dart';
import 'package:med_super/features/provider_registration/data/datasources/remote/provider_registration_remote_datasource.dart';
import 'package:med_super/features/provider_registration/data/repositories/provider_registration_repository_impl.dart';
import 'package:med_super/features/provider_registration/domain/entities/doctor_registration_draft.dart';
import 'package:mocktail/mocktail.dart';

class _MockRemoteDatasource extends Mock
    implements ProviderRegistrationRemoteDatasource {}

void main() {
  late _MockRemoteDatasource remote;
  late ProviderRegistrationRepositoryImpl repository;

  setUpAll(() {
    registerFallbackValue(const DoctorRegistrationDraft());
  });

  setUp(() {
    remote = _MockRemoteDatasource();
    repository = ProviderRegistrationRepositoryImpl(remote: remote);
  });

  const draft = DoctorRegistrationDraft(fullName: 'Dr. X');

  test('submit returns Result.ok(null) when the datasource succeeds', () async {
    when(() => remote.submit(any())).thenAnswer((_) async {});

    final result = await repository.submit(draft);

    expect(result.isOk, isTrue);
    verify(() => remote.submit(draft)).called(1);
  });

  test('submit maps a generic exception to Failure.unknown', () async {
    final exception = Exception('boom');
    when(() => remote.submit(any())).thenThrow(exception);

    final result = await repository.submit(draft);

    expect(result.isErr, isTrue);
    final failure = result.failureOrNull;
    expect(failure, isA<UnknownFailure>());
  });

  test(
    'submit maps a connectionError DioException to Failure.network',
    () async {
      final dioException = DioException(
        requestOptions: RequestOptions(path: '/v1/provider/registration'),
        type: DioExceptionType.connectionError,
      );
      when(() => remote.submit(any())).thenThrow(dioException);

      final result = await repository.submit(draft);

      expect(result.isErr, isTrue);
      expect(result.failureOrNull, const Failure.network());
    },
  );

  test('submit maps a 401 badResponse DioException to Failure.auth', () async {
    final dioException = DioException(
      requestOptions: RequestOptions(path: '/v1/provider/registration'),
      type: DioExceptionType.badResponse,
      response: Response(
        requestOptions: RequestOptions(path: '/v1/provider/registration'),
        statusCode: 401,
        data: <String, dynamic>{
          'error': {'code': 'UNAUTHORIZED'},
        },
      ),
    );
    when(() => remote.submit(any())).thenThrow(dioException);

    final result = await repository.submit(draft);

    expect(result.isErr, isTrue);
    expect(result.failureOrNull, const Failure.auth());
  });

  test(
    'submit maps a 500 badResponse DioException to Failure.server with code',
    () async {
      final dioException = DioException(
        requestOptions: RequestOptions(path: '/v1/provider/registration'),
        type: DioExceptionType.badResponse,
        response: Response(
          requestOptions: RequestOptions(path: '/v1/provider/registration'),
          statusCode: 500,
          data: <String, dynamic>{
            'error': {'code': 'SERVER_ERROR', 'message': 'oops'},
          },
        ),
      );
      when(() => remote.submit(any())).thenThrow(dioException);

      final result = await repository.submit(draft);

      final failure = result.failureOrNull;
      expect(failure, isA<ServerFailure>());
      expect((failure as ServerFailure).statusCode, 500);
      expect(failure.code, 'SERVER_ERROR');
      expect(failure.message, 'oops');
    },
  );

  test('submit does not swallow success — passes the exact draft', () async {
    when(() => remote.submit(any())).thenAnswer((_) async {});

    await repository.submit(draft);

    final captured = verify(() => remote.submit(captureAny())).captured;
    expect(captured.single, same(draft));
  });
}

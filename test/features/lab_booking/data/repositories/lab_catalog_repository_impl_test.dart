import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:med_super/core/error/failure.dart';
import 'package:med_super/core/error/result.dart';
import 'package:med_super/features/lab_booking/data/datasources/remote/lab_catalog_remote_datasource.dart';
import 'package:med_super/features/lab_booking/data/repositories/lab_catalog_repository_impl.dart';
import 'package:med_super/features/lab_booking/domain/entities/lab_catalog.dart';

class _MockLabCatalogRemoteDatasource extends Mock
    implements LabCatalogRemoteDatasource {}

void main() {
  late _MockLabCatalogRemoteDatasource remote;
  late LabCatalogRepositoryImpl repository;

  setUp(() {
    remote = _MockLabCatalogRemoteDatasource();
    repository = LabCatalogRepositoryImpl(remote: remote);
  });

  const catalog = LabCatalog(categories: [], tests: [], suggestedLabs: []);

  test('returns Result.ok with the datasource value on success', () async {
    when(
      () => remote.getCatalog(
        query: any(named: 'query'),
        categoryId: any(named: 'categoryId'),
      ),
    ).thenAnswer((_) async => catalog);

    final result = await repository.getCatalog(query: 'q', categoryId: 'c');

    expect(result, isA<Ok<LabCatalog>>());
    expect(result.valueOrNull, catalog);
  });

  test('maps a DioException to a network Failure on connection error', () async {
    when(
      () => remote.getCatalog(
        query: any(named: 'query'),
        categoryId: any(named: 'categoryId'),
      ),
    ).thenThrow(
      DioException(
        requestOptions: RequestOptions(path: '/v1/lab-tests'),
        type: DioExceptionType.connectionError,
      ),
    );

    final result = await repository.getCatalog();

    expect(result, isA<Err<LabCatalog>>());
    expect(result.failureOrNull, const Failure.network());
  });

  test('maps a non-Dio exception to Failure.unknown', () async {
    when(
      () => remote.getCatalog(
        query: any(named: 'query'),
        categoryId: any(named: 'categoryId'),
      ),
    ).thenThrow(Exception('boom'));

    final result = await repository.getCatalog();

    expect(result, isA<Err<LabCatalog>>());
    expect(result.failureOrNull, isA<UnknownFailure>());
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:med_super/core/error/failure.dart';
import 'package:med_super/core/error/result.dart';
import 'package:med_super/features/lab_booking/domain/entities/lab_catalog.dart';
import 'package:med_super/features/lab_booking/domain/repositories/lab_catalog_repository.dart';
import 'package:med_super/features/lab_booking/domain/usecases/get_lab_catalog_usecase.dart';

class _MockLabCatalogRepository extends Mock implements LabCatalogRepository {}

void main() {
  late _MockLabCatalogRepository repository;
  late GetLabCatalogUseCase useCase;

  setUp(() {
    repository = _MockLabCatalogRepository();
    useCase = GetLabCatalogUseCase(repository);
  });

  const catalog = LabCatalog(categories: [], tests: [], suggestedLabs: []);

  test('delegates to repository.getCatalog with the given args', () async {
    when(
      () => repository.getCatalog(query: 'cbc', categoryId: 'blood'),
    ).thenAnswer((_) async => const Result.ok(catalog));

    final result = await useCase.call(query: 'cbc', categoryId: 'blood');

    expect(result, isA<Ok<LabCatalog>>());
    verify(
      () => repository.getCatalog(query: 'cbc', categoryId: 'blood'),
    ).called(1);
  });

  test('passes through null query/categoryId when omitted', () async {
    when(
      () => repository.getCatalog(query: null, categoryId: null),
    ).thenAnswer((_) async => const Result.ok(catalog));

    final result = await useCase.call();

    expect(result.valueOrNull, catalog);
  });

  test('propagates a failure result unchanged', () async {
    const failure = Failure.network();
    when(
      () => repository.getCatalog(query: any(named: 'query'), categoryId: any(named: 'categoryId')),
    ).thenAnswer((_) async => const Result.err(failure));

    final result = await useCase.call();

    expect(result, isA<Err<LabCatalog>>());
    expect(result.failureOrNull, failure);
  });
}

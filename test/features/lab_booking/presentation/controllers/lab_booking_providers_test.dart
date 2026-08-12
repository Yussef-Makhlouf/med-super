import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:med_super/core/error/failure.dart';
import 'package:med_super/core/error/result.dart';
import 'package:med_super/features/lab_booking/domain/entities/lab_catalog.dart';
import 'package:med_super/features/lab_booking/domain/entities/lab_test.dart';
import 'package:med_super/features/lab_booking/domain/entities/lab_test_category.dart';
import 'package:med_super/features/lab_booking/domain/repositories/lab_catalog_repository.dart';
import 'package:med_super/features/lab_booking/presentation/controllers/lab_booking_providers.dart';

class _MockLabCatalogRepository extends Mock implements LabCatalogRepository {}

void main() {
  late _MockLabCatalogRepository repository;
  late ProviderContainer container;

  const category = LabTestCategory(id: 'blood', labelKey: 'k');
  const cheapTest = LabTest(
    id: 'cheap',
    name: 'Cheap',
    price: 100,
    currency: 'EGP',
    isPackage: false,
    requiresFasting: false,
    categoryId: 'blood',
  );
  const vitaminDTest = LabTest(
    id: 'vitamin-d',
    name: 'Vitamin D',
    price: 200,
    currency: 'EGP',
    isPackage: false,
    requiresFasting: false,
    categoryId: 'blood',
  );
  final catalog = LabCatalog(
    categories: const [category],
    tests: const [cheapTest, vitaminDTest],
    suggestedLabs: const [],
  );

  setUp(() {
    repository = _MockLabCatalogRepository();
    container = ProviderContainer(
      overrides: [labCatalogRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
  });

  group('activeLabCategoryProvider', () {
    test('defaults to "packages"', () {
      expect(container.read(activeLabCategoryProvider), 'packages');
    });

    test('select updates the state', () {
      container.read(activeLabCategoryProvider.notifier).select('vitamins');
      expect(container.read(activeLabCategoryProvider), 'vitamins');
    });

    test('select can clear back to null', () {
      container.read(activeLabCategoryProvider.notifier).select('vitamins');
      container.read(activeLabCategoryProvider.notifier).select(null);
      expect(container.read(activeLabCategoryProvider), isNull);
    });
  });

  group('labSearchQueryProvider', () {
    test('defaults to empty string', () {
      expect(container.read(labSearchQueryProvider), '');
    });

    test('setQuery updates the state', () {
      container.read(labSearchQueryProvider.notifier).setQuery('cbc');
      expect(container.read(labSearchQueryProvider), 'cbc');
    });
  });

  group('selectedLabTestsProvider', () {
    test('defaults to a set containing "vitamin-d"', () {
      expect(container.read(selectedLabTestsProvider), {'vitamin-d'});
    });

    test('toggle adds a test id not yet selected', () {
      container.read(selectedLabTestsProvider.notifier).toggle('cheap');
      expect(container.read(selectedLabTestsProvider), {'vitamin-d', 'cheap'});
    });

    test('toggle removes a test id already selected', () {
      container.read(selectedLabTestsProvider.notifier).toggle('vitamin-d');
      expect(container.read(selectedLabTestsProvider), isEmpty);
    });

    test('toggling twice is a no-op relative to the original state', () {
      final notifier = container.read(selectedLabTestsProvider.notifier);
      notifier.toggle('cheap');
      notifier.toggle('cheap');
      expect(container.read(selectedLabTestsProvider), {'vitamin-d'});
    });
  });

  group('labCatalogProvider', () {
    test('resolves to the repository catalog on success', () async {
      when(
        () => repository.getCatalog(
          query: any(named: 'query'),
          categoryId: any(named: 'categoryId'),
        ),
      ).thenAnswer((_) async => Result.ok(catalog));

      final result = await container.read(labCatalogProvider.future);

      expect(result, catalog);
    });

    test('watches activeLabCategory/searchQuery and forwards them', () async {
      when(
        () => repository.getCatalog(query: 'q1', categoryId: 'vitamins'),
      ).thenAnswer((_) async => Result.ok(catalog));

      container.read(activeLabCategoryProvider.notifier).select('vitamins');
      container.read(labSearchQueryProvider.notifier).setQuery('q1');

      await container.read(labCatalogProvider.future);

      verify(
        () => repository.getCatalog(query: 'q1', categoryId: 'vitamins'),
      ).called(1);
    });

    test('throws the Failure when the repository returns Result.err', () async {
      when(
        () => repository.getCatalog(
          query: any(named: 'query'),
          categoryId: any(named: 'categoryId'),
        ),
      ).thenAnswer((_) async => const Result.err(Failure.network()));

      // `container.read(provider.future)` raced with autoDispose in this
      // riverpod version (the provider could be torn down before the mocked
      // Future settled, surfacing a disposal StateError instead of our
      // Failure). Listening directly and capturing the AsyncError via the
      // listener callback avoids that race entirely.
      final errorCompleter = Completer<Object>();
      final sub = container.listen(labCatalogProvider, (previous, next) {
        if (next.hasError && !errorCompleter.isCompleted) {
          errorCompleter.complete(next.error);
        }
      }, fireImmediately: true);
      addTearDown(sub.close);

      final error = await errorCompleter.future.timeout(
        const Duration(seconds: 5),
      );
      expect(error, const Failure.network());
    });
  });

  group('selectedLabTestsTotalProvider', () {
    setUp(() {
      when(
        () => repository.getCatalog(
          query: any(named: 'query'),
          categoryId: any(named: 'categoryId'),
        ),
      ).thenAnswer((_) async => Result.ok(catalog));
    });

    test('sums the price of every selected test (default selection)', () async {
      final total = await container.read(selectedLabTestsTotalProvider.future);
      expect(total, vitaminDTest.price);
    });

    test('updates when a test is added to the selection', () async {
      container.read(selectedLabTestsProvider.notifier).toggle('cheap');
      final total = await container.read(selectedLabTestsTotalProvider.future);
      expect(total, vitaminDTest.price + cheapTest.price);
    });

    test('is 0 when the selection is empty', () async {
      container.read(selectedLabTestsProvider.notifier).toggle('vitamin-d');
      final total = await container.read(selectedLabTestsTotalProvider.future);
      expect(total, 0);
    });

    test('is the sum of all tests when everything is selected', () async {
      container.read(selectedLabTestsProvider.notifier).toggle('cheap');
      final total = await container.read(selectedLabTestsTotalProvider.future);
      expect(total, cheapTest.price + vitaminDTest.price);
    });

    test(
      'stays correct after switching the active category filter — '
      'regression test: the total used to resolve against the '
      'category-filtered labCatalogProvider, so a selected test whose '
      'category was no longer active silently dropped out of the sum',
      () async {
        // 'vitamin-d' (the default selection) belongs to category 'blood'.
        // Switching the active filter to a category that excludes it must
        // not change the total.
        when(
          () => repository.getCatalog(query: '', categoryId: 'other'),
        ).thenAnswer(
          (_) async => Result.ok(
            LabCatalog(categories: const [category], tests: const [cheapTest], suggestedLabs: const []),
          ),
        );

        final totalBefore = await container.read(
          selectedLabTestsTotalProvider.future,
        );
        expect(totalBefore, vitaminDTest.price);

        container.read(activeLabCategoryProvider.notifier).select('other');
        // labCatalogProvider (category-filtered) now excludes 'vitamin-d'
        // entirely, but the total must still find it via the unfiltered
        // allLabTestsProvider.
        final filteredCatalog = await container.read(
          labCatalogProvider.future,
        );
        expect(
          filteredCatalog.tests.any((t) => t.id == 'vitamin-d'),
          isFalse,
        );

        final totalAfter = await container.read(
          selectedLabTestsTotalProvider.future,
        );
        expect(totalAfter, vitaminDTest.price);
      },
    );
  });

  group('allLabTestsProvider', () {
    test('always requests the unfiltered catalog (null query/category)', () async {
      when(
        () => repository.getCatalog(query: null, categoryId: null),
      ).thenAnswer((_) async => Result.ok(catalog));

      final result = await container.read(allLabTestsProvider.future);

      expect(result, catalog);
      verify(() => repository.getCatalog(query: null, categoryId: null)).called(1);
    });

    test(
      'does not refetch when activeLabCategory/searchQuery change — it is '
      'independent of those filters, unlike labCatalogProvider',
      () async {
        when(
          () => repository.getCatalog(query: null, categoryId: null),
        ).thenAnswer((_) async => Result.ok(catalog));
        when(
          () => repository.getCatalog(
            query: any(named: 'query'),
            categoryId: any(named: 'categoryId'),
          ),
        ).thenAnswer((_) async => Result.ok(catalog));

        await container.read(allLabTestsProvider.future);
        container.read(activeLabCategoryProvider.notifier).select('vitamins');
        container.read(labSearchQueryProvider.notifier).setQuery('q');
        await container.read(allLabTestsProvider.future);

        verify(
          () => repository.getCatalog(query: null, categoryId: null),
        ).called(1);
      },
    );
  });
}

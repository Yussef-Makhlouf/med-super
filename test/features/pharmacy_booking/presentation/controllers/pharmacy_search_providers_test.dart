import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:med_super/features/pharmacy_booking/domain/entities/pharmacy_sort_option.dart';
import 'package:med_super/features/pharmacy_booking/presentation/controllers/pharmacy_search_providers.dart';

// Matches `mockPharmacies`' fixed-UUID ids (kept in sync with the real
// backend's seeded demo pharmacies — see that list's own doc comment).
const _ph1 = '00000000-0000-0000-0000-000000000101';
const _ph2 = '00000000-0000-0000-0000-000000000102';
const _ph3 = '00000000-0000-0000-0000-000000000103';

void main() {
  late ProviderContainer container;

  setUp(() {
    container = ProviderContainer();
    addTearDown(container.dispose);
  });

  group('pharmaciesProvider', () {
    test('resolves to the 3 mock pharmacies', () async {
      final result = await container.read(pharmaciesProvider.future);

      expect(result, hasLength(3));
      expect(result.map((p) => p.id), [_ph1, _ph2, _ph3]);
    });
  });

  group('selectedPharmacyProvider', () {
    test('defaults to null (no explicit choice yet)', () {
      expect(container.read(selectedPharmacyProvider), isNull);
    });

    test('select stores the chosen pharmacy id', () {
      container.read(selectedPharmacyProvider.notifier).select(_ph2);
      expect(container.read(selectedPharmacyProvider), _ph2);
    });
  });

  group('pharmacySearchQueryProvider', () {
    test('defaults to empty string', () {
      expect(container.read(pharmacySearchQueryProvider), '');
    });

    test('setQuery updates the state', () {
      container.read(pharmacySearchQueryProvider.notifier).setQuery('نهدي');
      expect(container.read(pharmacySearchQueryProvider), 'نهدي');
    });
  });

  group('pharmacyOpenNowOnlyFilterProvider', () {
    test('defaults to false', () {
      expect(container.read(pharmacyOpenNowOnlyFilterProvider), isFalse);
    });

    test('toggle flips the state', () {
      container.read(pharmacyOpenNowOnlyFilterProvider.notifier).toggle();
      expect(container.read(pharmacyOpenNowOnlyFilterProvider), isTrue);
    });
  });

  group('pharmacySortProvider', () {
    test('defaults to nearest', () {
      expect(container.read(pharmacySortProvider), PharmacySortOption.nearest);
    });

    test('select updates the state', () {
      container
          .read(pharmacySortProvider.notifier)
          .select(PharmacySortOption.topRated);
      expect(container.read(pharmacySortProvider), PharmacySortOption.topRated);
    });
  });

  group('filteredPharmaciesProvider', () {
    test('defaults to nearest-first order', () async {
      final result = await container.read(filteredPharmaciesProvider.future);
      expect(result.map((p) => p.id), [_ph1, _ph2, _ph3]);
    });

    test('sorts by rating descending when topRated is selected', () async {
      container
          .read(pharmacySortProvider.notifier)
          .select(PharmacySortOption.topRated);

      final result = await container.read(filteredPharmaciesProvider.future);
      expect(result.map((p) => p.id), [_ph1, _ph2, _ph3]);
    });

    test('filters out closed pharmacies when openNowOnly is true', () async {
      container.read(pharmacyOpenNowOnlyFilterProvider.notifier).toggle();

      final result = await container.read(filteredPharmaciesProvider.future);
      expect(result.map((p) => p.id), [_ph1, _ph2]);
    });

    test('filters by name matching the search query', () async {
      container.read(pharmacySearchQueryProvider.notifier).setQuery('الدواء');

      final result = await container.read(filteredPharmaciesProvider.future);
      expect(result.map((p) => p.id), [_ph2]);
    });

    test('filters by address matching the search query', () async {
      container.read(pharmacySearchQueryProvider.notifier).setQuery('العليا');

      final result = await container.read(filteredPharmaciesProvider.future);
      expect(result.map((p) => p.id), [_ph3]);
    });

    test('returns an empty list when nothing matches the query', () async {
      container
          .read(pharmacySearchQueryProvider.notifier)
          .setQuery('nonexistent');

      final result = await container.read(filteredPharmaciesProvider.future);
      expect(result, isEmpty);
    });
  });
}

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:med_super/features/pharmacy_booking/domain/entities/pharmacy.dart';
import 'package:med_super/features/pharmacy_booking/domain/entities/pharmacy_sort_option.dart';
import 'package:med_super/features/pharmacy_booking/domain/entities/pharmacy_status.dart';

/// Hand-rolled (no `@riverpod` codegen — see the feature's build notes)
/// mock data source for step 2 of the pharmacy booking flow. There is no
/// backend endpoint for this yet, so a short simulated delay stands in for
/// the network round trip a real `FutureProvider` would await, which keeps
/// the loading-skeleton state exercised the same way it would be for real
/// data.
@visibleForTesting
const mockPharmacies = <Pharmacy>[
  Pharmacy(
    id: 'ph1',
    name: 'صيدلية النهدي',
    address: 'شارع التحلية، الرياض',
    distanceKm: 1.2,
    rating: 4.8,
    ratingCount: 1200,
    latitude: 24.7136,
    longitude: 46.6753,
    status: PharmacyStatus(state: PharmacyOpenState.open24h),
  ),
  Pharmacy(
    id: 'ph2',
    name: 'صيدلية الدواء',
    address: 'طريق الملك فهد، الرياض',
    distanceKm: 2.5,
    rating: 4.5,
    ratingCount: 850,
    latitude: 24.7255,
    longitude: 46.6851,
    status: PharmacyStatus(state: PharmacyOpenState.openUntil, time: '11:30 م'),
  ),
  Pharmacy(
    id: 'ph3',
    name: 'صيدلية المجتمع',
    address: 'حي العليا، الرياض',
    distanceKm: 3.8,
    rating: 4.2,
    ratingCount: 320,
    latitude: 24.6944,
    longitude: 46.6892,
    status: PharmacyStatus(
      state: PharmacyOpenState.closedUntilTomorrow,
      time: '8:00 ص',
    ),
  ),
];

/// All candidate pharmacies for the current prescription — a mock
/// FutureProvider standing in for a real backend call (see [mockPharmacies]).
final pharmaciesProvider = FutureProvider<List<Pharmacy>>((ref) async {
  await Future<void>.delayed(const Duration(milliseconds: 600));
  return mockPharmacies;
});

/// Explicitly chosen pharmacy id — null means "not chosen yet, default to
/// the first result", matching the Figma state where the top card is
/// pre-selected without any tap.
class SelectedPharmacy extends Notifier<String?> {
  @override
  String? build() => null;

  void select(String pharmacyId) => state = pharmacyId;
}

final selectedPharmacyProvider = NotifierProvider<SelectedPharmacy, String?>(
  SelectedPharmacy.new,
);

/// Free-text search query typed into the "ابحث عن صيدلية..." box.
class PharmacySearchQuery extends Notifier<String> {
  @override
  String build() => '';

  void setQuery(String query) => state = query;
}

final pharmacySearchQueryProvider =
    NotifierProvider<PharmacySearchQuery, String>(PharmacySearchQuery.new);

/// "مفتوح الآن" filter chip — when true, only currently-open pharmacies show.
class PharmacyOpenNowOnlyFilter extends Notifier<bool> {
  @override
  bool build() => false;

  void toggle() => state = !state;
}

final pharmacyOpenNowOnlyFilterProvider =
    NotifierProvider<PharmacyOpenNowOnlyFilter, bool>(
      PharmacyOpenNowOnlyFilter.new,
    );

/// Sort order for the pharmacy list — defaults to "الأقرب إليك" (nearest)
/// per the mockup, where that chip is selected out of the box.
class PharmacySort extends Notifier<PharmacySortOption> {
  @override
  PharmacySortOption build() => PharmacySortOption.nearest;

  void select(PharmacySortOption sort) => state = sort;
}

final pharmacySortProvider = NotifierProvider<PharmacySort, PharmacySortOption>(
  PharmacySort.new,
);

/// [pharmaciesProvider] narrowed by the search query and the "مفتوح الآن"
/// filter, then ordered by the selected sort option — all client-side since
/// there is no backend for this mock data.
final filteredPharmaciesProvider = FutureProvider<List<Pharmacy>>((ref) async {
  final pharmacies = await ref.watch(pharmaciesProvider.future);
  final query = ref.watch(pharmacySearchQueryProvider).trim().toLowerCase();
  final openNowOnly = ref.watch(pharmacyOpenNowOnlyFilterProvider);
  final sort = ref.watch(pharmacySortProvider);

  var result = pharmacies.where((pharmacy) {
    if (openNowOnly && !pharmacy.status.state.isOpen) return false;
    if (query.isEmpty) return true;
    return pharmacy.name.toLowerCase().contains(query) ||
        pharmacy.address.toLowerCase().contains(query);
  }).toList();

  result.sort(
    (a, b) => switch (sort) {
      PharmacySortOption.topRated => b.rating.compareTo(a.rating),
      PharmacySortOption.nearest => a.distanceKm.compareTo(b.distanceKm),
    },
  );

  return result;
});

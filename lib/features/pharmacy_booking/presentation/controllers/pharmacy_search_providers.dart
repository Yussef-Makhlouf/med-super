import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:med_super/core/di/core_providers.dart';
import 'package:med_super/features/pharmacy_booking/data/datasources/remote/pharmacy_branch_search_remote_datasource.dart';
import 'package:med_super/features/pharmacy_booking/domain/entities/pharmacy.dart';
import 'package:med_super/features/provider_registration/presentation/controllers/clinic_location_provider.dart';

/// Plain (non-codegen) Riverpod providers — deliberately not `@riverpod`,
/// mirroring `provider_profile/presentation/controllers/pharmacy_branch_providers.dart`'s
/// build-runner-free style.
final pharmacyBranchSearchRemoteDatasourceProvider =
    Provider<PharmacyBranchSearchRemoteDatasource>(
      (ref) => PharmacyBranchSearchRemoteDatasource(ref.watch(dioProvider)),
    );

/// Reuses the geolocator wrapper already built for provider registration
/// (`ClinicLocationService`) rather than duplicating the platform-permission
/// dance — same reuse `PharmacyMapView`'s "locate me" button already makes.
final pharmacyLocationServiceProvider = Provider(
  (ref) => const ClinicLocationService(),
);

/// Accumulated pharmacy branches plus pagination state for the current
/// prescription — `GET /v1/pharmacy-branches/search` (`clinic-reservations`
/// File 12 Part 37). Best-effort device location: if permission is
/// denied/unavailable, the search still runs without `lat`/`lng` (server
/// sorts by name instead of distance, and every result's `distanceKm` comes
/// back null — the card hides its distance row in that case rather than
/// showing a fabricated number).
class PharmacySearchState {
  const PharmacySearchState({
    required this.items,
    required this.nextCursor,
    required this.isLoadingMore,
  });

  final List<Pharmacy> items;
  final String? nextCursor;
  final bool isLoadingMore;

  /// A "load more" affordance should only ever render when the backend
  /// actually said there's another page — never as an always-on control the
  /// user has to discover does nothing once the real count is under a page.
  bool get hasMore => nextCursor != null;

  PharmacySearchState copyWith({
    List<Pharmacy>? items,
    String? nextCursor,
    bool clearNextCursor = false,
    bool? isLoadingMore,
  }) => PharmacySearchState(
    items: items ?? this.items,
    nextCursor: clearNextCursor ? null : (nextCursor ?? this.nextCursor),
    isLoadingMore: isLoadingMore ?? this.isLoadingMore,
  );
}

class PharmacySearchNotifier extends AsyncNotifier<PharmacySearchState> {
  @override
  Future<PharmacySearchState> build() async {
    final query = ref.watch(pharmacySearchQueryProvider);
    final position = await ref
        .watch(pharmacyLocationServiceProvider)
        .getCurrentPosition();
    var page = await ref
        .watch(pharmacyBranchSearchRemoteDatasourceProvider)
        .search(
          query: query,
          latitude: position?.latitude,
          longitude: position?.longitude,
        );

    // A valid but stale/emulator location can be outside the backend's
    // default 15 km radius. Keep the nearby sort when it works, but do not
    // turn the pharmacy picker into an empty state when a broader catalogue
    // search can still offer verified branches.
    if (page.items.isEmpty && position != null) {
      page = await ref
          .watch(pharmacyBranchSearchRemoteDatasourceProvider)
          .search(query: query);
    }

    return PharmacySearchState(
      items: page.items,
      nextCursor: page.nextCursor,
      isLoadingMore: false,
    );
  }

  Future<void> loadMore() async {
    final current = state.value;
    if (current == null || !current.hasMore || current.isLoadingMore) return;

    state = AsyncData(current.copyWith(isLoadingMore: true));
    try {
      final position = await ref
          .read(pharmacyLocationServiceProvider)
          .getCurrentPosition();
      final page = await ref
          .read(pharmacyBranchSearchRemoteDatasourceProvider)
          .search(
            query: ref.read(pharmacySearchQueryProvider),
            latitude: position?.latitude,
            longitude: position?.longitude,
            cursor: current.nextCursor,
          );
      state = AsyncData(
        current.copyWith(
          items: [...current.items, ...page.items],
          nextCursor: page.nextCursor,
          clearNextCursor: page.nextCursor == null,
          isLoadingMore: false,
        ),
      );
    } catch (_) {
      // A failed "load more" leaves the already-loaded page intact — only
      // the trailing spinner clears, so the user doesn't lose what already
      // rendered and can just tap the button again.
      state = AsyncData(current.copyWith(isLoadingMore: false));
    }
  }
}

final pharmacySearchProvider =
    AsyncNotifierProvider<PharmacySearchNotifier, PharmacySearchState>(
      PharmacySearchNotifier.new,
    );

/// Back-compat view over [pharmacySearchProvider] for callers that only
/// need the flat item list (the map view, the search-query filter below).
final pharmaciesProvider = FutureProvider<List<Pharmacy>>((ref) async {
  final state = await ref.watch(pharmacySearchProvider.future);
  return state.items;
});

/// Explicitly chosen branch id — null means "not chosen yet, default to the
/// first result", matching the Figma state where the top card is
/// pre-selected without any tap.
class SelectedPharmacy extends Notifier<String?> {
  @override
  String? build() => null;

  void select(String branchId) => state = branchId;

  void clear() => state = null;
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

/// [pharmaciesProvider] narrowed by the search query, sorted by distance
/// (nearest first, unknown-distance results last). The query is sent to the
/// backend by [PharmacySearchNotifier] and retained here as a defensive local
/// filter for mock/older responses that may ignore it.
final filteredPharmaciesProvider = FutureProvider<List<Pharmacy>>((ref) async {
  final pharmacies = await ref.watch(pharmaciesProvider.future);
  final query = ref.watch(pharmacySearchQueryProvider).trim().toLowerCase();

  final result = pharmacies.where((pharmacy) {
    if (query.isEmpty) return true;
    return pharmacy.name.toLowerCase().contains(query) ||
        pharmacy.address.toLowerCase().contains(query);
  }).toList();

  result.sort((a, b) {
    final da = a.distanceKm;
    final db = b.distanceKm;
    if (da == null && db == null) return 0;
    if (da == null) return 1;
    if (db == null) return -1;
    return da.compareTo(db);
  });

  return result;
});

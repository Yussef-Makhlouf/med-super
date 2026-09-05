import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:med_super/core/di/core_providers.dart';
import 'package:med_super/features/lab_booking/data/datasources/remote/lab_branch_search_remote_datasource.dart';
import 'package:med_super/features/lab_booking/domain/entities/lab_branch.dart';
import 'package:med_super/features/provider_registration/presentation/controllers/clinic_location_provider.dart';

/// Plain (non-codegen) Riverpod providers — mirrors
/// `pharmacy_booking/presentation/controllers/pharmacy_search_providers.dart`'s
/// build-runner-free style exactly, adapted from pharmacy branches to lab
/// branches.
final labBranchSearchRemoteDatasourceProvider =
    Provider<LabBranchSearchRemoteDatasource>(
      (ref) => LabBranchSearchRemoteDatasource(ref.watch(dioProvider)),
    );

/// Reuses the geolocator wrapper already built for provider registration
/// (`ClinicLocationService`) rather than duplicating the platform-permission
/// dance.
final labBranchLocationServiceProvider = Provider(
  (ref) => const ClinicLocationService(),
);

/// Accumulated lab branches plus pagination state for the current request —
/// `GET /v1/lab-branches/search`. Best-effort device location: if permission
/// is denied/unavailable, the search still runs without `lat`/`lng` (server
/// sorts by name instead of distance, and every result's `distanceKm` comes
/// back null — the card hides its distance row in that case).
class LabBranchSearchState {
  const LabBranchSearchState({
    required this.items,
    required this.nextCursor,
    required this.isLoadingMore,
  });

  final List<LabBranch> items;
  final String? nextCursor;
  final bool isLoadingMore;

  bool get hasMore => nextCursor != null;

  LabBranchSearchState copyWith({
    List<LabBranch>? items,
    String? nextCursor,
    bool clearNextCursor = false,
    bool? isLoadingMore,
  }) => LabBranchSearchState(
    items: items ?? this.items,
    nextCursor: clearNextCursor ? null : (nextCursor ?? this.nextCursor),
    isLoadingMore: isLoadingMore ?? this.isLoadingMore,
  );
}

class LabBranchSearchNotifier extends AsyncNotifier<LabBranchSearchState> {
  @override
  Future<LabBranchSearchState> build() async {
    final query = ref.watch(labBranchSearchQueryProvider);
    final position = await ref
        .watch(labBranchLocationServiceProvider)
        .getCurrentPosition();
    var page = await ref
        .watch(labBranchSearchRemoteDatasourceProvider)
        .search(
          query: query,
          latitude: position?.latitude,
          longitude: position?.longitude,
        );

    // A valid but stale/emulator location can be outside the backend's
    // default 15 km radius — fall back to an unscoped search rather than
    // showing an empty state when verified branches do exist.
    if (page.items.isEmpty && position != null) {
      page = await ref
          .watch(labBranchSearchRemoteDatasourceProvider)
          .search(query: query);
    }

    return LabBranchSearchState(
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
          .read(labBranchLocationServiceProvider)
          .getCurrentPosition();
      final page = await ref
          .read(labBranchSearchRemoteDatasourceProvider)
          .search(
            query: ref.read(labBranchSearchQueryProvider),
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
      state = AsyncData(current.copyWith(isLoadingMore: false));
    }
  }
}

final labBranchSearchProvider =
    AsyncNotifierProvider<LabBranchSearchNotifier, LabBranchSearchState>(
      LabBranchSearchNotifier.new,
    );

/// Back-compat view over [labBranchSearchProvider] for callers that only need
/// the flat item list (the map view, the search-query filter below).
final labBranchesProvider = FutureProvider<List<LabBranch>>((ref) async {
  final state = await ref.watch(labBranchSearchProvider.future);
  return state.items;
});

/// Explicitly chosen branch id — null means "not chosen yet, default to the
/// first result".
class SelectedLabBranch extends Notifier<String?> {
  @override
  String? build() => null;

  void select(String branchId) => state = branchId;

  void clear() => state = null;
}

final selectedLabBranchProvider = NotifierProvider<SelectedLabBranch, String?>(
  SelectedLabBranch.new,
);

/// Free-text search query typed into the "ابحث عن مختبر..." box.
class LabBranchSearchQuery extends Notifier<String> {
  @override
  String build() => '';

  void setQuery(String query) => state = query;
}

final labBranchSearchQueryProvider =
    NotifierProvider<LabBranchSearchQuery, String>(LabBranchSearchQuery.new);

/// [labBranchesProvider] narrowed by the search query, sorted by distance
/// (nearest first, unknown-distance results last). The query is sent to the
/// backend by [LabBranchSearchNotifier] and retained here as a defensive
/// local filter for mock/older responses that may ignore it.
final filteredLabBranchesProvider = FutureProvider<List<LabBranch>>((
  ref,
) async {
  final branches = await ref.watch(labBranchesProvider.future);
  final query = ref.watch(labBranchSearchQueryProvider).trim().toLowerCase();

  final result = branches.where((branch) {
    if (query.isEmpty) return true;
    return branch.name.toLowerCase().contains(query) ||
        branch.address.toLowerCase().contains(query);
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

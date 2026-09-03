import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:med_super/core/di/core_providers.dart';
import 'package:med_super/features/provider_registration/presentation/controllers/clinic_location_provider.dart';
import 'package:med_super/features/search_discovery/data/datasources/remote/doctor_search_remote_datasource.dart';
import 'package:med_super/features/search_discovery/data/repositories/doctor_search_repository_impl.dart';
import 'package:med_super/features/search_discovery/domain/entities/doctor_summary.dart';
import 'package:med_super/features/search_discovery/domain/entities/doctor_sort.dart';
import 'package:med_super/features/search_discovery/domain/repositories/doctor_search_repository.dart';
import 'package:med_super/features/search_discovery/domain/usecases/search_doctors_usecase.dart';

part 'search_providers.g.dart';

/// Reuses the geolocator wrapper already built for provider registration
/// (`ClinicLocationService`) — same reuse `pharmacy_search_providers.dart`
/// already makes for the pharmacy branch search. Best-effort: if
/// permission is denied/unavailable, the search still runs without
/// `lat`/`lng` (server sorts by rating instead of distance, and every
/// result's `distanceKm` comes back null — the card hides its distance row
/// in that case rather than showing a fabricated "0.0 km").
final doctorSearchLocationServiceProvider = Provider(
  (ref) => const ClinicLocationService(),
);

@riverpod
DoctorSearchRemoteDatasource doctorSearchRemoteDatasource(Ref ref) =>
    DoctorSearchRemoteDatasource(ref.watch(dioProvider));

@riverpod
DoctorSearchRepository doctorSearchRepository(Ref ref) =>
    DoctorSearchRepositoryImpl(
      remote: ref.watch(doctorSearchRemoteDatasourceProvider),
    );

@riverpod
SearchDoctorsUseCase searchDoctorsUseCase(Ref ref) =>
    SearchDoctorsUseCase(ref.watch(doctorSearchRepositoryProvider));

class DoctorSearchParams {
  const DoctorSearchParams({
    this.query = '',
    this.specialty,
    this.sort = DoctorSort.topRated,
  });

  final String query;
  final String? specialty;
  final DoctorSort sort;

  DoctorSearchParams copyWith({
    String? query,
    String? specialty,
    DoctorSort? sort,
    bool clearSpecialty = false,
  }) => DoctorSearchParams(
    query: query ?? this.query,
    specialty: clearSpecialty ? null : (specialty ?? this.specialty),
    sort: sort ?? this.sort,
  );

  @override
  bool operator ==(Object other) =>
      other is DoctorSearchParams &&
      other.query == query &&
      other.specialty == specialty &&
      other.sort == sort;

  @override
  int get hashCode => Object.hash(query, specialty, sort);
}

@riverpod
class DoctorSearchController extends _$DoctorSearchController {
  @override
  DoctorSearchParams build() => const DoctorSearchParams();

  void setQuery(String query) => state = state.copyWith(query: query);

  void setSpecialty(String? specialty) => state = specialty == null
      ? state.copyWith(clearSpecialty: true)
      : state.copyWith(specialty: specialty);

  void setSort(DoctorSort sort) => state = state.copyWith(sort: sort);
}

/// A "load more" affordance should only ever render when the backend
/// actually said there's another page — never as an always-on control the
/// user has to discover does nothing once the real count is under a page.
/// Mirrors `PharmacySearchState`/`PharmacySearchNotifier`
/// (`pharmacy_search_providers.dart`) — same plain (non-codegen)
/// `AsyncNotifier` pattern, since accumulating pages doesn't fit a single
/// `@riverpod` `FutureProvider`'s one-shot rebuild-on-param-change model.
class DoctorSearchState {
  const DoctorSearchState({
    required this.doctors,
    required this.totalCount,
    required this.nextCursor,
    required this.isLoadingMore,
  });

  final List<DoctorSummary> doctors;
  final int totalCount;
  final String? nextCursor;
  final bool isLoadingMore;

  bool get hasMore => nextCursor != null;

  DoctorSearchState copyWith({
    List<DoctorSummary>? doctors,
    int? totalCount,
    String? nextCursor,
    bool clearNextCursor = false,
    bool? isLoadingMore,
  }) => DoctorSearchState(
    doctors: doctors ?? this.doctors,
    totalCount: totalCount ?? this.totalCount,
    nextCursor: clearNextCursor ? null : (nextCursor ?? this.nextCursor),
    isLoadingMore: isLoadingMore ?? this.isLoadingMore,
  );
}

class DoctorSearchResultsNotifier extends AsyncNotifier<DoctorSearchState> {
  @override
  Future<DoctorSearchState> build() async {
    final params = ref.watch(doctorSearchControllerProvider);
    final position = await ref
        .watch(doctorSearchLocationServiceProvider)
        .getCurrentPosition();
    final result = await ref
        .watch(searchDoctorsUseCaseProvider)
        .call(
          query: params.query,
          specialty: params.specialty,
          sort: params.sort,
          latitude: position?.latitude,
          longitude: position?.longitude,
        );
    final page = result.when(
      ok: (value) => value,
      err: (failure) => throw failure,
    );
    return DoctorSearchState(
      doctors: page.doctors,
      totalCount: page.totalCount,
      nextCursor: page.nextCursor,
      isLoadingMore: false,
    );
  }

  Future<void> loadMore() async {
    final current = state.value;
    if (current == null || !current.hasMore || current.isLoadingMore) return;

    state = AsyncData(current.copyWith(isLoadingMore: true));
    try {
      final params = ref.read(doctorSearchControllerProvider);
      final position = await ref
          .read(doctorSearchLocationServiceProvider)
          .getCurrentPosition();
      final result = await ref
          .read(searchDoctorsUseCaseProvider)
          .call(
            query: params.query,
            specialty: params.specialty,
            sort: params.sort,
            latitude: position?.latitude,
            longitude: position?.longitude,
            cursor: current.nextCursor,
          );
      final page = result.when(
        ok: (value) => value,
        err: (failure) => throw failure,
      );
      state = AsyncData(
        current.copyWith(
          doctors: [...current.doctors, ...page.doctors],
          nextCursor: page.nextCursor,
          clearNextCursor: page.nextCursor == null,
          isLoadingMore: false,
        ),
      );
    } catch (_) {
      // A failed "load more" keeps the existing page visible — only the
      // spinner clears, matching PharmacySearchNotifier's behavior.
      state = AsyncData(current.copyWith(isLoadingMore: false));
    }
  }
}

final doctorSearchResultsProvider =
    AsyncNotifierProvider<DoctorSearchResultsNotifier, DoctorSearchState>(
      DoctorSearchResultsNotifier.new,
    );

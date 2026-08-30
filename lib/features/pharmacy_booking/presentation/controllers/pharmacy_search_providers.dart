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

/// All candidate pharmacy branches for the current prescription —
/// `GET /v1/pharmacy-branches/search` (`clinic-reservations` File 12 Part
/// 37). Best-effort device location: if permission is denied/unavailable,
/// the search still runs without `lat`/`lng` (server sorts by name instead
/// of distance, and every result's `distanceKm` comes back null — the card
/// hides its distance row in that case rather than showing a fabricated
/// number).
final pharmaciesProvider = FutureProvider<List<Pharmacy>>((ref) async {
  final position = await ref
      .watch(pharmacyLocationServiceProvider)
      .getCurrentPosition();
  return ref
      .watch(pharmacyBranchSearchRemoteDatasourceProvider)
      .search(latitude: position?.latitude, longitude: position?.longitude);
});

/// Explicitly chosen branch id — null means "not chosen yet, default to the
/// first result", matching the Figma state where the top card is
/// pre-selected without any tap.
class SelectedPharmacy extends Notifier<String?> {
  @override
  String? build() => null;

  void select(String branchId) => state = branchId;
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
/// (nearest first, unknown-distance results last) — client-side, since the
/// query box re-filters the same already-fetched page rather than re-hitting
/// the network per keystroke.
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

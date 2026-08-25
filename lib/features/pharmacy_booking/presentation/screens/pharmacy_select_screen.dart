import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:med_super/core/theme/app_colors.dart';
import 'package:med_super/core/theme/app_radii.dart';
import 'package:med_super/core/widgets/app_button.dart';
import 'package:med_super/core/widgets/async_value_view.dart';
import 'package:med_super/core/widgets/step_progress_header.dart';
import 'package:med_super/features/pharmacy_booking/presentation/controllers/pharmacy_search_providers.dart';
import 'package:med_super/features/pharmacy_booking/presentation/widgets/pharmacy_card.dart';
import 'package:med_super/features/pharmacy_booking/presentation/widgets/pharmacy_filter_chip_bar.dart';
import 'package:med_super/features/pharmacy_booking/presentation/widgets/pharmacy_map_view.dart';
import 'package:med_super/features/pharmacy_booking/presentation/widgets/pharmacy_search_skeleton.dart';

/// Step 2 of the pharmacy booking flow — choose a pharmacy to fulfil the
/// prescription uploaded in step 1. Selecting a card only marks it as the
/// current choice (the patient may change their mind); a bottom "التالي"
/// bar is the only thing that actually advances to step 3.
class PharmacySelectScreen extends ConsumerStatefulWidget {
  const PharmacySelectScreen({this.mapTileProvider, super.key});

  /// Test-only override passed straight through to [PharmacyMapView] — see
  /// its own doc comment for why `flutter test` should never be left to hit
  /// the real OSM tile servers.
  final TileProvider? mapTileProvider;

  @override
  ConsumerState<PharmacySelectScreen> createState() =>
      _PharmacySelectScreenState();
}

class _PharmacySelectScreenState extends ConsumerState<PharmacySelectScreen> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    // Initialized eagerly here (not via a lazy `late final` initializer read
    // from `build()`) so the field is always safely populated before
    // `dispose()` could ever run — a lazy initializer that first runs inside
    // `dispose()` would touch `ref` after the widget is unmounted, which
    // throws.
    _searchController = TextEditingController(
      text: ref.read(pharmacySearchQueryProvider),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _select(String pharmacyId) {
    ref.read(selectedPharmacyProvider.notifier).select(pharmacyId);
  }

  void _next() {
    context.push('/patient/pharmacy/review');
  }

  /// Opens the pharmacy's full profile (the same real screen wired to
  /// `GET /v1/pharmacies/:id`) with a "select and continue" action baked in
  /// via the route's `extra` — so choosing can happen either straight from
  /// this compact card (`_select` above, unchanged) or after reading the
  /// full profile first.
  void _viewDetails(String pharmacyId) {
    context.push(
      '/patient/pharmacies/$pharmacyId',
      extra: () {
        _select(pharmacyId);
        _next();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final pharmaciesAsync = ref.watch(filteredPharmaciesProvider);
    final openNowOnly = ref.watch(pharmacyOpenNowOnlyFilterProvider);
    final selectedSort = ref.watch(pharmacySortProvider);
    final explicitSelectedId = ref.watch(selectedPharmacyProvider);
    // The search bar, filter chips and map render immediately regardless of
    // loading state — only the card list below waits on the async result
    // (and shows the skeleton while it does), so the map is fed whatever is
    // already resolved (empty before the first load completes).
    final loadedPharmacies = pharmaciesAsync.value ?? const [];
    final selectedId =
        explicitSelectedId ??
        (loadedPharmacies.isEmpty ? null : loadedPharmacies.first.id);
    // A pharmacy is "chosen" either explicitly (a card was tapped) or
    // implicitly (the first result is pre-selected once the list loads,
    // matching the mockup's pre-selected top card) — the "التالي" bar must
    // treat both the same way.
    final hasSelection = selectedId != null;

    return Scaffold(
      backgroundColor: AppColors.surfaceApp,
      body: SafeArea(
        child: Column(
          children: [
            const _Header(),
            StepProgressHeader(
              // Same step labels/order as step 1's stepper — must read
              // identically across every screen of this flow.
              stepLabels: [
                'pharmacy_booking.step_upload'.tr(),
                'pharmacy_booking.step_pharmacy'.tr(),
                'pharmacy_booking.step_delivery'.tr(),
              ],
              currentStep: 1,
              accentColor: AppColors.patientPrimary,
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                children: [
                  TextField(
                    controller: _searchController,
                    textAlign: TextAlign.right,
                    onChanged: (value) => ref
                        .read(pharmacySearchQueryProvider.notifier)
                        .setQuery(value),
                    decoration: InputDecoration(
                      hintText: 'pharmacy_booking.select_pharmacy.search_hint'
                          .tr(),
                      suffixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(
                          color: AppColors.borderLight,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  PharmacyFilterChipBar(
                    openNowOnly: openNowOnly,
                    onToggleOpenNow: () => ref
                        .read(pharmacyOpenNowOnlyFilterProvider.notifier)
                        .toggle(),
                    selectedSort: selectedSort,
                    onSelectSort: (sort) =>
                        ref.read(pharmacySortProvider.notifier).select(sort),
                  ),
                  const SizedBox(height: 16),
                  PharmacyMapView(
                    pharmacies: loadedPharmacies,
                    selectedId: selectedId,
                    onSelect: (id) =>
                        ref.read(selectedPharmacyProvider.notifier).select(id),
                    tileProvider: widget.mapTileProvider,
                  ),
                  const SizedBox(height: 16),
                  AsyncValueView(
                    value: pharmaciesAsync,
                    onRetry: () => ref.invalidate(pharmaciesProvider),
                    loadingWidget: const PharmacySearchSkeleton(),
                    data: (pharmacies) => Column(
                      children: pharmacies
                          .map(
                            (pharmacy) => Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: PharmacyCard(
                                pharmacy: pharmacy,
                                isSelected: pharmacy.id == selectedId,
                                onSelect: () => _select(pharmacy.id),
                                onViewDetails: () => _viewDetails(pharmacy.id),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                ],
              ),
            ),
            _NextBar(enabled: hasSelection, onNext: _next),
          ],
        ),
      ),
    );
  }
}

/// Fixed bottom bar with the "التالي" CTA — advancing to step 3 is a
/// deliberate, separate action from picking a card, so the patient can
/// freely change their mind between pharmacies before committing.
class _NextBar extends StatelessWidget {
  const _NextBar({required this.enabled, required this.onNext});

  final bool enabled;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.borderLight)),
      ),
      child: AppButton.filled(
        label: 'pharmacy_booking.select_pharmacy.next_cta'.tr(),
        fullWidth: true,
        backgroundColor: AppColors.patientPrimary,
        foregroundColor: Colors.white,
        borderRadius: AppRadii.xl,
        onPressed: enabled ? onNext : null,
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          IconButton(onPressed: () {}, icon: const Icon(Icons.search)),
          Expanded(
            child: Text(
              'pharmacy_booking.select_pharmacy.title'.tr(),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.patientPrimary,
              ),
            ),
          ),
          IconButton(
            onPressed: () => context.pop(),
            icon: const Icon(Icons.arrow_forward),
          ),
        ],
      ),
    );
  }
}

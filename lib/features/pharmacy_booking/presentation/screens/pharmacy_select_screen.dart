import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:med_super/core/theme/app_colors.dart';
import 'package:med_super/core/widgets/async_value_view.dart';
import 'package:med_super/features/pharmacy_booking/presentation/controllers/pharmacy_search_providers.dart';
import 'package:med_super/features/pharmacy_booking/presentation/widgets/pharmacy_card.dart';
import 'package:med_super/features/pharmacy_booking/presentation/widgets/pharmacy_filter_chip_bar.dart';
import 'package:med_super/features/pharmacy_booking/presentation/widgets/pharmacy_map_view.dart';
import 'package:med_super/features/pharmacy_booking/presentation/widgets/pharmacy_search_skeleton.dart';

/// Step 2 of the pharmacy booking flow — choose a pharmacy to fulfil the
/// prescription uploaded in step 1. No stepper on this screen (unlike steps
/// 1 and 3 of this flow), matching the mockup.
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

  void _choose(String pharmacyId) {
    ref.read(selectedPharmacyProvider.notifier).select(pharmacyId);
    context.push('/patient/pharmacy/review');
  }

  @override
  Widget build(BuildContext context) {
    final pharmaciesAsync = ref.watch(filteredPharmaciesProvider);
    final openNowOnly = ref.watch(pharmacyOpenNowOnlyFilterProvider);
    final selectedSort = ref.watch(pharmacySortProvider);
    final explicitSelectedId = ref.watch(selectedPharmacyProvider);

    return Scaffold(
      backgroundColor: AppColors.surfaceApp,
      body: SafeArea(
        child: Column(
          children: [
            const _Header(),
            Expanded(
              child: AsyncValueView(
                value: pharmaciesAsync,
                onRetry: () => ref.invalidate(pharmaciesProvider),
                loadingWidget: const Padding(
                  padding: EdgeInsets.fromLTRB(16, 8, 16, 24),
                  child: PharmacySearchSkeleton(),
                ),
                data: (pharmacies) {
                  final selectedId =
                      explicitSelectedId ??
                      (pharmacies.isEmpty ? null : pharmacies.first.id);
                  return ListView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    children: [
                      TextField(
                        controller: _searchController,
                        textAlign: TextAlign.right,
                        onChanged: (value) => ref
                            .read(pharmacySearchQueryProvider.notifier)
                            .setQuery(value),
                        decoration: InputDecoration(
                          hintText:
                              'pharmacy_booking.select_pharmacy.search_hint'
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
                        onSelectSort: (sort) => ref
                            .read(pharmacySortProvider.notifier)
                            .select(sort),
                      ),
                      const SizedBox(height: 16),
                      PharmacyMapView(
                        pharmacies: pharmacies,
                        selectedId: selectedId,
                        onSelect: (id) => ref
                            .read(selectedPharmacyProvider.notifier)
                            .select(id),
                        tileProvider: widget.mapTileProvider,
                      ),
                      const SizedBox(height: 16),
                      ...pharmacies.map(
                        (pharmacy) => Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: PharmacyCard(
                            pharmacy: pharmacy,
                            isSelected: pharmacy.id == selectedId,
                            onSelect: () => _choose(pharmacy.id),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
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

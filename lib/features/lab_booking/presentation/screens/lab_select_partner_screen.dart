import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:med_super/core/theme/app_colors.dart';
import 'package:med_super/core/widgets/async_value_view.dart';
import 'package:med_super/core/widgets/step_progress_header.dart';
import 'package:med_super/features/lab_booking/presentation/controllers/lab_partner_providers.dart';
import 'package:med_super/features/lab_booking/presentation/widgets/lab_confirm_bottom_bar.dart';
import 'package:med_super/features/lab_booking/presentation/widgets/lab_partner_card.dart';
import 'package:med_super/features/lab_booking/presentation/widgets/lab_partners_map_view.dart';
import 'package:med_super/features/lab_booking/presentation/widgets/lab_sort_chip_bar.dart';

/// Step 2 of the lab booking flow — choose an accredited lab to fulfil the
/// tests picked in step 1. Figma node 14:1099 ("اختيار المختبر").
class LabSelectPartnerScreen extends ConsumerStatefulWidget {
  const LabSelectPartnerScreen({this.mapTileProvider, super.key});

  /// Test-only override passed straight through to [LabPartnersMapView] —
  /// see its own doc comment for why `flutter test` should never be left to
  /// hit the real OSM tile servers.
  final TileProvider? mapTileProvider;

  @override
  ConsumerState<LabSelectPartnerScreen> createState() =>
      _LabSelectPartnerScreenState();
}

class _LabSelectPartnerScreenState
    extends ConsumerState<LabSelectPartnerScreen> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    // Initialized eagerly here (not via a lazy `late final` initializer
    // read from `build()`) so the field is always safely populated before
    // `dispose()` could ever run — a lazy initializer that first runs
    // inside `dispose()` would touch `ref` after the widget is unmounted,
    // which throws.
    _searchController = TextEditingController(
      text: ref.read(labSearchQueryProvider),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _continue(String labId) {
    ref.read(selectedLabPartnerProvider.notifier).select(labId);
    context.push('/patient/lab/review');
  }

  @override
  Widget build(BuildContext context) {
    final partnersAsync = ref.watch(filteredLabPartnersProvider);
    final selectedSort = ref.watch(labSortControllerProvider);
    final openNowOnly = ref.watch(labOpenNowOnlyFilterProvider);
    final explicitSelectedId = ref.watch(selectedLabPartnerProvider);

    return Scaffold(
      backgroundColor: AppColors.surfaceApp,
      body: SafeArea(
        child: Column(
          children: [
            _Header(),
            StepProgressHeader(
              // Same step labels/order as the other two steps of this flow
              // — the stepper must read identically across all three
              // screens, not per-screen wording.
              stepLabels: [
                'lab_booking.step_upload'.tr(),
                'lab_booking.step_select_lab'.tr(),
                'lab_booking.step_review'.tr(),
              ],
              currentStep: 1,
              accentColor: AppColors.patientPrimary,
            ),
            Expanded(
              child: AsyncValueView(
                value: partnersAsync,
                onRetry: () => ref.invalidate(labPartnersProvider),
                data: (partners) {
                  final selectedId =
                      explicitSelectedId ??
                      (partners.isEmpty ? null : partners.first.id);
                  return ListView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    children: [
                      Row(
                        children: [
                          IconButton(
                            onPressed: () => ref
                                .read(labOpenNowOnlyFilterProvider.notifier)
                                .toggle(),
                            icon: Icon(
                              Icons.tune,
                              color: openNowOnly
                                  ? AppColors.patientPrimary
                                  : AppColors.ink700,
                            ),
                          ),
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              textAlign: TextAlign.right,
                              onChanged: (value) => ref
                                  .read(labSearchQueryProvider.notifier)
                                  .setQuery(value),
                              decoration: InputDecoration(
                                hintText: 'lab_booking.select_lab.search_hint'
                                    .tr(),
                                suffixIcon: const Icon(Icons.search),
                                filled: true,
                                fillColor: Colors.white,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(20),
                                  borderSide: const BorderSide(
                                    color: AppColors.borderLight,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      LabPartnersMapView(
                        partners: partners,
                        selectedId: selectedId,
                        onSelect: (id) => ref
                            .read(selectedLabPartnerProvider.notifier)
                            .select(id),
                        tileProvider: widget.mapTileProvider,
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(17),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: AppColors.borderSubtle),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: LabSortChipBar(
                          selected: selectedSort,
                          onSelected: (sort) => ref
                              .read(labSortControllerProvider.notifier)
                              .select(sort),
                          openNowOnly: openNowOnly,
                          onToggleOpenNow: () => ref
                              .read(labOpenNowOnlyFilterProvider.notifier)
                              .toggle(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Align(
                        alignment: AlignmentDirectional.centerEnd,
                        child: Text(
                          'lab_booking.select_lab.available_labs_count'.tr(
                            args: ['${partners.length}'],
                          ),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.ink700,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...partners.map(
                        (partner) => Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: LabPartnerCard(
                            partner: partner,
                            isSelected: partner.id == selectedId,
                            onSelect: () => ref
                                .read(selectedLabPartnerProvider.notifier)
                                .select(partner.id),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            LabConfirmBottomBar(
              isSubmitting: false,
              onContinue: () {
                final partners = partnersAsync.value ?? const [];
                final labId =
                    explicitSelectedId ??
                    (partners.isEmpty ? null : partners.first.id);
                if (labId != null) _continue(labId);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // Balances the trailing back button's width so the title stays
          // visually centered now that nothing occupies the leading slot.
          const SizedBox(width: 48),
          Expanded(
            child: Text(
              'lab_booking.step_select_lab'.tr(),
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

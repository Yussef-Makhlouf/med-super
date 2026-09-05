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
import 'package:med_super/features/lab_booking/domain/entities/lab_branch.dart';
import 'package:med_super/features/lab_booking/domain/entities/lab_service_type.dart';
import 'package:med_super/features/lab_booking/presentation/controllers/lab_branch_search_providers.dart';
import 'package:med_super/features/lab_booking/presentation/controllers/lab_upload_providers.dart';
import 'package:med_super/features/lab_booking/presentation/widgets/lab_branch_card.dart';
import 'package:med_super/features/lab_booking/presentation/widgets/lab_branches_map_view.dart';

/// Step 2 of the lab booking flow — choose an accredited lab branch to
/// fulfil the request uploaded in step 1. Rebuilt 2026-09-05 against the
/// real `GET /v1/lab-branches/search` (previously a mock `GET
/// /v1/lab-partners` invented endpoint) — mirrors `pharmacy_booking`'s
/// `PharmacySelectScreen` structure closely.
class LabSelectPartnerScreen extends ConsumerStatefulWidget {
  const LabSelectPartnerScreen({this.mapTileProvider, super.key});

  /// Test-only override passed straight through to [LabBranchesMapView].
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
    _searchController = TextEditingController(
      text: ref.read(labBranchSearchQueryProvider),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _select(String branchId) {
    ref.read(selectedLabBranchProvider.notifier).select(branchId);
  }

  void _continue() {
    context.push('/patient/lab/review');
  }

  @override
  Widget build(BuildContext context) {
    final branchesAsync = ref.watch(filteredLabBranchesProvider);
    final searchState = ref.watch(labBranchSearchProvider).value;
    final explicitSelectedId = ref.watch(selectedLabBranchProvider);
    final loadedBranches = branchesAsync.value ?? const [];
    // Home-collection only ever fulfils through a `homeCollectionCapable`
    // branch — chosen back on step 1 (`selectedLabServiceTypeProvider`),
    // still in force here since nothing resets it between steps.
    final requiresHomeCollection =
        ref.watch(selectedLabServiceTypeProvider) ==
        LabServiceType.homeCollection;
    bool isSelectable(LabBranch b) =>
        !requiresHomeCollection || b.homeCollectionCapable;

    final selectableIds = loadedBranches
        .where(isSelectable)
        .map((b) => b.id)
        .toSet();
    final selectedId =
        (explicitSelectedId != null && selectableIds.contains(explicitSelectedId))
        ? explicitSelectedId
        : null;
    final hasSelection = selectedId != null;

    return Scaffold(
      backgroundColor: AppColors.surfaceApp,
      body: SafeArea(
        child: Column(
          children: [
            const _Header(),
            StepProgressHeader(
              // Same step labels/order as the other two steps of this flow
              // — the stepper must read identically across all three
              // screens.
              stepLabels: [
                'lab_booking.step_upload'.tr(),
                'lab_booking.step_select_lab'.tr(),
                'lab_booking.step_review'.tr(),
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
                        .read(labBranchSearchQueryProvider.notifier)
                        .setQuery(value),
                    decoration: InputDecoration(
                      hintText: 'lab_booking.select_lab.search_hint'.tr(),
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
                  const SizedBox(height: 16),
                  LabBranchesMapView(
                    branches: loadedBranches,
                    selectedId: selectedId,
                    onSelect: (id) =>
                        ref.read(selectedLabBranchProvider.notifier).select(id),
                    tileProvider: widget.mapTileProvider,
                  ),
                  const SizedBox(height: 16),
                  AsyncValueView(
                    value: branchesAsync,
                    onRetry: () => ref.invalidate(labBranchSearchProvider),
                    data: (branches) => Column(
                      children: branches
                          .map(
                            (branch) => Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: LabBranchCard(
                                branch: branch,
                                isSelected: branch.id == selectedId,
                                onSelect: () => _select(branch.id),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                  // Only rendered when the backend's own `nextCursor` says
                  // there's actually another page.
                  if (searchState?.hasMore ?? false)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Center(
                        child: TextButton(
                          onPressed: searchState!.isLoadingMore
                              ? null
                              : () => ref
                                    .read(labBranchSearchProvider.notifier)
                                    .loadMore(),
                          child: searchState.isLoadingMore
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(
                                  'lab_booking.select_lab.load_more'.tr(),
                                ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: AppColors.borderLight)),
              ),
              child: AppButton.filled(
                label: 'lab_booking.select_lab.continue_cta'.tr(),
                fullWidth: true,
                backgroundColor: AppColors.patientPrimary,
                foregroundColor: Colors.white,
                borderRadius: AppRadii.xl,
                onPressed: hasSelection ? _continue : null,
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

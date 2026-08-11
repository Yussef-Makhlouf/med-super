import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:med_super/core/theme/app_colors.dart';
import 'package:med_super/core/widgets/async_value_view.dart';
import 'package:med_super/core/widgets/step_progress_header.dart';
import 'package:med_super/features/lab_booking/presentation/controllers/lab_booking_providers.dart';
import 'package:med_super/features/lab_booking/presentation/controllers/lab_partner_providers.dart';
import 'package:med_super/features/lab_booking/presentation/widgets/category_chip_bar.dart';
import 'package:med_super/features/lab_booking/presentation/widgets/lab_booking_bottom_bar.dart';
import 'package:med_super/features/lab_booking/presentation/widgets/selectable_test_card.dart';
import 'package:med_super/features/lab_booking/presentation/widgets/suggested_lab_card.dart';

class LabTestSelectionScreen extends ConsumerStatefulWidget {
  const LabTestSelectionScreen({super.key});

  @override
  ConsumerState<LabTestSelectionScreen> createState() =>
      _LabTestSelectionScreenState();
}

class _LabTestSelectionScreenState
    extends ConsumerState<LabTestSelectionScreen> {
  late final _searchController = TextEditingController(
    text: ref.read(labSearchQueryProvider),
  );
  bool _addingLabId = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _addSuggestedLab(String labId) async {
    final testIds = ref.read(selectedLabTestsProvider);
    if (testIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('lab_booking.select_tests_first'.tr())),
      );
      return;
    }
    setState(() => _addingLabId = true);
    final result = await ref
        .read(confirmLabBookingUseCaseProvider)
        .call(labId: labId, testIds: testIds.toList());
    if (!mounted) return;
    setState(() => _addingLabId = false);
    result.when(
      ok: (confirmation) =>
          context.push('/patient/lab/confirmation', extra: confirmation),
      err: (failure) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('lab_booking.select_lab.confirm_error'.tr())),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final catalogAsync = ref.watch(labCatalogProvider);
    final selectedIds = ref.watch(selectedLabTestsProvider);
    final activeCategory = ref.watch(activeLabCategoryProvider);
    final totalAsync = ref.watch(selectedLabTestsTotalProvider);

    return Scaffold(
      backgroundColor: AppColors.surfaceApp,
      body: SafeArea(
        child: Column(
          children: [
            _Header(),
            Expanded(
              child: AsyncValueView(
                value: catalogAsync,
                onRetry: () => ref.invalidate(labCatalogProvider),
                data: (catalog) => ListView(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
                  children: [
                    TextField(
                      controller: _searchController,
                      textAlign: TextAlign.right,
                      onChanged: (value) => ref
                          .read(labSearchQueryProvider.notifier)
                          .setQuery(value),
                      decoration: InputDecoration(
                        hintText: 'lab_booking.search_hint'.tr(),
                        prefixIcon: const Icon(Icons.search),
                        filled: true,
                        fillColor: AppColors.surfaceApp,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: const BorderSide(
                            color: AppColors.borderLight,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    CategoryChipBar(
                      categories: catalog.categories,
                      activeId: activeCategory,
                      onSelected: (id) => ref
                          .read(activeLabCategoryProvider.notifier)
                          .select(id),
                    ),
                    const SizedBox(height: 48),
                    Align(
                      alignment: AlignmentDirectional.centerEnd,
                      child: Text(
                        'lab_booking.available_tests'.tr(),
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                          color: AppColors.ink900,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ...catalog.tests.map(
                      (test) => Padding(
                        padding: const EdgeInsets.only(bottom: 24),
                        child: SelectableTestCard(
                          test: test,
                          isSelected: selectedIds.contains(test.id),
                          onToggle: () => ref
                              .read(selectedLabTestsProvider.notifier)
                              .toggle(test.id),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton(
                          onPressed: () =>
                              context.push('/patient/lab/select-lab'),
                          child: Text('common.view_all'.tr()),
                        ),
                        Text(
                          'lab_booking.suggested_labs'.tr(),
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w600,
                            color: AppColors.ink900,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ...catalog.suggestedLabs.map(
                      (lab) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: SuggestedLabCard(
                          lab: lab,
                          onAdd: _addingLabId
                              ? null
                              : () => _addSuggestedLab(lab.id),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            LabBookingBottomBar(
              selectedCount: selectedIds.length,
              totalPrice: totalAsync.value ?? 0,
              // TODO(sprint-lab-2): should go to lab selection then to a
              // schedule/payment screen, but no Figma design for that
              // schedule/payment screen has been found yet.
              onContinue: selectedIds.isEmpty
                  ? null
                  : () => context.push('/patient/lab/select-lab'),
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
      color: AppColors.surfaceApp,
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                IconButton(
                  onPressed: () => context.pop(),
                  icon: const Icon(Icons.arrow_back),
                ),
                Expanded(
                  child: Text(
                    'lab_booking.title'.tr(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: AppColors.ink900,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.help_outline, size: 16),
                ),
              ],
            ),
          ),
          StepProgressHeader(
            stepLabels: [
              'lab_booking.step_select_tests'.tr(),
              'lab_booking.step_select_lab'.tr(),
              'lab_booking.step_schedule_payment'.tr(),
            ],
            currentStep: 0,
            accentColor: AppColors.patientPrimary,
          ),
        ],
      ),
    );
  }
}

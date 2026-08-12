import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:med_super/core/theme/app_colors.dart';
import 'package:med_super/core/widgets/async_value_view.dart';
import 'package:med_super/core/widgets/step_progress_header.dart';
import 'package:med_super/features/lab_booking/presentation/controllers/lab_booking_providers.dart';
import 'package:med_super/features/lab_booking/presentation/controllers/lab_partner_providers.dart';
import 'package:med_super/features/lab_booking/presentation/widgets/lab_confirm_bottom_bar.dart';
import 'package:med_super/features/lab_booking/presentation/widgets/lab_partner_card.dart';
import 'package:med_super/features/lab_booking/presentation/widgets/lab_partners_map_view.dart';
import 'package:med_super/features/lab_booking/presentation/widgets/lab_sort_chip_bar.dart';

/// Step 2 of the lab booking flow — choose an accredited lab to fulfil the
/// tests picked in step 1. Figma node 14:1099 ("اختيار المختبر").
class LabSelectPartnerScreen extends ConsumerStatefulWidget {
  const LabSelectPartnerScreen({super.key});

  @override
  ConsumerState<LabSelectPartnerScreen> createState() =>
      _LabSelectPartnerScreenState();
}

class _LabSelectPartnerScreenState
    extends ConsumerState<LabSelectPartnerScreen> {
  void _continue(String labId) {
    ref.read(selectedLabPartnerProvider.notifier).select(labId);
    context.push('/patient/lab/schedule-payment');
  }

  @override
  Widget build(BuildContext context) {
    final partnersAsync = ref.watch(labPartnersProvider);
    final selectedSort = ref.watch(labSortControllerProvider);
    final explicitSelectedId = ref.watch(selectedLabPartnerProvider);
    final totalAsync = ref.watch(selectedLabTestsTotalProvider);

    return Scaffold(
      backgroundColor: AppColors.surfaceApp,
      body: SafeArea(
        child: Column(
          children: [
            _Header(),
            StepProgressHeader(
              stepLabels: [
                'lab_booking.select_lab.stepper_tests'.tr(),
                'lab_booking.select_lab.stepper_lab'.tr(),
                'lab_booking.select_lab.stepper_confirm'.tr(),
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
                      LabPartnersMapView(
                        partners: partners,
                        selectedId: selectedId,
                        onSelect: (id) => ref
                            .read(selectedLabPartnerProvider.notifier)
                            .select(id),
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
                        ),
                      ),
                      const SizedBox(height: 16),
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
              totalPrice: totalAsync.value ?? 0,
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
              'lab_booking.select_lab.title'.tr(),
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

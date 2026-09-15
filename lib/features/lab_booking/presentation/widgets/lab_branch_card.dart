import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:med_super/core/theme/app_colors.dart';
import 'package:med_super/core/theme/app_radii.dart';
import 'package:med_super/core/theme/app_shadows.dart';
import 'package:med_super/core/widgets/app_button.dart';
import 'package:med_super/core/widgets/app_icon_tile.dart';
import 'package:med_super/features/lab_booking/domain/entities/lab_branch.dart';
import 'package:solar_icons/solar_icons.dart';

/// A single lab branch card in the step-2 selection list: logo + name/
/// address, a distance row (hidden when the device's location isn't known),
/// then a trailing "اختر" CTA — filled for the currently-selected branch,
/// outlined for the rest. Mirrors `pharmacy_booking`'s `PharmacyCard`.
///
/// Rating, starting price and live open/closed status are not shown here —
/// no ratings table, no lab price catalog, and no operating-hours model
/// exist on the real `lab_branches`/`laboratories` tables to back them (same
/// reasoning `PharmacyCard` already applied 2026-08-29 when it dropped the
/// same class of fabricated fields).
class LabBranchCard extends StatelessWidget {
  const LabBranchCard({
    required this.branch,
    required this.isSelected,
    required this.onSelect,
    super.key,
  });

  final LabBranch branch;
  final bool isSelected;
  final VoidCallback onSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(
          color: isSelected ? AppColors.patientPrimary : Colors.transparent,
          width: 2,
        ),
        boxShadow: isSelected ? AppShadows.raised : AppShadows.resting,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AppIconTile(
                icon: SolarIconsOutline.testTube,
                color: AppColors.patientPrimary,
                size: 56,
                iconSize: 26,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      branch.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      branch.address,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.mutedText2,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (branch.distanceKm != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(
                  SolarIconsOutline.routing,
                  size: 14,
                  color: AppColors.mutedText2,
                ),
                const SizedBox(width: 4),
                Text(
                  'lab_booking.select_lab.distance_km'.tr(
                    args: [branch.distanceKm!.toStringAsFixed(1)],
                  ),
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.mutedText2,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 14),
          const Divider(height: 1, color: AppColors.borderLight),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              branch.homeCollectionCapable
                  ? const _HomeCollectionBadge()
                  : const SizedBox.shrink(),
              _CtaButton(isSelected: isSelected, onSelect: onSelect),
            ],
          ),
        ],
      ),
    );
  }
}

/// `lab_branches.home_collection_capable` — real backend data. Hidden
/// entirely for a branch that doesn't offer it, rather than a negative
/// badge — a branch-visit-only booking doesn't care either way.
class _HomeCollectionBadge extends StatelessWidget {
  const _HomeCollectionBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.tealBg,
        borderRadius: BorderRadius.circular(AppRadii.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            SolarIconsOutline.home,
            size: 16,
            color: AppColors.tealAccent,
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              'lab_booking.select_lab.home_collection_available'.tr(),
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.tealAccent,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CtaButton extends StatelessWidget {
  const _CtaButton({required this.isSelected, required this.onSelect});

  final bool isSelected;
  final VoidCallback onSelect;

  @override
  Widget build(BuildContext context) {
    final label = 'lab_booking.select_lab.choose_cta'.tr();

    final button = isSelected
        ? AppButton.filled(
            label: label,
            onPressed: onSelect,
            backgroundColor: AppColors.patientPrimary,
            foregroundColor: Colors.white,
            borderRadius: AppRadii.pill,
          )
        : AppButton.outlined(
            label: label,
            onPressed: onSelect,
            foregroundColor: AppColors.patientPrimary,
            borderRadius: AppRadii.pill,
          );

    return SizedBox(height: 44, child: button);
  }
}

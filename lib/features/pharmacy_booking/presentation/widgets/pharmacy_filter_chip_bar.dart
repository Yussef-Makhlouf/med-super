import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:med_super/core/theme/app_colors.dart';
import 'package:med_super/features/pharmacy_booking/domain/entities/pharmacy_sort_option.dart';

/// The 3-chip filter/sort row on the select-pharmacy screen: "مفتوح الآن"
/// (a filter toggle) plus "الأعلى تقييماً"/"الأقرب إليك" (mutually exclusive
/// sort options). "الأقرب إليك" is selected by default per the mockup and
/// renders with a distinct teal accent rather than the other chips' plain
/// blue active state.
class PharmacyFilterChipBar extends StatelessWidget {
  const PharmacyFilterChipBar({
    required this.openNowOnly,
    required this.onToggleOpenNow,
    required this.selectedSort,
    required this.onSelectSort,
    super.key,
  });

  final bool openNowOnly;
  final VoidCallback onToggleOpenNow;
  final PharmacySortOption selectedSort;
  final ValueChanged<PharmacySortOption> onSelectSort;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _chip(
          label: 'pharmacy_booking.select_pharmacy.filter_open_now'.tr(),
          icon: Icons.access_time,
          selected: openNowOnly,
          onSelected: (_) => onToggleOpenNow(),
        ),
        _chip(
          label: 'pharmacy_booking.select_pharmacy.filter_top_rated'.tr(),
          icon: Icons.star_border,
          selected: selectedSort == PharmacySortOption.topRated,
          onSelected: (_) => onSelectSort(PharmacySortOption.topRated),
        ),
        _chip(
          label: 'pharmacy_booking.select_pharmacy.filter_nearest'.tr(),
          icon: Icons.near_me_outlined,
          selected: selectedSort == PharmacySortOption.nearest,
          onSelected: (_) => onSelectSort(PharmacySortOption.nearest),
          useTealWhenSelected: true,
        ),
      ],
    );
  }

  Widget _chip({
    required String label,
    required IconData icon,
    required bool selected,
    required ValueChanged<bool> onSelected,
    bool useTealWhenSelected = false,
  }) {
    final activeColor = useTealWhenSelected
        ? AppColors.tealAccent
        : AppColors.patientPrimary;
    final activeBg = useTealWhenSelected
        ? AppColors.tealBg
        : AppColors.patientPrimary.withValues(alpha: 0.1);

    return ChoiceChip(
      // The selected state swaps the icon itself for a checkmark rather
      // than overlaying one on top of it — ChoiceChip's default checkmark
      // stacks on top of `avatar` instead of replacing it, so it must be
      // turned off here.
      avatar: Icon(
        selected ? Icons.check : icon,
        size: 16,
        color: selected ? activeColor : AppColors.mutedText2,
      ),
      showCheckmark: false,
      label: Text(label),
      selected: selected,
      onSelected: onSelected,
      backgroundColor: Colors.white,
      selectedColor: activeBg,
      side: BorderSide(color: selected ? activeColor : AppColors.borderMedium),
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: selected ? activeColor : AppColors.mutedText2,
      ),
      shape: const StadiumBorder(),
    );
  }
}

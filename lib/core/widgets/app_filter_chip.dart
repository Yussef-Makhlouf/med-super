import 'package:flutter/material.dart';
import 'package:med_super/core/theme/app_palette.dart';
import 'package:med_super/core/theme/app_radii.dart';

/// One themed selectable chip (design system v2) — replaces two
/// near-identical `ChoiceChip` builders (`doctor_search_screen.dart`'s
/// specialty and sort-order rows) that each hand-rolled the same
/// selected/unselected color and border logic.
class AppFilterChip extends StatelessWidget {
  const AppFilterChip({
    required this.label,
    required this.selected,
    required this.onSelected,
    super.key,
  });

  final String label;
  final bool selected;
  final ValueChanged<bool> onSelected;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: onSelected,
      selectedColor: AppPalette.primarySoft,
      backgroundColor: Colors.white,
      labelStyle: TextStyle(
        color: selected ? AppPalette.primary : AppPalette.inkMuted,
        fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
      ),
      side: BorderSide(
        color: selected ? AppPalette.primary : AppPalette.border,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.pill),
      ),
      showCheckmark: false,
      padding: const EdgeInsets.symmetric(horizontal: 8),
    );
  }
}

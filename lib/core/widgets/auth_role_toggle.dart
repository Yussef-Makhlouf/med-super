import 'package:flutter/material.dart';
import 'package:med_super/core/theme/app_palette.dart';
import 'package:med_super/core/theme/app_radii.dart';

/// Segmented role picker shared by the phone-OTP and phone+password login
/// screens — same track/chip mechanics, just a different set of roles
/// ([entries] lets each caller supply its own 2- or 3-way split).
class AuthRoleToggle<T> extends StatelessWidget {
  const AuthRoleToggle({
    required this.entries,
    required this.value,
    required this.onChanged,
    super.key,
  });

  final List<(String label, T value)> entries;
  final T value;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppPalette.surfaceSunken,
        borderRadius: BorderRadius.circular(AppRadii.md),
      ),
      child: Row(
        children: [
          for (final entry in entries)
            Expanded(
              child: _RoleChip(
                label: entry.$1,
                selected: entry.$2 == value,
                onTap: () => onChanged(entry.$2),
              ),
            ),
        ],
      ),
    );
  }
}

class _RoleChip extends StatelessWidget {
  const _RoleChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? Colors.white : Colors.transparent,
      borderRadius: BorderRadius.circular(AppRadii.sm),
      elevation: selected ? 1 : 0,
      shadowColor: Colors.black12,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadii.sm),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: selected ? AppPalette.primary : AppPalette.inkMuted,
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:med_super/core/theme/app_colors.dart';

class WalletAmountChip extends StatelessWidget {
  const WalletAmountChip({
    required this.amount,
    required this.isSelected,
    required this.onTap,
    super.key,
  });

  final double amount;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const brandBlue = Color(0xFF2563EB);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? brandBlue.withValues(alpha: 0.1) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? brandBlue : const Color(0xFFE2E8F0),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Text(
          '${amount.toInt()} ج.م',
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
            color: isSelected ? brandBlue : AppColors.ink900,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}

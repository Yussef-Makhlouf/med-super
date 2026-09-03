import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../../../../core/widgets/app_button.dart';
import '../../domain/entities/wallet_balance.dart';

class WalletBalanceCard extends StatelessWidget {
  final WalletBalance balance;
  final VoidCallback onAddBalance;
  final VoidCallback onTransfer;

  const WalletBalanceCard({
    super.key,
    required this.balance,
    required this.onAddBalance,
    required this.onTransfer,
  });

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat('#,##0.00', 'ar');
    final formattedAvailable = formatter.format(balance.availableBalance);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF1E40AF),
            Color(0xFF2563EB),
            Color(0xFF3B82F6),
          ],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2563EB).withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'wallet.available_balance'.tr(),
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white38),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.credit_card,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                formattedAvailable,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(width: 6),
              const Text(
                'ج.م',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: AppButton.filled(
                  label: 'wallet.deposit'.tr(),
                  icon: const Icon(Icons.add_circle_outline, size: 18),
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF1E40AF),
                  borderRadius: 14,
                  onPressed: onAddBalance,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AppButton.outlined(
                  label: 'wallet.transfer'.tr(),
                  icon: const Icon(Icons.swap_horiz, size: 18),
                  foregroundColor: Colors.white,
                  borderRadius: 14,
                  onPressed: onTransfer,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:med_super/core/theme/app_colors.dart';
import 'package:med_super/core/theme/color_schemes.dart';
import 'package:med_super/core/widgets/app_button.dart';
import '../../domain/entities/wallet_transaction.dart';

class WalletDepositSuccessScreen extends StatelessWidget {
  final WalletTransaction transaction;

  /// Display label for the funding card / destination account. Passed in by
  /// the confirm step rather than read off [transaction] — a wallet ledger
  /// row carries no payment-method field (File 12 Part 50.3).
  final String paymentMethodLabel;

  const WalletDepositSuccessScreen({
    super.key,
    required this.transaction,
    required this.paymentMethodLabel,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormatted = DateFormat('d MMMM yyyy، hh:mm a', 'ar').format(transaction.createdAt);
    final isTransfer = transaction.type == TransactionType.withdrawal;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(),
              Container(
                width: 90,
                height: 90,
                decoration: const BoxDecoration(
                  color: Color(0xFFDCFCE7),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  color: Color(0xFF16A34A),
                  size: 64,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                (isTransfer ? 'wallet.transfer_success_title' : 'wallet.deposit_success_title').tr(),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                  color: AppColors.ink900,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                (isTransfer ? 'wallet.transfer_success_sub' : 'wallet.deposit_success_sub').tr(
                  namedArgs: {'amount': transaction.amount.toStringAsFixed(0)},
                ),
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.mutedText2,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFF1F5F9)),
                ),
                child: Column(
                  children: [
                    _buildReceiptRow(
                      'wallet.transaction_number'.tr(),
                      '#${transaction.paymentIntentId ?? transaction.id}',
                    ),
                    const Divider(height: 1, color: Color(0xFFF1F5F9)),
                    _buildReceiptRow('wallet.date_and_time'.tr(), dateFormatted),
                    const Divider(height: 1, color: Color(0xFFF1F5F9)),
                    _buildReceiptRow(
                      'wallet.gross_amount'.tr(),
                      '${transaction.amount.toStringAsFixed(0)} ج.م',
                      isHighlight: true,
                    ),
                    const Divider(height: 1, color: Color(0xFFF1F5F9)),
                    if (isTransfer)
                      _buildReceiptRow(
                        'wallet.destination_account'.tr(),
                        paymentMethodLabel,
                        icon: Icons.account_balance_outlined,
                      )
                    else
                      _buildReceiptRow(
                        'wallet.payment_method'.tr(),
                        paymentMethodLabel,
                        icon: Icons.credit_card,
                      ),
                  ],
                ),
              ),
              const Spacer(),
              AppButton.filled(
                label: 'wallet.return_to_wallet'.tr(),
                fullWidth: true,
                borderRadius: 16,
                backgroundColor: brandBlue,
                foregroundColor: Colors.white,
                onPressed: () => context.go('/patient/home/wallet'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReceiptRow(
    String label,
    String value, {
    bool isHighlight = false,
    IconData? icon,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.mutedText2,
            ),
          ),
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 16, color: AppColors.mutedText2),
                const SizedBox(width: 6),
              ],
              Text(
                value,
                style: TextStyle(
                  fontSize: isHighlight ? 18 : 14,
                  fontWeight: isHighlight ? FontWeight.bold : FontWeight.w600,
                  color: isHighlight ? brandBlue : AppColors.ink900,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

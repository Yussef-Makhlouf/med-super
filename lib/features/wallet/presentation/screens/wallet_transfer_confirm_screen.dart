import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:med_super/core/theme/app_colors.dart';
import 'package:med_super/core/theme/color_schemes.dart';
import 'package:med_super/core/widgets/app_button.dart';
import 'package:med_super/core/widgets/step_progress_header.dart';
import '../../domain/entities/transfer_request.dart';
import '../controllers/wallet_providers.dart';
import 'wallet_deposit_success_screen.dart';
import 'wallet_transfer_destination_screen.dart';

/// Step 3/3 of the transfer-out flow: review the amount and destination
/// account chosen in the previous two steps before actually submitting.
class WalletTransferConfirmScreen extends ConsumerStatefulWidget {
  final double amount;
  final String destinationAccountId;

  const WalletTransferConfirmScreen({
    super.key,
    required this.amount,
    required this.destinationAccountId,
  });

  @override
  ConsumerState<WalletTransferConfirmScreen> createState() =>
      _WalletTransferConfirmScreenState();
}

class _WalletTransferConfirmScreenState
    extends ConsumerState<WalletTransferConfirmScreen> {
  bool _isLoading = false;

  Future<void> _submitTransfer() async {
    setState(() => _isLoading = true);
    try {
      final repo = ref.read(walletRepositoryProvider);
      final transaction = await repo.transferBalance(
        TransferRequest(
          amount: widget.amount,
          destinationAccountId: widget.destinationAccountId,
        ),
      );
      ref.invalidate(walletBalanceProvider);
      ref.invalidate(walletTransactionsProvider);

      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => WalletDepositSuccessScreen(
            transaction: transaction,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('common.error'.tr())),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          'wallet.step_confirm'.tr(),
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.ink900,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.ink900, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: StepProgressHeader(
              stepLabels: [
                'wallet.step_amount'.tr(),
                'wallet.select_destination_account'.tr(),
                'wallet.step_confirm'.tr(),
              ],
              currentStep: 2,
              accentColor: brandBlue,
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildReviewCard(
                    title: 'wallet.amount_details_title'.tr(),
                    icon: Icons.payments_outlined,
                    onEdit: () {
                      Navigator.of(context)
                        ..pop()
                        ..pop();
                    },
                    rows: [
                      (
                        label: 'wallet.gross_amount'.tr(),
                        value: '${widget.amount.toStringAsFixed(0)} ج.م',
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildReviewCard(
                    title: 'wallet.destination_account_title'.tr(),
                    icon: Icons.account_balance_outlined,
                    onEdit: () => Navigator.of(context).pop(),
                    rows: [
                      (
                        label: 'wallet.destination_account'.tr(),
                        value: walletDestinationAccountLabel(widget.destinationAccountId),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(20),
            color: Colors.white,
            child: AppButton.filled(
              label: 'wallet.confirm_transfer'.tr(),
              fullWidth: true,
              borderRadius: 16,
              isLoading: _isLoading,
              backgroundColor: brandBlue,
              foregroundColor: Colors.white,
              onPressed: _submitTransfer,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewCard({
    required String title,
    required IconData icon,
    required VoidCallback onEdit,
    required List<({String label, String value})> rows,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Color(0xFFF1F5F9)),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: brandBlue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, size: 16, color: brandBlue),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: AppColors.ink900,
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined, size: 14, color: brandBlue),
                  label: Text(
                    'wallet.edit'.tr(),
                    style: const TextStyle(color: brandBlue, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              children: [
                for (final row in rows)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          row.label,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.mutedText2,
                          ),
                        ),
                        Text(
                          row.value,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.ink900,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

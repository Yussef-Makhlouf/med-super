import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:med_super/core/theme/app_colors.dart';
import 'package:med_super/core/theme/color_schemes.dart';
import 'package:med_super/core/widgets/app_button.dart';
import 'package:med_super/core/widgets/step_progress_header.dart';
import 'wallet_transfer_confirm_screen.dart';

/// The bank accounts a doctor can transfer wallet earnings to. There's no
/// "manage bank accounts" feature yet, so this is the one linked account
/// available today plus an "add new" affordance for later.
String walletDestinationAccountLabel(String id) => switch (id) {
      'bank_nbe_5566' => 'البنك الأهلي المصري **** 5566',
      _ => id,
    };

/// Step 2/3 of the transfer-out flow: choose the destination bank account.
class WalletTransferDestinationScreen extends StatefulWidget {
  final double amount;

  const WalletTransferDestinationScreen({
    super.key,
    required this.amount,
  });

  @override
  State<WalletTransferDestinationScreen> createState() =>
      _WalletTransferDestinationScreenState();
}

class _WalletTransferDestinationScreenState
    extends State<WalletTransferDestinationScreen> {
  String _selectedAccountId = 'bank_nbe_5566';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          'wallet.select_destination_account'.tr(),
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
              currentStep: 1,
              accentColor: brandBlue,
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'wallet.gross_amount'.tr(),
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.mutedText2,
                          ),
                        ),
                        Text(
                          '${widget.amount.toStringAsFixed(0)} ج.م',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: brandBlue,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'wallet.select_destination_account'.tr(),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: AppColors.ink900,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildAccountOption(
                    id: 'bank_nbe_5566',
                    title: walletDestinationAccountLabel('bank_nbe_5566'),
                    subtitle: 'حساب جاري',
                  ),
                  const SizedBox(height: 10),
                  Material(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('wallet.add_bank_account_coming_soon'.tr())),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF0FDF4),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.add,
                                color: Color(0xFF16A34A),
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Text(
                              'wallet.add_new_bank_account'.tr(),
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                                color: AppColors.ink900,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(20),
            color: Colors.white,
            child: AppButton.filled(
              label: 'متابعة',
              fullWidth: true,
              borderRadius: 16,
              backgroundColor: brandBlue,
              foregroundColor: Colors.white,
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => WalletTransferConfirmScreen(
                      amount: widget.amount,
                      destinationAccountId: _selectedAccountId,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountOption({
    required String id,
    required String title,
    required String subtitle,
  }) {
    final isSelected = _selectedAccountId == id;

    return Material(
      color: isSelected ? const Color(0xFFEFF6FF) : Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: () => setState(() => _selectedAccountId = id),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? brandBlue : const Color(0xFFE2E8F0),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: brandBlue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.account_balance_outlined,
                  color: brandBlue,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                        fontSize: 14,
                        color: AppColors.ink900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.mutedText2,
                      ),
                    ),
                  ],
                ),
              ),
              Radio<String>(
                value: id,
                groupValue: _selectedAccountId,
                activeColor: brandBlue,
                onChanged: (val) {
                  if (val != null) setState(() => _selectedAccountId = val);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:med_super/core/theme/app_colors.dart';
import 'package:med_super/core/theme/color_schemes.dart';
import 'package:med_super/core/widgets/app_button.dart';
import 'package:med_super/core/widgets/step_progress_header.dart';
import '../controllers/wallet_providers.dart';
import '../widgets/amount_chip.dart';
import 'wallet_transfer_destination_screen.dart';

/// Step 1/3 of the transfer-out flow: pick how much of the available
/// balance to move to a linked bank account.
class WalletTransferScreen extends ConsumerStatefulWidget {
  const WalletTransferScreen({super.key});

  @override
  ConsumerState<WalletTransferScreen> createState() =>
      _WalletTransferScreenState();
}

class _WalletTransferScreenState extends ConsumerState<WalletTransferScreen> {
  final _customController = TextEditingController();
  double _selectedAmount = 500.0;
  bool _isCustom = false;

  @override
  void dispose() {
    _customController.dispose();
    super.dispose();
  }

  void _selectAmount(double val) {
    setState(() {
      _selectedAmount = val;
      _isCustom = false;
      _customController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final balanceAsync = ref.watch(walletBalanceProvider);
    final availableBalance = balanceAsync.asData?.value.availableBalance ?? 0.0;
    final remainingBalance = availableBalance - _selectedAmount;
    final exceedsBalance = _selectedAmount > availableBalance;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          'wallet.transfer'.tr(),
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
              currentStep: 0,
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
                          'wallet.available_for_transfer'.tr(),
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.mutedText2,
                          ),
                        ),
                        Text(
                          '${availableBalance.toStringAsFixed(0)} ج.م',
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
                    'wallet.transfer_amount_title'.tr(),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: AppColors.ink900,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [500.0, 1000.0, 2000.0, availableBalance]
                        .where((amt) => amt > 0)
                        .toSet()
                        .map((amt) {
                      final isSel = !_isCustom && _selectedAmount == amt;
                      return WalletAmountChip(
                        amount: amt,
                        isSelected: isSel,
                        onTap: () => _selectAmount(amt),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'wallet.custom_amount'.tr(),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: AppColors.ink900,
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _customController,
                    keyboardType: TextInputType.number,
                    onChanged: (val) {
                      final parsed = double.tryParse(val);
                      if (parsed != null && parsed > 0) {
                        setState(() {
                          _selectedAmount = parsed;
                          _isCustom = true;
                        });
                      }
                    },
                    decoration: InputDecoration(
                      hintText: '0.00',
                      suffixText: 'ج.م',
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(
                          color: brandBlue,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: exceedsBalance
                          ? const Color(0xFFFEF2F2)
                          : const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: exceedsBalance
                            ? const Color(0xFFFCA5A5)
                            : const Color(0xFFBFDBFE),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          (exceedsBalance
                                  ? 'wallet.insufficient_balance'
                                  : 'wallet.remaining_balance_preview')
                              .tr(),
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: exceedsBalance
                                ? const Color(0xFFDC2626)
                                : const Color(0xFF1E40AF),
                          ),
                        ),
                        if (!exceedsBalance)
                          Text(
                            '${remainingBalance.toStringAsFixed(0)} ج.م',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Color(0xFF1E40AF),
                            ),
                          ),
                      ],
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
              onPressed: (_selectedAmount > 0 && !exceedsBalance)
                  ? () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => WalletTransferDestinationScreen(
                            amount: _selectedAmount,
                          ),
                        ),
                      );
                    }
                  : null,
            ),
          ),
        ],
      ),
    );
  }
}

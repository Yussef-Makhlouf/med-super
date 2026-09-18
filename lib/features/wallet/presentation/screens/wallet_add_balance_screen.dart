import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:med_super/core/theme/app_colors.dart';
import 'package:med_super/core/theme/color_schemes.dart';
import 'package:med_super/core/widgets/app_button.dart';
import 'package:med_super/core/widgets/step_progress_header.dart';
import '../controllers/wallet_providers.dart';
import '../widgets/amount_chip.dart';
import 'wallet_top_up_details_screen.dart';

class WalletAddBalanceScreen extends ConsumerStatefulWidget {
  const WalletAddBalanceScreen({super.key});

  @override
  ConsumerState<WalletAddBalanceScreen> createState() =>
      _WalletAddBalanceScreenState();
}

class _WalletAddBalanceScreenState
    extends ConsumerState<WalletAddBalanceScreen> {
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
    final currentBalance = balanceAsync.asData?.value.availableBalance ?? 4250.0;
    final expectedBalance = currentBalance + _selectedAmount;


    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          'wallet.add_balance'.tr(),
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
                'wallet.step_payment_details'.tr(),
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
                  Text(
                    'wallet.choose_amount'.tr(),
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
                    children: [100.0, 200.0, 500.0, 1000.0].map((amt) {
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
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFBFDBFE)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'wallet.new_balance_preview'.tr(),
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1E40AF),
                          ),
                        ),
                        Text(
                          '${expectedBalance.toStringAsFixed(2)} ج.م',
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
              onPressed: _selectedAmount > 0
                  ? () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => WalletTopUpDetailsScreen(
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

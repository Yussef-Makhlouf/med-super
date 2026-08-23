import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:med_super/core/theme/app_colors.dart';
import 'package:med_super/core/theme/color_schemes.dart';
import 'package:med_super/core/widgets/app_button.dart';
import 'package:med_super/core/widgets/step_progress_header.dart';
import 'wallet_confirm_deposit_screen.dart';

/// The selectable payment methods shared between [WalletPaymentMethodScreen]
/// and [WalletConfirmDepositScreen] (which needs to display the chosen
/// method's label without duplicating this list).
String walletPaymentMethodLabel(String id) {
  switch (id) {
    case 'card_mastercard_8888':
      return 'Mastercard **** 8888';
    case 'card_visa_4242':
      return 'Visa **** 4242';
    case 'apple_pay':
      return 'wallet.apple_pay'.tr();
    case 'add_new_card':
      return 'wallet.add_new_card'.tr();
    default:
      return id;
  }
}

class WalletPaymentMethodScreen extends ConsumerStatefulWidget {
  final double amount;

  const WalletPaymentMethodScreen({
    super.key,
    required this.amount,
  });

  @override
  ConsumerState<WalletPaymentMethodScreen> createState() =>
      _WalletPaymentMethodScreenState();
}

class _WalletPaymentMethodScreenState
    extends ConsumerState<WalletPaymentMethodScreen> {
  String _selectedMethod = 'card_mastercard_8888';

  void _goToConfirm() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => WalletConfirmDepositScreen(
          amount: widget.amount,
          paymentMethodId: _selectedMethod,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {


    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          'wallet.step_payment_method'.tr(),
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
                'wallet.step_payment_method'.tr(),
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
                        const Text(
                          'المبلغ الإجمالي للإيداع',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.mutedText2,
                          ),
                        ),
                        Text(
                          '${widget.amount.toStringAsFixed(2)} ج.م',
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
                    'wallet.select_payment_method'.tr(),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: AppColors.ink900,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildPaymentOption(
                    id: 'card_mastercard_8888',
                    title: 'Mastercard **** 8888',
                    subtitle: 'تنتهي في 12/28',
                    icon: Icons.credit_card,
                    iconColor: const Color(0xFFEA580C),
                  ),
                  const SizedBox(height: 10),
                  _buildPaymentOption(
                    id: 'card_visa_4242',
                    title: 'Visa **** 4242',
                    subtitle: 'تنتهي في 09/27',
                    icon: Icons.credit_card,
                    iconColor: brandBlue,
                  ),
                  const SizedBox(height: 10),
                  _buildPaymentOption(
                    id: 'apple_pay',
                    title: 'wallet.apple_pay'.tr(),
                    subtitle: 'الدفع السريع المباشر',
                    icon: Icons.phone_iphone,
                    iconColor: Colors.black87,
                  ),
                  const SizedBox(height: 10),
                  _buildPaymentOption(
                    id: 'add_new_card',
                    title: 'wallet.add_new_card'.tr(),
                    subtitle: 'بطاقات الفيزا، ماستركارد، أو ميزة',
                    icon: Icons.add_card,
                    iconColor: const Color(0xFF16A34A),
                  ),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(20),
            color: Colors.white,
            child: AppButton.filled(
              label: 'wallet.review_and_confirm'.tr(),
              fullWidth: true,
              borderRadius: 16,
              backgroundColor: brandBlue,
              foregroundColor: Colors.white,
              onPressed: _goToConfirm,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentOption({
    required String id,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
  }) {

    final isSelected = _selectedMethod == id;

    return Material(
      color: isSelected ? const Color(0xFFEFF6FF) : Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: () => setState(() => _selectedMethod = id),
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
                  color: iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 22),
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
                groupValue: _selectedMethod,
                activeColor: brandBlue,
                onChanged: (val) {
                  if (val != null) setState(() => _selectedMethod = val);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

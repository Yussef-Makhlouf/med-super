import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:med_super/core/payments/presentation/widgets/payment_customer_fields.dart';
import 'package:med_super/core/theme/app_colors.dart';
import 'package:med_super/core/theme/color_schemes.dart';
import 'package:med_super/core/widgets/app_button.dart';
import 'package:med_super/core/widgets/step_progress_header.dart';
import 'package:med_super/features/auth/presentation/controllers/session_provider.dart';
import 'wallet_confirm_deposit_screen.dart';

/// Step 2/3 of the top-up flow: the billing details Paymob requires.
///
/// This replaced a saved-card picker (Visa ****4242 / Apple Pay) that had
/// no backend behind it — `POST /v1/wallet/top-up` is card-only and takes
/// no payment-method parameter at all, so there was nothing real to choose
/// between. What it does need is `customer`, which nothing collected.
class WalletTopUpDetailsScreen extends ConsumerStatefulWidget {
  const WalletTopUpDetailsScreen({required this.amount, super.key});

  final double amount;

  @override
  ConsumerState<WalletTopUpDetailsScreen> createState() =>
      _WalletTopUpDetailsScreenState();
}

class _WalletTopUpDetailsScreenState
    extends ConsumerState<WalletTopUpDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  late final PaymentCustomerFormControllers _controllers;

  @override
  void initState() {
    super.initState();
    final session = ref.read(sessionControllerProvider).asData?.value;
    _controllers = PaymentCustomerFormControllers(
      phone: session?.user.phone,
    );
  }

  @override
  void dispose() {
    _controllers.dispose();
    super.dispose();
  }

  void _goToConfirm() {
    if (_formKey.currentState?.validate() != true) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => WalletConfirmDepositScreen(
          amount: widget.amount,
          customer: _controllers.toCustomerInfo(),
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
          'payments.customer_title'.tr(),
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.ink900,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios,
            color: AppColors.ink900,
            size: 20,
          ),
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
              currentStep: 1,
              accentColor: brandBlue,
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
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
                            'wallet.total_deposit_amount'.tr(),
                            style: const TextStyle(
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
                      'payments.customer_title'.tr(),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: AppColors.ink900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'wallet.top_up_card_only'.tr(),
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.mutedText2,
                      ),
                    ),
                    const SizedBox(height: 16),
                    PaymentCustomerFields(controllers: _controllers),
                  ],
                ),
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
}

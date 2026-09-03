import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:med_super/core/theme/app_colors.dart';
import 'package:med_super/core/theme/color_schemes.dart';
import 'package:med_super/core/widgets/app_button.dart';
import '../controllers/wallet_providers.dart';
import 'wallet_refund_status_screen.dart';

class WalletRefundRequestScreen extends ConsumerStatefulWidget {
  final String transactionId;

  const WalletRefundRequestScreen({
    super.key,
    required this.transactionId,
  });

  @override
  ConsumerState<WalletRefundRequestScreen> createState() =>
      _WalletRefundRequestScreenState();
}

class _WalletRefundRequestScreenState
    extends ConsumerState<WalletRefundRequestScreen> {
  String _selectedReasonKey = 'wallet.refund_reason_cancelled';
  final _detailsController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _detailsController.dispose();
    super.dispose();
  }

  Future<void> _submitRefund() async {
    setState(() => _isLoading = true);
    try {
      final repo = ref.read(walletRepositoryProvider);
      final refundReq = await repo.requestRefund(
        transactionId: widget.transactionId,
        reason: _selectedReasonKey.tr(),
        details: _detailsController.text.trim().isNotEmpty
            ? _detailsController.text.trim()
            : null,
      );

      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => WalletRefundStatusScreen(
            refundId: refundReq.id,
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

    final reasons = [
      'wallet.refund_reason_cancelled',
      'wallet.refund_reason_no_show',
      'wallet.refund_reason_unsatisfied',
      'wallet.refund_reason_other',
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          'wallet.refund_request'.tr(),
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
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTransactionSummaryCard(ref),
                  const SizedBox(height: 20),
                  Text(
                    'wallet.refund_reason_title'.tr(),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: AppColors.ink900,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...reasons.map((key) {
                    final isSelected = _selectedReasonKey == key;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Material(
                        color: isSelected ? const Color(0xFFEFF6FF) : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isSelected ? brandBlue : const Color(0xFFE2E8F0),
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: RadioListTile<String>(
                            value: key,
                            groupValue: _selectedReasonKey,
                            title: Text(
                              key.tr(),
                              style: TextStyle(
                                fontWeight:
                                    isSelected ? FontWeight.bold : FontWeight.w500,
                                fontSize: 14,
                                color: AppColors.ink900,
                              ),
                            ),
                            activeColor: brandBlue,
                            onChanged: (val) {
                              if (val != null) {
                                setState(() => _selectedReasonKey = val);
                              }
                            },
                          ),
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 20),
                  Text(
                    'wallet.additional_details'.tr(),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: AppColors.ink900,
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _detailsController,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: 'wallet.details_hint'.tr(),
                      filled: true,
                      fillColor: Colors.white,
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
                  const SizedBox(height: 20),
                  _buildRefundMethodInfo(),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(20),
            color: Colors.white,
            child: AppButton.filled(
              label: 'wallet.submit_refund'.tr(),
              fullWidth: true,
              borderRadius: 16,
              isLoading: _isLoading,
              backgroundColor: brandBlue,
              foregroundColor: Colors.white,
              onPressed: _submitRefund,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionSummaryCard(WidgetRef ref) {
    final detailAsync = ref.watch(
      walletTransactionDetailProvider(widget.transactionId),
    );

    return detailAsync.when(
      data: (tx) {
        final dateFormatted =
            DateFormat('d MMMM yyyy، hh:mm a', 'ar').format(tx.createdAt);
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: brandBlue,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.medical_services_outlined,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tx.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: AppColors.ink900,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          dateFormatted,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.mutedText2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              const Divider(height: 1, color: Color(0xFFF1F5F9)),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'wallet.total_amount_due'.tr(),
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.mutedText2,
                    ),
                  ),
                  Text(
                    '${tx.amount.toStringAsFixed(0)} ج.م',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.ink900,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
      loading: () => const SizedBox(
        height: 90,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (err, _) => const SizedBox.shrink(),
    );
  }

  Widget _buildRefundMethodInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFBFDBFE)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, color: Color(0xFF1E40AF), size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'wallet.refund_method_title'.tr(),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: Color(0xFF1E40AF),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'wallet.refund_method_info'.tr(),
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF1E40AF),
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

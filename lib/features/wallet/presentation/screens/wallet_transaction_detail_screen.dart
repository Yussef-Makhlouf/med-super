import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:med_super/core/theme/app_colors.dart';
import 'package:med_super/core/theme/color_schemes.dart';
import 'package:med_super/core/widgets/app_button.dart';
import 'package:med_super/features/auth/presentation/controllers/session_provider.dart';
import '../../domain/entities/wallet_transaction.dart';
import '../controllers/wallet_providers.dart';
import 'wallet_refund_request_screen.dart';

class WalletTransactionDetailScreen extends ConsumerWidget {
  final String transactionId;

  const WalletTransactionDetailScreen({
    super.key,
    required this.transactionId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(walletTransactionDetailProvider(transactionId));
    final isPatientView =
        ref.watch(sessionControllerProvider).asData?.value?.user.isPatient ?? false;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          'wallet.transaction_details'.tr(),
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
      body: detailAsync.when(
        data: (tx) => _buildDetailBody(context, tx, isPatientView: isPatientView),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('common.error'.tr())),
      ),
    );
  }

  String _amountLabelKey(TransactionType type) => switch (type) {
        TransactionType.deposit => 'wallet.amount_added',
        TransactionType.payment => 'wallet.amount_paid',
        TransactionType.refund => 'wallet.amount_refunded',
        TransactionType.withdrawal => 'wallet.amount_withdrawn',
      };

  String _statusLabelKey(TransactionStatus status) => switch (status) {
        TransactionStatus.completed => 'wallet.completed_successfully',
        TransactionStatus.pending => 'wallet.transaction_pending',
        TransactionStatus.failed => 'wallet.transaction_failed',
      };

  Widget _buildDetailBody(
    BuildContext context,
    WalletTransaction tx, {
    required bool isPatientView,
  }) {
    final dateFormatted = DateFormat('d MMMM yyyy، hh:mm a', 'ar').format(tx.createdAt);
    final isPositive = tx.type == TransactionType.deposit || tx.type == TransactionType.refund;
    final statusColor = switch (tx.status) {
      TransactionStatus.completed => const Color(0xFF16A34A),
      TransactionStatus.pending => const Color(0xFFD97706),
      TransactionStatus.failed => const Color(0xFFDC2626),
    };

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFFF1F5F9)),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isPositive ? const Color(0xFFDCFCE7) : const Color(0xFFEFF6FF),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check_circle_rounded,
                    color: isPositive ? const Color(0xFF16A34A) : const Color(0xFF2563EB),
                    size: 32,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  _amountLabelKey(tx.type).tr(),
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.mutedText2,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${isPositive ? '+' : '-'}${tx.amount.toStringAsFixed(0)} ج.م',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 28,
                    color: isPositive ? const Color(0xFF16A34A) : AppColors.ink900,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.circle, size: 6, color: statusColor),
                      const SizedBox(width: 6),
                      Text(
                        _statusLabelKey(tx.status).tr(),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: statusColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFF1F5F9)),
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, size: 18, color: AppColors.mutedText2),
                      const SizedBox(width: 8),
                      Text(
                        'wallet.transaction_info_title'.tr(),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: AppColors.ink900,
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, color: Color(0xFFF1F5F9)),
                if (tx.serviceName != null)
                  _buildRow(
                    'wallet.service'.tr(),
                    tx.serviceName!,
                    icon: Icons.medical_services_outlined,
                  ),
                if (tx.doctorName != null)
                  _buildRow(
                    (isPatientView ? 'wallet.doctor_name' : 'wallet.doctor').tr(),
                    tx.doctorName!,
                    icon: Icons.person_outline,
                  ),
                _buildRow(
                  'wallet.date_and_time'.tr(),
                  dateFormatted,
                  icon: Icons.calendar_today_outlined,
                ),
                _buildRow(
                  'wallet.payment_method'.tr(),
                  tx.paymentMethod ?? 'المحفظة الالكترونية',
                  icon: Icons.account_balance_wallet_outlined,
                ),
                _buildRow(
                  'wallet.reference_number'.tr(),
                  '#${tx.referenceNumber ?? 'TXN-84920481'}',
                  icon: Icons.confirmation_number_outlined,
                  isLast: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFF1F5F9)),
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Row(
                    children: [
                      const Icon(Icons.credit_card, size: 18, color: AppColors.mutedText2),
                      const SizedBox(width: 8),
                      Text(
                        'wallet.financial_details_title'.tr(),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: AppColors.ink900,
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, color: Color(0xFFF1F5F9)),
                _buildRow(
                  'wallet.base_consultation_fee'.tr(),
                  '${tx.amount.toStringAsFixed(0)} ج.م',
                ),
                if (tx.fee != null && tx.fee! > 0)
                  _buildRow(
                    'wallet.platform_fee'.tr(),
                    '-${tx.fee!.toStringAsFixed(0)} ج.م',
                    isNegative: true,
                  ),
                _buildRow('wallet.vat_tax'.tr(), '0.00 ج.م', isLast: true),
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCFCE7),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'wallet.final_amount_added'.tr(),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.ink900,
                        ),
                      ),
                      Text(
                        '${(tx.netAmount ?? tx.amount).toStringAsFixed(0)} ج.م',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF16A34A),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
          const SizedBox(height: 24),
          AppButton.filled(
            label: 'wallet.download_receipt'.tr(),
            fullWidth: true,
            borderRadius: 16,
            backgroundColor: brandBlue,
            foregroundColor: Colors.white,
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('تم حفظ الإيصال في جهازك')),
              );
            },
          ),
          if (tx.type == TransactionType.payment) ...[
            const SizedBox(height: 12),
            AppButton.outlined(
              label: 'wallet.request_refund'.tr(),
              fullWidth: true,
              borderRadius: 16,
              icon: const Icon(Icons.assignment_return_outlined, size: 18),
              foregroundColor: brandBlue,
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => WalletRefundRequestScreen(
                      transactionId: tx.id,
                    ),
                  ),
                );
              },
            ),
          ],
          const SizedBox(height: 12),
          AppButton.outlined(
            label: 'wallet.need_help'.tr(),
            fullWidth: true,
            borderRadius: 16,
            icon: const Icon(Icons.help_outline, size: 18),
            foregroundColor: brandBlue,
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('تم فتح محادثة الدعم الفني')),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildRow(
    String label,
    String value, {
    IconData? icon,
    bool isNegative = false,
    bool isLast = false,
  }) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 16, color: AppColors.mutedText2),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.mutedText2,
                    ),
                  ),
                ],
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isNegative ? const Color(0xFFDC2626) : AppColors.ink900,
                ),
              ),
            ],
          ),
        ),
        if (!isLast) const Divider(height: 1, color: Color(0xFFF1F5F9)),
      ],
    );
  }
}

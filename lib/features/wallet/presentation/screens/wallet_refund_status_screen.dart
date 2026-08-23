import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:med_super/core/theme/app_colors.dart';
import 'package:med_super/core/theme/color_schemes.dart';
import 'package:med_super/core/widgets/app_button.dart';
import '../../domain/entities/refund_request.dart';
import '../controllers/wallet_providers.dart';
import 'wallet_dashboard_screen.dart';

class WalletRefundStatusScreen extends ConsumerWidget {
  final String refundId;

  const WalletRefundStatusScreen({
    super.key,
    required this.refundId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusAsync = ref.watch(refundStatusProvider(refundId));

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          'wallet.refund_status_title'.tr(),
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
      body: statusAsync.when(
        data: (refund) => _buildStatusBody(context, refund),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('common.error'.tr())),
      ),
    );
  }

  Widget _buildStatusBody(BuildContext context, RefundRequest refund) {
    final dateFormatted = DateFormat('d MMMM yyyy', 'ar').format(refund.createdAt);
    final timeFormatted = DateFormat('d MMMM، hh:mm a', 'ar').format(refund.createdAt);

    final steps = [
      _RefundStepInfo(
        status: RefundStatus.submitted,
        title: 'wallet.status_submitted'.tr(),
        description: timeFormatted,
      ),
      _RefundStepInfo(
        status: RefundStatus.underReview,
        title: 'wallet.status_under_review'.tr(),
        description: 'wallet.step_under_review_desc'.tr(),
      ),
      _RefundStepInfo(
        status: RefundStatus.approved,
        title: 'wallet.status_approved'.tr(),
        description: 'wallet.step_approved_desc'.tr(),
      ),
      _RefundStepInfo(
        status: RefundStatus.transferred,
        title: 'wallet.status_transferred'.tr(),
        description: 'wallet.step_transferred_desc'.tr(),
      ),
    ];

    final currentStepIndex = _getStepIndex(refund.status);

    return SingleChildScrollView(
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${'wallet.request_number'.tr()}: #${refund.id}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: brandBlue,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${'wallet.cash_refund'.tr()} - ${refund.reason}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: AppColors.ink900,
                            ),
                            textAlign: TextAlign.end,
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
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'wallet.request_date'.tr(),
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.mutedText2,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            dateFormatted,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.ink900,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'wallet.amount_refunded'.tr(),
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.mutedText2,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${refund.amount.toStringAsFixed(0)} ج.م',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: brandBlue,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          Text(
            'wallet.request_path_title'.tr(),
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: AppColors.ink900,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFF1F5F9)),
            ),
            child: Column(
              children: List.generate(steps.length, (index) {
                final isDone = index < currentStepIndex;
                final isCurrent = index == currentStepIndex;
                final isLast = index == steps.length - 1;

                return IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        children: [
                          Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isDone
                                  ? const Color(0xFF16A34A)
                                  : isCurrent
                                      ? brandBlue
                                      : const Color(0xFFF1F5F9),
                            ),
                            child: Icon(
                              isDone
                                  ? Icons.check
                                  : isCurrent
                                      ? Icons.hourglass_top
                                      : Icons.circle_outlined,
                              size: 16,
                              color: isDone || isCurrent
                                  ? Colors.white
                                  : AppColors.mutedText2,
                            ),
                          ),
                          if (!isLast)
                            Expanded(
                              child: Container(
                                width: 2,
                                color: isDone
                                    ? const Color(0xFF16A34A)
                                    : const Color(0xFFE2E8F0),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                steps[index].title,
                                style: TextStyle(
                                  fontWeight: isCurrent || isDone
                                      ? FontWeight.bold
                                      : FontWeight.w600,
                                  fontSize: 14,
                                  color: isCurrent || isDone
                                      ? AppColors.ink900
                                      : AppColors.mutedText2,
                                ),
                              ),
                              const SizedBox(height: 4),
                              if (isCurrent)
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEFF6FF),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    steps[index].description,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF1E40AF),
                                    ),
                                  ),
                                )
                              else
                                Text(
                                  steps[index].description,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.mutedText2,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFF1F5F9)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline, color: brandBlue, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'wallet.need_help'.tr(),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: AppColors.ink900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'wallet.need_help_desc'.tr(),
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.mutedText2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('تم فتح محادثة الدعم الفني')),
                          );
                        },
                        child: Text(
                          '${'wallet.talk_to_support'.tr()} ←',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: brandBlue,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          AppButton.filled(
            label: 'wallet.return_to_wallet'.tr(),
            fullWidth: true,
            borderRadius: 16,
            backgroundColor: brandBlue,
            foregroundColor: Colors.white,
            onPressed: () {
              Navigator.of(context).popUntil(
                (route) => route.settings.name == WalletDashboardScreen.routeName,
              );
            },
          ),
          const SizedBox(height: 12),
          AppButton.outlined(
            label: 'wallet.download_invoice'.tr(),
            fullWidth: true,
            borderRadius: 16,
            foregroundColor: brandBlue,
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('تم حفظ الفاتورة في جهازك')),
              );
            },
          ),
        ],
      ),
    );
  }

  int _getStepIndex(RefundStatus status) {
    switch (status) {
      case RefundStatus.submitted:
        return 0;
      case RefundStatus.underReview:
        return 1;
      case RefundStatus.approved:
        return 2;
      case RefundStatus.transferred:
        return 3;
      case RefundStatus.rejected:
        return 1;
    }
  }
}

class _RefundStepInfo {
  final RefundStatus status;
  final String title;
  final String description;

  const _RefundStepInfo({
    required this.status,
    required this.title,
    required this.description,
  });
}

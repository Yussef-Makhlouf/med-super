import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:med_super/core/theme/app_colors.dart';
import '../../domain/entities/wallet_transaction.dart';
import '../utils/wallet_transaction_labels.dart';

class TransactionListTile extends StatelessWidget {
  const TransactionListTile({
    required this.transaction,
    required this.onTap,
    super.key,
  });

  final WalletTransaction transaction;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDeposit = transaction.type == TransactionType.deposit || transaction.type == TransactionType.refund;
    final iconData = _getIcon(transaction.type);
    final iconBg = isDeposit ? const Color(0xFFECFDF5) : const Color(0xFFEFF6FF);
    final iconColor = isDeposit ? const Color(0xFF10B981) : const Color(0xFF2563EB);
    final sign = isDeposit ? '+' : '-';
    final amountColor = isDeposit ? const Color(0xFF10B981) : AppColors.ink900;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(iconData, color: iconColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      walletTransactionTypeLabelKey(transaction.type).tr(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: AppColors.ink900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatDate(transaction.createdAt),
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.mutedText2,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '$sign${transaction.amount.toStringAsFixed(0)} ${transaction.currency}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: amountColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getIcon(TransactionType type) {
    switch (type) {
      case TransactionType.deposit:
        return Icons.arrow_downward;
      case TransactionType.refund:
        return Icons.replay;
      case TransactionType.withdrawal:
        return Icons.arrow_upward;
      case TransactionType.payment:
        return Icons.shopping_bag_outlined;
    }
  }

  String _formatDate(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}

typedef WalletTransactionListTile = TransactionListTile;

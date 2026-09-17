import 'package:med_super/features/wallet/domain/entities/wallet_transaction.dart';

/// Parses one `WalletTransactionSummary` from `GET /v1/wallet/transactions` —
/// camelCase keys, `amount`/`resultingBalance` as fixed 2-decimal strings,
/// and the enums in the backend's SCREAMING_SNAKE spelling.
class WalletTransactionModel extends WalletTransaction {
  const WalletTransactionModel({
    required super.id,
    required super.type,
    required super.amount,
    super.currency = 'EGP',
    required super.createdAt,
    required super.status,
    super.resultingBalance,
    super.paymentIntentId,
    super.appointmentId,
  });

  factory WalletTransactionModel.fromJson(Map<String, dynamic> json) {
    return WalletTransactionModel(
      id: json['id'] as String? ?? '',
      type: _typeFromString(json['type'] as String?),
      amount: double.tryParse(json['amount']?.toString() ?? '') ?? 0.0,
      createdAt:
          DateTime.tryParse(json['createdAt'] as String? ?? '') ??
              DateTime.now(),
      status: _statusFromString(json['status'] as String?),
      resultingBalance: double.tryParse(
        json['resultingBalance']?.toString() ?? '',
      ),
      paymentIntentId: json['paymentIntentId'] as String?,
      appointmentId: json['appointmentId'] as String?,
    );
  }

  static TransactionType _typeFromString(String? type) {
    switch (type) {
      case 'TOP_UP':
        return TransactionType.deposit;
      case 'REFUND':
        return TransactionType.refund;
      // Mock-only — the backend has no transfer-out concept.
      case 'WITHDRAWAL':
        return TransactionType.withdrawal;
      case 'APPOINTMENT_PAYMENT':
      default:
        return TransactionType.payment;
    }
  }

  static TransactionStatus _statusFromString(String? status) {
    switch (status) {
      case 'PENDING':
        return TransactionStatus.pending;
      case 'FAILED':
        return TransactionStatus.failed;
      case 'COMPLETED':
      default:
        return TransactionStatus.completed;
    }
  }
}

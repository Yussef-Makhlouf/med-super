import 'package:med_super/features/wallet/domain/entities/wallet_transaction.dart';

class WalletTransactionModel extends WalletTransaction {
  const WalletTransactionModel({
    required super.id,
    required super.title,
    required super.type,
    required super.amount,
    super.currency = 'EGP',
    required super.timestamp,
    required super.status,
    super.serviceName,
    super.doctorName,
    super.fees = 0.0,
    super.netAmount,
    super.referenceNumber,
    super.paymentMethod,
  });

  factory WalletTransactionModel.fromJson(Map<String, dynamic> json) {
    return WalletTransactionModel(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      type: _typeFromString(json['type'] as String?),
      amount: (json['amount'] as num? ?? 0).toDouble(),
      currency: json['currency'] as String? ?? 'EGP',
      timestamp: DateTime.tryParse(json['timestamp'] as String? ?? '') ?? DateTime.now(),
      status: _statusFromString(json['status'] as String?),
      serviceName: json['service_name'] as String?,
      doctorName: json['doctor_name'] as String?,
      fees: (json['fees'] as num?)?.toDouble() ?? 0.0,
      netAmount: (json['net_amount'] as num?)?.toDouble(),
      referenceNumber: json['reference_number'] as String?,
      paymentMethod: json['payment_method'] as String?,
    );
  }

  static TransactionType _typeFromString(String? type) {
    switch (type?.toLowerCase()) {
      case 'deposit':
        return TransactionType.deposit;
      case 'withdrawal':
        return TransactionType.withdrawal;
      case 'refund':
        return TransactionType.refund;
      case 'payment':
      default:
        return TransactionType.payment;
    }
  }

  static TransactionStatus _statusFromString(String? status) {
    switch (status?.toLowerCase()) {
      case 'pending':
        return TransactionStatus.pending;
      case 'failed':
        return TransactionStatus.failed;
      case 'completed':
      default:
        return TransactionStatus.completed;
    }
  }
}

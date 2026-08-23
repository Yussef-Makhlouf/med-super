enum TransactionType { deposit, withdrawal, payment, refund }
enum TransactionStatus { completed, pending, failed }

class WalletTransaction {
  final String id;
  final String title;
  final TransactionType type;
  final double amount;
  final String currency;
  final DateTime timestamp;
  final TransactionStatus status;
  final String? serviceName;
  final String? doctorName;
  final double fees;
  final double? netAmount;
  final String? referenceNumber;
  final String? paymentMethod;

  const WalletTransaction({
    required this.id,
    required this.title,
    required this.type,
    required this.amount,
    this.currency = 'EGP',
    required this.timestamp,
    required this.status,
    this.serviceName,
    this.doctorName,
    this.fees = 0.0,
    this.netAmount,
    this.referenceNumber,
    this.paymentMethod,
  });

  DateTime get createdAt => timestamp;
  double? get fee => fees;
  double get calculatedNet => netAmount ?? (amount - fees);
}

import '../../domain/entities/wallet_transaction.dart';

/// Translation key describing what a wallet transaction *was*. The backend's
/// ledger projection carries no human-readable title (File 12 Part 50.3), so
/// the label is derived from the type instead of read off the row.
String walletTransactionTypeLabelKey(TransactionType type) => switch (type) {
      TransactionType.deposit => 'wallet.type_top_up',
      TransactionType.payment => 'wallet.type_appointment_payment',
      TransactionType.refund => 'wallet.type_refund',
      TransactionType.withdrawal => 'wallet.type_transfer',
    };

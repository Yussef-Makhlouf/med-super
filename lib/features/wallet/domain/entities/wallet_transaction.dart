/// Mirrors the backend `WalletTransactionType` enum — `TOP_UP`,
/// `APPOINTMENT_PAYMENT`, `REFUND` — except [withdrawal], which has no
/// backend counterpart and only exists for the mock-only bank-transfer flow
/// (see `STATUS.md`).
enum TransactionType { deposit, withdrawal, payment, refund }

/// Mirrors the backend `WalletTransactionStatus` enum. A `TOP_UP` stays
/// [pending] until its funding payment captures; the other types are written
/// [completed] immediately.
enum TransactionStatus { completed, pending, failed }

/// One row of `GET /v1/wallet/transactions` (File 12 Part 50.3) — a ledger
/// projection, not a receipt: the backend carries no title, service name,
/// doctor name, or fee breakdown for a wallet movement.
class WalletTransaction {
  final String id;
  final TransactionType type;
  final double amount;

  /// Not returned per transaction — the wallet itself carries the currency,
  /// and a wallet is single-currency.
  final String currency;
  final DateTime createdAt;
  final TransactionStatus status;

  /// Wallet balance immediately after this transaction settled — null while
  /// a `TOP_UP` is still [TransactionStatus.pending], since nothing has
  /// moved yet.
  final double? resultingBalance;
  final String? paymentIntentId;
  final String? appointmentId;

  const WalletTransaction({
    required this.id,
    required this.type,
    required this.amount,
    this.currency = 'EGP',
    required this.createdAt,
    required this.status,
    this.resultingBalance,
    this.paymentIntentId,
    this.appointmentId,
  });
}

/// One page of `GET /v1/wallet/transactions` — [nextCursor] is null once
/// there's nothing more to load.
class WalletTransactionPage {
  const WalletTransactionPage({required this.items, required this.nextCursor});

  final List<WalletTransaction> items;
  final String? nextCursor;
}

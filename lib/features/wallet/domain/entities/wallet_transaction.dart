/// Mirrors the backend `WalletTransactionType` enum — `TOP_UP`,
/// `APPOINTMENT_PAYMENT`, `REFUND` — except [withdrawal], which has no
/// backend counterpart and only exists for the mock-only bank-transfer flow
/// (see `STATUS.md`).
enum TransactionType { deposit, withdrawal, payment, refund }

/// Mirrors the backend `WalletTransactionStatus` enum. A `TOP_UP` stays
/// [pending] until its funding payment captures; the other types are written
/// [completed] immediately.
enum TransactionStatus { completed, pending, failed }

/// Who cancelled the appointment this `REFUND` transaction reverses.
enum RefundCancelledBy { patient, doctor }

/// One row of `GET /v1/wallet/transactions` (File 12 Part 50.3) — a ledger
/// projection, not a receipt: the backend carries no title or fee
/// breakdown for a wallet movement, but does now cross-reference the
/// appointment for a doctor name and, on a `REFUND` row, who cancelled.
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

  /// The doctor [appointmentId] was with — `null` when this transaction has
  /// no linked appointment (e.g. a `TOP_UP`).
  final String? doctorName;

  /// Set only on a `REFUND` row whose appointment was cancelled.
  final RefundCancelledBy? cancelledBy;

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
    this.doctorName,
    this.cancelledBy,
  });
}

/// One page of `GET /v1/wallet/transactions` — [nextCursor] is null once
/// there's nothing more to load.
class WalletTransactionPage {
  const WalletTransactionPage({required this.items, required this.nextCursor});

  final List<WalletTransaction> items;
  final String? nextCursor;
}

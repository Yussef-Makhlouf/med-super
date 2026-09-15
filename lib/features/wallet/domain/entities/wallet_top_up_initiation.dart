/// Result of `POST /v1/wallet/top-up` (File 12 Part 50.3).
///
/// Top-up is **not** a synchronous deposit: this call only creates a
/// `PENDING` `WalletTransaction` plus a `CREATED` payment intent and hands
/// back a Paymob checkout URL. The balance moves when — and only when — the
/// capture webhook lands (`ProcessWalletTopUpUseCase`), so nothing here
/// should be treated as "money added".
class WalletTopUpInitiation {
  const WalletTopUpInitiation({
    required this.walletTransactionId,
    required this.paymentIntentId,
    required this.redirectUrl,
  });

  final String walletTransactionId;
  final String paymentIntentId;
  final String redirectUrl;
}

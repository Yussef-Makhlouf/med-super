/// `GET /v1/wallet` (File 12 Part 50.3). A user who has never topped up has
/// no wallet row yet — the backend reports that as a zero balance with an
/// empty [walletId] rather than a 404.
class WalletBalance {
  final String walletId;
  final double availableBalance;
  final String currency;

  const WalletBalance({
    required this.walletId,
    required this.availableBalance,
    this.currency = 'EGP',
  });

  String get formattedBalance => '${availableBalance.toStringAsFixed(2)} $currency';
}

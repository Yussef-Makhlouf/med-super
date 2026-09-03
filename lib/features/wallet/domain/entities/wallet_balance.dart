class WalletBalance {
  final double availableBalance;
  final double pendingBalance;
  final String currency;

  const WalletBalance({
    required this.availableBalance,
    this.pendingBalance = 0.0,
    this.currency = 'EGP',
  });

  String get formattedBalance => '${availableBalance.toStringAsFixed(2)} $currency';
}

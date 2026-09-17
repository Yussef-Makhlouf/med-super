import 'package:med_super/features/wallet/domain/entities/wallet_balance.dart';

/// Parses `GET /v1/wallet`'s `WalletSummary` — camelCase keys, and `balance`
/// arrives as a fixed 2-decimal string (`"2450.00"`), never a JSON number.
class WalletBalanceModel extends WalletBalance {
  const WalletBalanceModel({
    required super.walletId,
    required super.availableBalance,
    super.currency = 'EGP',
  });

  factory WalletBalanceModel.fromJson(Map<String, dynamic> json) {
    return WalletBalanceModel(
      walletId: json['walletId'] as String? ?? '',
      availableBalance:
          double.tryParse(json['balance']?.toString() ?? '') ?? 0.0,
      currency: json['currency'] as String? ?? 'EGP',
    );
  }
}

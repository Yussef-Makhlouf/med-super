import 'package:med_super/features/wallet/domain/entities/wallet_balance.dart';

class WalletBalanceModel extends WalletBalance {
  const WalletBalanceModel({
    required super.availableBalance,
    super.pendingBalance = 0.0,
    super.currency = 'EGP',
  });

  factory WalletBalanceModel.fromJson(Map<String, dynamic> json) {
    return WalletBalanceModel(
      availableBalance: (json['available_balance'] as num? ?? 0).toDouble(),
      pendingBalance: (json['pending_balance'] as num? ?? 0).toDouble(),
      currency: json['currency'] as String? ?? 'EGP',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'available_balance': availableBalance,
      'pending_balance': pendingBalance,
      'currency': currency,
    };
  }
}

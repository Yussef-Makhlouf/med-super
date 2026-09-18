import '../../domain/entities/wallet_top_up_initiation.dart';

class WalletTopUpInitiationModel extends WalletTopUpInitiation {
  const WalletTopUpInitiationModel({
    required super.walletTransactionId,
    required super.paymentIntentId,
    required super.redirectUrl,
  });

  factory WalletTopUpInitiationModel.fromJson(Map<String, dynamic> json) =>
      WalletTopUpInitiationModel(
        walletTransactionId: json['walletTransactionId'] as String? ?? '',
        paymentIntentId: json['paymentIntentId'] as String? ?? '',
        redirectUrl: json['redirectUrl'] as String? ?? '',
      );
}

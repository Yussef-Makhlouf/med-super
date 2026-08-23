import '../../domain/entities/deposit_request.dart';

class DepositRequestModel extends DepositRequest {
  const DepositRequestModel({
    required super.amount,
    required super.paymentMethodId,
  });

  Map<String, dynamic> toJson() {
    return {
      'amount': amount,
      'payment_method_id': paymentMethodId,
    };
  }
}

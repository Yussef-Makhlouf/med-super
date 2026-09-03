class DepositRequest {
  const DepositRequest({
    required this.amount,
    required this.paymentMethodId,
  });

  final double amount;
  final String paymentMethodId;
}

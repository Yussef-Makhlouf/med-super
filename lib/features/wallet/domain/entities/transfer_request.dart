class TransferRequest {
  const TransferRequest({
    required this.amount,
    required this.destinationAccountId,
  });

  final double amount;
  final String destinationAccountId;
}

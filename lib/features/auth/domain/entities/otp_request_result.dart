class OtpRequestResult {
  const OtpRequestResult({
    required this.requestId,
    required this.expiresInSeconds,
  });

  final String requestId;
  final int expiresInSeconds;
}

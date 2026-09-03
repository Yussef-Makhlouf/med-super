/// Estimated (not final) cost breakdown shown on the review step.
///
/// The final price is only settled once the lab reviews the uploaded
/// request image, so every value here is approximate.
class LabCostEstimate {
  const LabCostEstimate({
    required this.testsEstimate,
    required this.homeFee,
    required this.total,
  });

  /// Approximate value of the tests, e.g. `partner.startingPrice`.
  final int testsEstimate;

  /// Home-collection service fee. `0` when the service type is a branch
  /// visit (the row is hidden entirely in that case).
  final int homeFee;

  /// `testsEstimate + homeFee`.
  final int total;
}

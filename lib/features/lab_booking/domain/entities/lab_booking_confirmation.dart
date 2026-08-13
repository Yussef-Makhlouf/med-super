/// Result of confirming a lab booking — drives the success screen (step 3).
///
/// The lab request is only *submitted* here, not confirmed: the final price
/// and any prep instructions (e.g. fasting) are only known once the lab
/// reviews the uploaded request image and responds.
class LabBookingConfirmation {
  const LabBookingConfirmation({
    required this.bookingNumber,
    required this.labName,
    required this.labAddress,
    required this.expectedResponseHours,
  });

  final String bookingNumber;
  final String labName;
  final String labAddress;

  /// Estimated number of hours until the lab reviews the request and
  /// responds. Drives `lab_booking.confirmation.expected_response_value`.
  final int expectedResponseHours;
}

/// Result of confirming a lab booking — drives the success screen (step 3).
class LabBookingConfirmation {
  const LabBookingConfirmation({
    required this.bookingNumber,
    required this.labName,
    required this.labAddress,
    required this.date,
    required this.time,
    this.fastingHours,
  });

  final String bookingNumber;
  final String labName;
  final String labAddress;
  final DateTime date;

  /// Pre-formatted by the backend (e.g. "10:00").
  final String time;

  /// Set only when at least one booked test requires fasting.
  final int? fastingHours;
}

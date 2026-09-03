/// A single bookable time slot within a day's morning/evening period.
class LabTimeSlot {
  const LabTimeSlot({required this.time, required this.isAvailable});

  /// Pre-formatted 24h "HH:mm", displayed as localized 12h AM/PM.
  final String time;
  final bool isAvailable;
}

class TimeSlot {
  const TimeSlot({
    required this.id,
    required this.label,
    required this.available,
  });

  final String id;
  final String label;
  final bool available;
}

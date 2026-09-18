import 'time_slot.dart';

class AvailableDay {
  const AvailableDay({
    required this.id,
    required this.label,
    required this.dayNumber,
    required this.slots,
  });

  final String id;
  final String label;
  final int dayNumber;
  final List<TimeSlot> slots;
}

/// A single 30-minute slot in the provider's daily schedule.
/// Mock-only for now — no backend contract exists yet for this calendar view.
enum ScheduleSlotStatus { available, booked }

class ScheduleSlot {
  const ScheduleSlot({
    required this.id,
    required this.start,
    required this.end,
    required this.status,
    this.patientName,
    this.note,
  });

  final String id;
  final DateTime start;
  final DateTime end;
  final ScheduleSlotStatus status;
  final String? patientName;
  final String? note;

  ScheduleSlot booked({required String patientName, String? note}) =>
      ScheduleSlot(
        id: id,
        start: start,
        end: end,
        status: ScheduleSlotStatus.booked,
        patientName: patientName,
        note: note,
      );

  ScheduleSlot get cleared =>
      ScheduleSlot(id: id, start: start, end: end, status: ScheduleSlotStatus.available);
}

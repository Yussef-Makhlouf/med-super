import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:med_super/features/lab_booking/domain/entities/lab_payment_method.dart';
import 'package:med_super/features/lab_booking/domain/entities/lab_time_slot.dart';

part 'lab_schedule_providers.g.dart';

/// The next 4 selectable days (today included), matching the Figma design.
/// No backend design exists yet for real per-lab availability, so this is
/// generated client-side rather than inventing a network shape for it.
@riverpod
List<DateTime> labAvailableDays(Ref ref) {
  final today = DateTime.now();
  final startOfToday = DateTime(today.year, today.month, today.day);
  return List.generate(4, (i) => startOfToday.add(Duration(days: i)));
}

/// Fixed morning/evening time-slot templates, keyed by period.
/// One evening slot ('16:30') is marked unavailable to match the design's
/// dimmed slot and exercise the "not every slot is bookable" UI state.
@riverpod
Map<String, List<LabTimeSlot>> labTimeSlotsByPeriod(Ref ref) => {
  'morning': const [
    LabTimeSlot(time: '09:00', isAvailable: true),
    LabTimeSlot(time: '09:30', isAvailable: true),
    LabTimeSlot(time: '10:00', isAvailable: true),
    LabTimeSlot(time: '11:00', isAvailable: true),
  ],
  'evening': const [
    LabTimeSlot(time: '16:00', isAvailable: true),
    LabTimeSlot(time: '16:30', isAvailable: false),
    LabTimeSlot(time: '17:00', isAvailable: true),
    LabTimeSlot(time: '18:00', isAvailable: true),
  ],
};

/// Selected day for the schedule step — defaults to the last (furthest)
/// available day, matching the Figma default selection.
@riverpod
class SelectedScheduleDay extends _$SelectedScheduleDay {
  @override
  DateTime build() {
    final days = ref.watch(labAvailableDaysProvider);
    return days.last;
  }

  void select(DateTime day) => state = day;
}

/// Selected time slot — required before confirming; null until the user
/// (or the design's own pre-selected default) picks one.
@riverpod
class SelectedTimeSlot extends _$SelectedTimeSlot {
  @override
  String? build() => '09:30';

  void select(String? time) => state = time;
}

/// Selected payment method — credit card pre-selected, matching Figma.
@riverpod
class SelectedPaymentMethod extends _$SelectedPaymentMethod {
  @override
  LabPaymentMethod build() => LabPaymentMethod.creditCard;

  void select(LabPaymentMethod method) => state = method;
}

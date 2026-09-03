import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:med_super/features/provider_dashboard/domain/entities/schedule_slot.dart';

const _mockPatientNames = [
  'أحمد محمود',
  'سارة علي',
  'محمد إبراهيم',
  'منى حسن',
  'يوسف كريم',
  'هبة الله',
  'عمر خالد',
  'ندى سامي',
];

DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

/// Deterministic mock generator — the same calendar day always produces the
/// same base slots, so re-navigating away and back doesn't reshuffle data
/// that isn't overridden by [ScheduleOverridesNotifier].
List<ScheduleSlot> generateBaseSlotsForDate(DateTime date) {
  final day = dateOnly(date);
  // Friday is the clinic's weekly day off — mock only, not a real setting.
  if (day.weekday == DateTime.friday) return const [];

  final seed = day.year * 10000 + day.month * 100 + day.day;
  final random = Random(seed);
  final now = DateTime.now();

  final slots = <ScheduleSlot>[];
  var hour = 9;
  var minute = 0;
  while (hour < 17) {
    final start = DateTime(day.year, day.month, day.day, hour, minute);
    final isPast = start.isBefore(now);
    final roll = random.nextDouble();
    final isBooked = isPast ? roll < 0.6 : roll < 0.35;
    slots.add(
      ScheduleSlot(
        id: '${day.toIso8601String()}_${hour}_$minute',
        start: start,
        end: start.add(const Duration(minutes: 30)),
        status: isBooked ? ScheduleSlotStatus.booked : ScheduleSlotStatus.available,
        patientName: isBooked
            ? _mockPatientNames[random.nextInt(_mockPatientNames.length)]
            : null,
      ),
    );
    minute += 30;
    if (minute == 60) {
      minute = 0;
      hour++;
    }
  }
  return slots;
}

/// User-made changes (book/cancel) layered on top of [generateBaseSlotsForDate].
/// Kept separate from the generator so navigating between days never loses
/// edits and never regenerates data that was already shown.
class ScheduleOverridesNotifier extends Notifier<Map<String, ScheduleSlot>> {
  @override
  Map<String, ScheduleSlot> build() => const {};

  void book(ScheduleSlot slot, {required String patientName, String? note}) {
    state = {...state, slot.id: slot.booked(patientName: patientName, note: note)};
  }

  void cancel(ScheduleSlot slot) {
    state = {...state, slot.id: slot.cleared};
  }
}

final scheduleOverridesProvider =
    NotifierProvider<ScheduleOverridesNotifier, Map<String, ScheduleSlot>>(
      ScheduleOverridesNotifier.new,
    );

/// Slots for one calendar day, generated data merged with any overrides.
final scheduleSlotsForDateProvider = Provider.family<List<ScheduleSlot>, DateTime>((
  ref,
  date,
) {
  final overrides = ref.watch(scheduleOverridesProvider);
  final base = generateBaseSlotsForDate(date);
  return [for (final slot in base) overrides[slot.id] ?? slot];
});

/// Currently selected day in the provider home calendar.
class SelectedCalendarDateNotifier extends Notifier<DateTime> {
  @override
  DateTime build() => dateOnly(DateTime.now());

  void select(DateTime date) => state = dateOnly(date);
}

final selectedCalendarDateProvider =
    NotifierProvider<SelectedCalendarDateNotifier, DateTime>(
      SelectedCalendarDateNotifier.new,
    );

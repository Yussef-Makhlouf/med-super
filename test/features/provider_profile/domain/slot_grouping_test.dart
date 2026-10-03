import 'package:flutter_test/flutter_test.dart';
import 'package:med_super/features/provider_profile/domain/entities/doctor_slot.dart';
import 'package:med_super/features/provider_profile/domain/utils/slot_grouping.dart';

DoctorSlot _slot(String id, String startUtcIso) {
  final start = DateTime.parse(startUtcIso);
  return DoctorSlot(
    slotId: id,
    startAtUtc: start,
    endAtUtc: start.add(const Duration(minutes: 30)),
  );
}

void main() {
  // Expected wall-clock values match the backend's own conversion (luxon,
  // ICU tzdata): Egypt observes DST again since 2023, +03:00 from the last
  // Friday of April to the last Thursday of October, +02:00 otherwise.
  group('groupSlotsIntoAvailableDays in Africa/Cairo', () {
    test('summer (EEST, +03:00): 07:00Z is 10:00 in the clinic', () {
      final days = groupSlotsIntoAvailableDays(
        [_slot('s1', '2026-10-03T07:00:00Z')],
        ianaTimezone: 'Africa/Cairo',
        nowUtc: DateTime.utc(2026, 10, 1, 9),
      );

      expect(days.single.id, '2026-10-03');
      expect(days.single.slots.single.label, '10:00 ص');
      expect(days.single.slots.single.id, 's1');
    });

    test('winter (EET, +02:00): 07:00Z is 09:00 in the clinic', () {
      final days = groupSlotsIntoAvailableDays(
        [_slot('s1', '2026-01-15T07:00:00Z')],
        ianaTimezone: 'Africa/Cairo',
        nowUtc: DateTime.utc(2026, 1, 14, 9),
      );

      expect(days.single.slots.single.label, '09:00 ص');
    });

    test('autumn transition: the last summer hour and the first winter hour', () {
      // DST ends at 2026-10-30T00:00 local (+03) = 2026-10-29T21:00Z.
      final days = groupSlotsIntoAvailableDays(
        [
          _slot('before', '2026-10-29T20:30:00Z'),
          _slot('after', '2026-10-29T21:30:00Z'),
        ],
        ianaTimezone: 'Africa/Cairo',
        nowUtc: DateTime.utc(2026, 10, 20),
      );

      expect(days.map((d) => d.id), ['2026-10-29']);
      expect(days.single.slots.map((s) => s.label), ['11:30 م', '11:30 م']);
      expect(days.single.slots.map((s) => s.id), ['before', 'after']);
    });

    test('spring transition: 21:59Z is still 23:59, 22:00Z is already 01:00 next day', () {
      final days = groupSlotsIntoAvailableDays(
        [
          _slot('a', '2026-04-23T21:59:00Z'),
          _slot('b', '2026-04-23T22:00:00Z'),
        ],
        ianaTimezone: 'Africa/Cairo',
        nowUtc: DateTime.utc(2026, 4, 20),
      );

      expect(days.map((d) => d.id), ['2026-04-23', '2026-04-24']);
      expect(days[0].slots.single.label, '11:59 م');
      expect(days[1].slots.single.label, '01:00 ص');
    });

    test('day boundary: 21:30Z is already tomorrow in a Cairo summer', () {
      final days = groupSlotsIntoAvailableDays(
        [_slot('late', '2026-10-03T21:30:00Z')],
        ianaTimezone: 'Africa/Cairo',
        nowUtc: DateTime.utc(2026, 10, 3, 10),
      );

      expect(days.single.id, '2026-10-04');
      expect(days.single.label, 'غداً');
      expect(days.single.dayNumber, 4);
      expect(days.single.slots.single.label, '12:30 ص');
    });

    test('"today" is decided in clinic time, not UTC', () {
      // 22:30Z on the 3rd is 01:30 on the 4th in Cairo, so a 09:00 slot on
      // the 4th is "today" for the clinic.
      final days = groupSlotsIntoAvailableDays(
        [_slot('s', '2026-10-04T06:00:00Z')],
        ianaTimezone: 'Africa/Cairo',
        nowUtc: DateTime.utc(2026, 10, 3, 22, 30),
      );

      expect(days.single.label, 'اليوم');
    });
  });

  group('unknown or missing timezone', () {
    test('an unrecognised zone is shown as UTC, explicitly labelled', () {
      final days = groupSlotsIntoAvailableDays(
        [_slot('s', '2026-10-03T07:00:00Z')],
        ianaTimezone: 'Mars/Olympus_Mons',
        nowUtc: DateTime.utc(2026, 10, 1),
      );

      expect(days.single.slots.single.label, '07:00 ص UTC');
    });

    test('a null zone is shown as UTC, explicitly labelled', () {
      final days = groupSlotsIntoAvailableDays(
        [_slot('s', '2026-10-03T13:15:00Z')],
        nowUtc: DateTime.utc(2026, 10, 1),
      );

      expect(days.single.slots.single.label, '01:15 م UTC');
    });
  });

  test('another real IANA zone uses its own rules, not Cairo\'s', () {
    final days = groupSlotsIntoAvailableDays(
      [_slot('s', '2026-10-03T07:00:00Z')],
      ianaTimezone: 'Asia/Riyadh',
      nowUtc: DateTime.utc(2026, 10, 1),
    );

    expect(days.single.slots.single.label, '10:00 ص');
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:med_super/features/provider_dashboard/domain/entities/doctor_schedule_template.dart';
import 'package:med_super/features/provider_dashboard/domain/schedule_day_lookup.dart';

DoctorScheduleTemplate _template({
  required String id,
  required int weekday,
  String affiliationId = 'aff-1',
  String branchId = 'branch-1',
}) => DoctorScheduleTemplate(
  id: id,
  doctorClinicAffiliationId: affiliationId,
  clinicBranchId: branchId,
  clinicId: 'clinic-1',
  clinicName: 'Test Clinic',
  ianaTimezone: 'Africa/Cairo',
  weekday: weekday,
  startTime: '09:00',
  endTime: '17:00',
  slotDurationMinutes: 30,
  bufferMinutes: 0,
  version: 1,
  createdAt: DateTime.utc(2026, 1, 1),
  updatedAt: DateTime.utc(2026, 1, 1),
);

void main() {
  group('scheduleTemplatesForDate', () {
    test('returns the template matching the date\'s ISO weekday', () {
      // 2026-09-07 is a Monday (weekday == 1).
      final monday = _template(id: 't-mon', weekday: 1);
      final tuesday = _template(id: 't-tue', weekday: 2);

      final result = scheduleTemplatesForDate(
        [monday, tuesday],
        DateTime(2026, 9, 7),
      );

      expect(result, [monday]);
    });

    test('returns every matching template across multiple affiliations', () {
      final mondayBranchA = _template(
        id: 't-a',
        weekday: 1,
        affiliationId: 'aff-a',
        branchId: 'branch-a',
      );
      final mondayBranchB = _template(
        id: 't-b',
        weekday: 1,
        affiliationId: 'aff-b',
        branchId: 'branch-b',
      );

      final result = scheduleTemplatesForDate(
        [mondayBranchA, mondayBranchB],
        DateTime(2026, 9, 7),
      );

      expect(result, containsAll([mondayBranchA, mondayBranchB]));
      expect(result.length, 2);
    });

    test('returns an empty list when no template covers that weekday (day off)', () {
      final tuesday = _template(id: 't-tue', weekday: 2);

      final result = scheduleTemplatesForDate([tuesday], DateTime(2026, 9, 7));

      expect(result, isEmpty);
    });

    test('returns an empty list for an empty template set', () {
      final result = scheduleTemplatesForDate([], DateTime(2026, 9, 7));
      expect(result, isEmpty);
    });

    test('Sunday maps to ISO weekday 7', () {
      // 2026-09-13 is a Sunday.
      final sunday = _template(id: 't-sun', weekday: 7);

      final result = scheduleTemplatesForDate([sunday], DateTime(2026, 9, 13));

      expect(result, [sunday]);
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:med_super/features/provider_registration/domain/entities/clinic_working_day.dart';

void main() {
  group('ClinicTime', () {
    test('stores hour and minute', () {
      const t = ClinicTime(hour: 9, minute: 30);
      expect(t.hour, 9);
      expect(t.minute, 30);
    });
  });

  group('Weekday', () {
    test('has exactly 7 values starting with saturday', () {
      expect(Weekday.values.length, 7);
      expect(Weekday.values.first, Weekday.saturday);
      expect(Weekday.values.last, Weekday.friday);
    });
  });

  group('ClinicWorkingDay.copyWith', () {
    const base = ClinicWorkingDay(
      day: Weekday.monday,
      isEnabled: false,
      from: ClinicTime(hour: 9, minute: 0),
      to: ClinicTime(hour: 17, minute: 0),
    );

    test('day is never changed by copyWith', () {
      final copy = base.copyWith(isEnabled: true);
      expect(copy.day, Weekday.monday);
    });

    test('with no arguments, returns equivalent values', () {
      final copy = base.copyWith();
      expect(copy.day, base.day);
      expect(copy.isEnabled, base.isEnabled);
      expect(copy.from, base.from);
      expect(copy.to, base.to);
    });

    test('isEnabled overrides when provided', () {
      final copy = base.copyWith(isEnabled: true);
      expect(copy.isEnabled, isTrue);
    });

    test('from/to override when provided', () {
      final copy = base.copyWith(
        from: const ClinicTime(hour: 10, minute: 15),
        to: const ClinicTime(hour: 18, minute: 45),
      );
      expect(copy.from, const ClinicTime(hour: 10, minute: 15));
      expect(copy.to, const ClinicTime(hour: 18, minute: 45));
    });

    test('from/to keep previous value when omitted and not cleared', () {
      final copy = base.copyWith(isEnabled: true);
      expect(copy.from, base.from);
      expect(copy.to, base.to);
    });

    test('clearFrom=true nulls out from even if from is also passed', () {
      final copy = base.copyWith(
        clearFrom: true,
        from: const ClinicTime(hour: 1, minute: 1),
      );
      expect(copy.from, isNull);
    });

    test('clearTo=true nulls out to even if to is also passed', () {
      final copy = base.copyWith(
        clearTo: true,
        to: const ClinicTime(hour: 1, minute: 1),
      );
      expect(copy.to, isNull);
    });

    test('clearFrom/clearTo default to false and leave values untouched', () {
      final copy = base.copyWith();
      expect(copy.from, isNotNull);
      expect(copy.to, isNotNull);
    });

    test('clearFrom on a day with null from stays null', () {
      const emptyDay = ClinicWorkingDay(day: Weekday.friday, isEnabled: false);
      final copy = emptyDay.copyWith(clearFrom: true, clearTo: true);
      expect(copy.from, isNull);
      expect(copy.to, isNull);
    });

    test('can clear from and to simultaneously', () {
      final copy = base.copyWith(clearFrom: true, clearTo: true);
      expect(copy.from, isNull);
      expect(copy.to, isNull);
      expect(copy.isEnabled, base.isEnabled);
    });
  });
}

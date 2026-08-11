import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:med_super/features/provider_registration/domain/entities/clinic_working_day.dart';
import 'package:med_super/features/provider_registration/presentation/widgets/working_hours_day_row.dart';

import '../../../../helpers/pump_app.dart';

void main() {
  testWidgets('shows placeholder times when day has no from/to', (
    tester,
  ) async {
    const day = ClinicWorkingDay(day: Weekday.monday, isEnabled: false);

    await pumpPlainApp(
      tester,
      WorkingHoursDayRow(
        day: day,
        onToggle: (_) {},
        onPickFrom: () {},
        onPickTo: () {},
      ),
    );

    expect(find.text('--:--'), findsNWidgets(2));
    expect(tester.takeException(), isNull);
  });

  testWidgets('formats from/to as 12-hour clock with AM/PM', (tester) async {
    const day = ClinicWorkingDay(
      day: Weekday.sunday,
      isEnabled: true,
      from: ClinicTime(hour: 9, minute: 5),
      to: ClinicTime(hour: 17, minute: 30),
    );

    await pumpPlainApp(
      tester,
      WorkingHoursDayRow(
        day: day,
        onToggle: (_) {},
        onPickFrom: () {},
        onPickTo: () {},
      ),
    );

    expect(find.text('09:05 AM'), findsOneWidget);
    expect(find.text('05:30 PM'), findsOneWidget);
  });

  testWidgets('formats midnight (hour 0) as 12:xx AM', (tester) async {
    const day = ClinicWorkingDay(
      day: Weekday.tuesday,
      isEnabled: true,
      from: ClinicTime(hour: 0, minute: 0),
      to: ClinicTime(hour: 12, minute: 0),
    );

    await pumpPlainApp(
      tester,
      WorkingHoursDayRow(
        day: day,
        onToggle: (_) {},
        onPickFrom: () {},
        onPickTo: () {},
      ),
    );

    expect(find.text('12:00 AM'), findsOneWidget);
    expect(find.text('12:00 PM'), findsOneWidget);
  });

  testWidgets('checkbox reflects isEnabled and invokes onToggle', (
    tester,
  ) async {
    bool? toggledTo;
    const day = ClinicWorkingDay(day: Weekday.friday, isEnabled: false);

    await pumpPlainApp(
      tester,
      WorkingHoursDayRow(
        day: day,
        onToggle: (v) => toggledTo = v,
        onPickFrom: () {},
        onPickTo: () {},
      ),
    );

    final checkbox = tester.widget<Checkbox>(find.byType(Checkbox));
    expect(checkbox.value, isFalse);

    await tester.tap(find.byType(Checkbox));
    await tester.pump();

    expect(toggledTo, isTrue);
  });

  testWidgets('tapping time fields invokes onPickFrom/onPickTo when enabled', (
    tester,
  ) async {
    var fromTapped = false;
    var toTapped = false;
    const day = ClinicWorkingDay(day: Weekday.wednesday, isEnabled: true);

    await pumpPlainApp(
      tester,
      WorkingHoursDayRow(
        day: day,
        onToggle: (_) {},
        onPickFrom: () => fromTapped = true,
        onPickTo: () => toTapped = true,
      ),
    );

    final inkWells = find.byType(InkWell);
    await tester.tap(inkWells.first);
    await tester.pump();
    await tester.tap(inkWells.last);
    await tester.pump();

    expect(fromTapped, isTrue);
    expect(toTapped, isTrue);
  });

  testWidgets(
    'time fields are disabled (no tap callback) when day is disabled',
    (tester) async {
      var fromTapped = false;
      const day = ClinicWorkingDay(day: Weekday.thursday, isEnabled: false);

      await pumpPlainApp(
        tester,
        WorkingHoursDayRow(
          day: day,
          onToggle: (_) {},
          onPickFrom: () => fromTapped = true,
          onPickTo: () {},
        ),
      );

      final inkWell = tester.widget<InkWell>(find.byType(InkWell).first);
      expect(inkWell.onTap, isNull);
      expect(fromTapped, isFalse);
    },
  );

  testWidgets('does not overflow on a narrow 320px width', (tester) async {
    const day = ClinicWorkingDay(
      day: Weekday.saturday,
      isEnabled: true,
      from: ClinicTime(hour: 9, minute: 0),
      to: ClinicTime(hour: 17, minute: 0),
    );

    await pumpPlainApp(
      tester,
      WorkingHoursDayRow(
        day: day,
        onToggle: (_) {},
        onPickFrom: () {},
        onPickTo: () {},
      ),
      surfaceSize: const Size(320, 400),
    );

    expect(tester.takeException(), isNull);
  });
}

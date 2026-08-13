import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:med_super/features/lab_booking/presentation/widgets/schedule_day_chip_bar.dart';

import '../../../../helpers/pump_localized_widget.dart';

void main() {
  final days = List.generate(4, (i) => DateTime(2026, 3, 20 + i));

  testWidgets('renders one card per day, showing its day-of-month', (
    tester,
  ) async {
    await pumpLocalizedWidget(
      tester,
      ScheduleDayChipBar(
        days: days,
        selectedDay: days.first,
        onSelected: (_) {},
      ),
    );

    for (final day in days) {
      expect(find.text('${day.day}'), findsOneWidget);
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('tapping a day invokes onSelected with that day', (tester) async {
    DateTime? tapped;
    await pumpLocalizedWidget(
      tester,
      ScheduleDayChipBar(
        days: days,
        selectedDay: days.first,
        onSelected: (day) => tapped = day,
      ),
    );

    await tester.tap(find.text('${days[2].day}'));
    await tester.pumpAndSettle();

    expect(tapped, days[2]);
  });

  testWidgets('does not overflow on a narrow 320px width', (tester) async {
    tester.view.physicalSize = const Size(320, 600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await pumpLocalizedWidget(
      tester,
      ScheduleDayChipBar(
        days: days,
        selectedDay: days.first,
        onSelected: (_) {},
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
  });
}

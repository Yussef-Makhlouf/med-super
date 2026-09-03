import 'package:flutter_test/flutter_test.dart';
import 'package:med_super/features/lab_booking/domain/entities/lab_time_slot.dart';
import 'package:med_super/features/lab_booking/presentation/widgets/time_slot_period_section.dart';

import '../../../../helpers/pump_localized_widget.dart';

void main() {
  const slots = [
    LabTimeSlot(time: '09:00', isAvailable: true),
    LabTimeSlot(time: '09:30', isAvailable: true),
    LabTimeSlot(time: '16:30', isAvailable: false),
  ];

  testWidgets('renders the period label and every slot as 12h time', (
    tester,
  ) async {
    await pumpLocalizedWidget(
      tester,
      TimeSlotPeriodSection(
        periodLabel: 'Morning',
        slots: slots,
        selectedTime: '09:30',
        onSelected: (_) {},
      ),
    );

    expect(find.text('Morning'), findsOneWidget);
    expect(find.textContaining('9:00'), findsOneWidget);
    expect(find.textContaining('9:30'), findsOneWidget);
    expect(find.textContaining('4:30'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('tapping an available slot invokes onSelected with its time', (
    tester,
  ) async {
    String? tapped;
    await pumpLocalizedWidget(
      tester,
      TimeSlotPeriodSection(
        periodLabel: 'Morning',
        slots: slots,
        selectedTime: null,
        onSelected: (time) => tapped = time,
      ),
    );

    await tester.tap(find.textContaining('9:00'));
    await tester.pumpAndSettle();

    expect(tapped, '09:00');
  });

  testWidgets('tapping an unavailable slot does nothing', (tester) async {
    var called = false;
    await pumpLocalizedWidget(
      tester,
      TimeSlotPeriodSection(
        periodLabel: 'Evening',
        slots: slots,
        selectedTime: null,
        onSelected: (_) => called = true,
      ),
    );

    await tester.tap(find.textContaining('4:30'));
    await tester.pumpAndSettle();

    expect(called, isFalse);
    expect(tester.takeException(), isNull);
  });
}

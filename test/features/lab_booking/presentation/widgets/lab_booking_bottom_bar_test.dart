import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:med_super/features/lab_booking/presentation/widgets/lab_booking_bottom_bar.dart';

import '../../../../helpers/pump_localized_widget.dart';

void main() {
  testWidgets('renders total price and enabled CTA when onContinue is set', (
    tester,
  ) async {
    var tapped = false;
    await pumpLocalizedWidget(
      tester,
      LabBookingBottomBar(
        selectedCount: 2,
        totalPrice: 350,
        onContinue: () => tapped = true,
      ),
    );

    expect(find.text('350 ج.م'), findsOneWidget);
    final button = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(button.onPressed, isNotNull);

    await tester.tap(find.byType(FilledButton));
    await tester.pump();
    expect(tapped, isTrue);
  });

  testWidgets('CTA is disabled when onContinue is null', (tester) async {
    await pumpLocalizedWidget(
      tester,
      const LabBookingBottomBar(
        selectedCount: 0,
        totalPrice: 0,
        onContinue: null,
      ),
    );

    final button = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(button.onPressed, isNull);
    expect(find.text('0 ج.م'), findsOneWidget);
  });
}

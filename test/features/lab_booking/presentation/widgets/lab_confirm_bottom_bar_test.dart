import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:med_super/features/lab_booking/presentation/widgets/lab_confirm_bottom_bar.dart';

import '../../../../helpers/pump_localized_widget.dart';

void main() {
  testWidgets('renders total price and an enabled CTA when not submitting', (
    tester,
  ) async {
    var tapped = false;
    await pumpLocalizedWidget(
      tester,
      LabConfirmBottomBar(
        totalPrice: 620,
        isSubmitting: false,
        onContinue: () => tapped = true,
      ),
    );

    expect(find.text('620 ج.م'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    final button = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(button.onPressed, isNotNull);

    await tester.tap(find.byType(FilledButton));
    await tester.pump();
    expect(tapped, isTrue);
  });

  testWidgets('shows a spinner and disables the CTA while submitting', (
    tester,
  ) async {
    await pumpLocalizedWidget(
      tester,
      LabConfirmBottomBar(
        totalPrice: 620,
        isSubmitting: true,
        onContinue: () {},
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    final button = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(button.onPressed, isNull);
  });
}

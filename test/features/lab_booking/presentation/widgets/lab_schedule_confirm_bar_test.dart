import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:med_super/features/lab_booking/presentation/widgets/lab_schedule_confirm_bar.dart';

import '../../../../helpers/pump_localized_widget.dart';

void main() {
  testWidgets('renders an enabled confirm button when not submitting', (
    tester,
  ) async {
    var tapped = false;
    await pumpLocalizedWidget(
      tester,
      LabScheduleConfirmBar(
        totalPrice: 150,
        isSubmitting: false,
        onConfirm: () => tapped = true,
      ),
    );

    final button = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(button.onPressed, isNotNull);
    button.onPressed!();
    expect(tapped, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('disables the button and shows a spinner while submitting', (
    tester,
  ) async {
    await pumpLocalizedWidget(
      tester,
      const LabScheduleConfirmBar(
        totalPrice: 150,
        isSubmitting: true,
        onConfirm: null,
      ),
    );

    final button = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(button.onPressed, isNull);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the button is disabled when onConfirm is null (nothing '
      'required selected yet)', (tester) async {
    await pumpLocalizedWidget(
      tester,
      const LabScheduleConfirmBar(
        totalPrice: 0,
        isSubmitting: false,
        onConfirm: null,
      ),
    );

    final button = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(button.onPressed, isNull);
    expect(tester.takeException(), isNull);
  });
}

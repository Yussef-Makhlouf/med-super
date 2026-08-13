import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:med_super/features/lab_booking/presentation/widgets/lab_confirm_bottom_bar.dart';

import '../../../../helpers/pump_localized_widget.dart';

void main() {
  testWidgets(
    'renders a single full-width, enabled CTA when not submitting — no '
    'price shown at this step',
    (tester) async {
      var tapped = false;
      await pumpLocalizedWidget(
        tester,
        LabConfirmBottomBar(
          isSubmitting: false,
          onContinue: () => tapped = true,
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsNothing);
      final button = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(button.onPressed, isNotNull);

      // The CTA must show the real localized copy (not a hardcoded English
      // placeholder) so a wrong/missing translation key is caught here.
      expect(
        find.text('lab_booking.select_lab.continue_cta'.tr()),
        findsOneWidget,
      );

      // No price/total text of any kind belongs in this bar per the
      // mockup — pricing is unknown until the lab reviews the request.
      expect(find.textContaining('ج.م'), findsNothing);

      await tester.tap(find.byType(FilledButton));
      await tester.pump();
      expect(tapped, isTrue);
    },
  );

  testWidgets('shows a spinner and disables the CTA while submitting', (
    tester,
  ) async {
    await pumpLocalizedWidget(
      tester,
      LabConfirmBottomBar(isSubmitting: true, onContinue: () {}),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    final button = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(button.onPressed, isNull);
  });
}

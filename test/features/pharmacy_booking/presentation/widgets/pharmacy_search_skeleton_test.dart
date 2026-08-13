import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:med_super/features/pharmacy_booking/presentation/widgets/pharmacy_search_skeleton.dart';

import '../../../../helpers/pump_localized_widget.dart';

void main() {
  testWidgets(
    'renders a pulsing skeleton with a map placeholder and 3 card shapes, '
    'no spinner',
    (tester) async {
      await pumpLocalizedWidget(tester, const PharmacySearchSkeleton());

      // Skeleton is a structural stand-in, not a spinner.
      expect(find.byType(CircularProgressIndicator), findsNothing);

      // 3 circular logo placeholders (one per skeleton card).
      final circles = tester
          .widgetList<Container>(find.byType(Container))
          .where((c) => c.decoration is BoxDecoration)
          .where(
            (c) => (c.decoration! as BoxDecoration).shape == BoxShape.circle,
          )
          .toList();
      expect(circles, hasLength(3));

      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('opacity pulses over time via its AnimationController', (
    tester,
  ) async {
    await pumpLocalizedWidget(tester, const PharmacySearchSkeleton());

    final initial = tester.widget<Opacity>(find.byType(Opacity)).opacity;

    await tester.pump(const Duration(milliseconds: 450));

    final later = tester.widget<Opacity>(find.byType(Opacity)).opacity;

    expect(later, isNot(initial));
    expect(tester.takeException(), isNull);
  });
}

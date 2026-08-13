import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:med_super/features/lab_booking/domain/entities/lab_cost_estimate.dart';
import 'package:med_super/features/lab_booking/presentation/widgets/lab_cost_estimate_section.dart';

import '../../../../helpers/pump_localized_widget.dart';

void main() {
  testWidgets(
    'shows the tests-estimate row, total and disclaimer, but hides the '
    'home-fee row when homeFee is 0 (branch visit)',
    (tester) async {
      await pumpLocalizedWidget(
        tester,
        const LabCostEstimateSection(
          estimate: LabCostEstimate(testsEstimate: 300, homeFee: 0, total: 300),
        ),
      );

      expect(find.textContaining('300'), findsWidgets);
      expect(find.byIcon(Icons.info_outline), findsOneWidget);
      // No home-fee row rendered — only one "ج.م" value line for the
      // tests-estimate row plus the bold total, i.e. no extra row in
      // between them for a fee that doesn't apply here.
      expect(find.textContaining('ج.م'), findsNWidgets(2));
      // Real translated copy for every label — asserted via `.tr()` on the
      // actual translation keys (not a hardcoded English/Arabic literal) so
      // a wrong copy string in ar.json/en.json fails this test.
      expect(
        find.text('lab_booking.review.cost_estimate_title'.tr()),
        findsOneWidget,
      );
      expect(
        find.text('lab_booking.review.tests_estimate_label'.tr()),
        findsOneWidget,
      );
      expect(find.text('lab_booking.review.home_fee_label'.tr()), findsNothing);
      expect(
        find.text('lab_booking.review.total_estimate_label'.tr()),
        findsOneWidget,
      );
      expect(
        find.text('lab_booking.review.estimate_disclaimer'.tr()),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('shows the home-fee row and a total equal to tests + fee when '
      'homeFee > 0 (home collection)', (tester) async {
    await pumpLocalizedWidget(
      tester,
      const LabCostEstimateSection(
        estimate: LabCostEstimate(
          testsEstimate: 300,
          homeFee: kLabHomeServiceFeeEgp,
          total: 300 + kLabHomeServiceFeeEgp,
        ),
      ),
    );

    expect(find.textContaining('300'), findsWidgets);
    expect(find.textContaining('$kLabHomeServiceFeeEgp'), findsWidgets);
    expect(
      find.textContaining('${300 + kLabHomeServiceFeeEgp}'),
      findsOneWidget,
    );
    // Tests-estimate row + home-fee row + total = 3 "ج.م" value lines.
    expect(find.textContaining('ج.م'), findsNWidgets(3));
    expect(find.text('lab_booking.review.home_fee_label'.tr()), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

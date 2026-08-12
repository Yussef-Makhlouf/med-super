import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:med_super/features/lab_booking/domain/entities/lab_test.dart';
import 'package:med_super/features/lab_booking/presentation/widgets/selectable_test_card.dart';

import '../../../../helpers/pump_localized_widget.dart';

void main() {
  const simpleTest = LabTest(
    id: 't1',
    name: 'CBC',
    price: 150,
    currency: 'EGP',
    isPackage: false,
    requiresFasting: false,
    categoryId: 'blood',
  );

  const packageTest = LabTest(
    id: 'p1',
    name: 'Full Body Package',
    price: 900,
    currency: 'EGP',
    isPackage: true,
    requiresFasting: true,
    categoryId: 'packages',
    includesCount: 12,
    fastingHours: 8,
    resultHours: 24,
  );

  testWidgets('renders a non-package test with add icon when not selected', (
    tester,
  ) async {
    await pumpLocalizedWidget(
      tester,
      SelectableTestCard(
        test: simpleTest,
        isSelected: false,
        onToggle: () {},
      ),
    );

    expect(find.text('CBC'), findsOneWidget);
    expect(find.text('150 ج.م'), findsOneWidget);
    expect(find.byIcon(Icons.add), findsOneWidget);
    expect(find.byIcon(Icons.remove), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('renders a package test with remove icon when selected', (
    tester,
  ) async {
    await pumpLocalizedWidget(
      tester,
      SelectableTestCard(
        test: packageTest,
        isSelected: true,
        onToggle: () {},
      ),
    );

    expect(find.text('Full Body Package'), findsOneWidget);
    expect(find.byIcon(Icons.remove), findsOneWidget);
    expect(find.byIcon(Icons.science_outlined), findsOneWidget);
    expect(find.byIcon(Icons.no_food_outlined), findsOneWidget);
    expect(find.byIcon(Icons.timer_outlined), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('tapping the card invokes onToggle', (tester) async {
    var toggled = false;
    await pumpLocalizedWidget(
      tester,
      SelectableTestCard(
        test: simpleTest,
        isSelected: false,
        onToggle: () => toggled = true,
      ),
    );

    await tester.tap(find.byType(InkWell));
    await tester.pump();

    expect(toggled, isTrue);
  });
}

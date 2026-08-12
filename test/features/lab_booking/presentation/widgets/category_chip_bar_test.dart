import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:med_super/features/lab_booking/domain/entities/lab_test_category.dart';
import 'package:med_super/features/lab_booking/presentation/widgets/category_chip_bar.dart';

import '../../../../helpers/pump_localized_widget.dart';

void main() {
  const categories = [
    LabTestCategory(id: 'packages', labelKey: 'lab_booking.categories.packages'),
    LabTestCategory(id: 'vitamins', labelKey: 'lab_booking.categories.vitamins'),
  ];

  testWidgets('renders a chip per category and highlights the active one', (
    tester,
  ) async {
    await pumpLocalizedWidget(
      tester,
      CategoryChipBar(
        categories: categories,
        activeId: 'packages',
        onSelected: (_) {},
      ),
    );

    expect(find.byType(ChoiceChip), findsNWidgets(2));
    final chips = tester.widgetList<ChoiceChip>(find.byType(ChoiceChip)).toList();
    expect(chips[0].selected, isTrue);
    expect(chips[1].selected, isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets('tapping the active chip deselects it (passes null)', (
    tester,
  ) async {
    String? received = 'unset';
    await pumpLocalizedWidget(
      tester,
      CategoryChipBar(
        categories: categories,
        activeId: 'packages',
        onSelected: (id) => received = id,
      ),
    );

    await tester.tap(find.byType(ChoiceChip).first);
    await tester.pump();

    expect(received, isNull);
  });

  testWidgets('tapping an inactive chip selects its id', (tester) async {
    String? received;
    await pumpLocalizedWidget(
      tester,
      CategoryChipBar(
        categories: categories,
        activeId: 'packages',
        onSelected: (id) => received = id,
      ),
    );

    await tester.tap(find.byType(ChoiceChip).last);
    await tester.pump();

    expect(received, 'vitamins');
  });

  testWidgets('renders nothing when categories list is empty', (
    tester,
  ) async {
    await pumpLocalizedWidget(
      tester,
      CategoryChipBar(categories: const [], activeId: null, onSelected: (_) {}),
    );

    expect(find.byType(ChoiceChip), findsNothing);
    expect(tester.takeException(), isNull);
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:med_super/features/lab_booking/domain/entities/lab_sort_option.dart';
import 'package:med_super/features/lab_booking/presentation/widgets/lab_sort_chip_bar.dart';

import '../../../../helpers/pump_localized_widget.dart';

void main() {
  testWidgets('renders one chip per sort option and marks the active one', (
    tester,
  ) async {
    await pumpLocalizedWidget(
      tester,
      LabSortChipBar(selected: LabSortOption.nearest, onSelected: (_) {}),
    );

    expect(find.byType(ChoiceChip), findsNWidgets(3));
    final chips = tester.widgetList<ChoiceChip>(find.byType(ChoiceChip)).toList();
    expect(chips.where((c) => c.selected).length, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('tapping a chip reports its LabSortOption', (tester) async {
    LabSortOption? received;
    await pumpLocalizedWidget(
      tester,
      LabSortChipBar(
        selected: LabSortOption.nearest,
        onSelected: (sort) => received = sort,
      ),
    );

    await tester.tap(find.byType(ChoiceChip).first);
    await tester.pump();

    expect(received, isNotNull);
  });

  testWidgets('selecting ratingDesc marks that chip as selected', (
    tester,
  ) async {
    await pumpLocalizedWidget(
      tester,
      LabSortChipBar(selected: LabSortOption.ratingDesc, onSelected: (_) {}),
    );

    final chips = tester.widgetList<ChoiceChip>(find.byType(ChoiceChip)).toList();
    expect(chips.where((c) => c.selected).length, 1);
  });
}

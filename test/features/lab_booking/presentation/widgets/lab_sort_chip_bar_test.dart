import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:med_super/features/lab_booking/domain/entities/lab_sort_option.dart';
import 'package:med_super/features/lab_booking/presentation/widgets/lab_sort_chip_bar.dart';

import '../../../../helpers/pump_localized_widget.dart';

void main() {
  testWidgets(
    'renders the "مفتوح الآن" filter chip plus one chip per sort option, '
    'and marks the active sort chip',
    (tester) async {
      await pumpLocalizedWidget(
        tester,
        LabSortChipBar(
          selected: LabSortOption.nearest,
          onSelected: (_) {},
          openNowOnly: false,
          onToggleOpenNow: () {},
        ),
      );

      // 1 filter chip ("مفتوح الآن") + 3 sort chips.
      expect(find.byType(ChoiceChip), findsNWidgets(4));
      expect(
        find.text('lab_booking.select_lab.filter_open_now'.tr()),
        findsOneWidget,
      );
      final chips = tester
          .widgetList<ChoiceChip>(find.byType(ChoiceChip))
          .toList();
      // Only the active sort chip is selected — the filter chip isn't.
      expect(chips.where((c) => c.selected).length, 1);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('tapping a sort chip reports its LabSortOption', (tester) async {
    LabSortOption? received;
    await pumpLocalizedWidget(
      tester,
      LabSortChipBar(
        selected: LabSortOption.nearest,
        onSelected: (sort) => received = sort,
        openNowOnly: false,
        onToggleOpenNow: () {},
      ),
    );

    // The filter chip is the first ChoiceChip, so the first *sort* chip is
    // the second one in the row.
    await tester.tap(find.byType(ChoiceChip).at(1));
    await tester.pump();

    expect(received, isNotNull);
  });

  testWidgets('selecting ratingDesc marks that chip as selected', (
    tester,
  ) async {
    await pumpLocalizedWidget(
      tester,
      LabSortChipBar(
        selected: LabSortOption.ratingDesc,
        onSelected: (_) {},
        openNowOnly: false,
        onToggleOpenNow: () {},
      ),
    );

    final chips = tester
        .widgetList<ChoiceChip>(find.byType(ChoiceChip))
        .toList();
    expect(chips.where((c) => c.selected).length, 1);
  });

  testWidgets('renders the filter chip as active when openNowOnly is true', (
    tester,
  ) async {
    await pumpLocalizedWidget(
      tester,
      LabSortChipBar(
        selected: LabSortOption.nearest,
        onSelected: (_) {},
        openNowOnly: true,
        onToggleOpenNow: () {},
      ),
    );

    final filterChip = tester
        .widgetList<ChoiceChip>(find.byType(ChoiceChip))
        .first;
    expect(filterChip.selected, isTrue);
  });

  testWidgets('tapping the filter chip invokes onToggleOpenNow', (
    tester,
  ) async {
    var toggled = false;
    await pumpLocalizedWidget(
      tester,
      LabSortChipBar(
        selected: LabSortOption.nearest,
        onSelected: (_) {},
        openNowOnly: false,
        onToggleOpenNow: () => toggled = true,
      ),
    );

    await tester.tap(find.byType(ChoiceChip).first);
    await tester.pump();

    expect(toggled, isTrue);
  });
}

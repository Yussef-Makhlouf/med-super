import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:med_super/features/pharmacy_booking/domain/entities/pharmacy_sort_option.dart';
import 'package:med_super/features/pharmacy_booking/presentation/widgets/pharmacy_filter_chip_bar.dart';

import '../../../../helpers/pump_localized_widget.dart';

void main() {
  testWidgets('renders exactly 3 chips: open-now, top-rated, nearest', (
    tester,
  ) async {
    await pumpLocalizedWidget(
      tester,
      PharmacyFilterChipBar(
        openNowOnly: false,
        onToggleOpenNow: () {},
        selectedSort: PharmacySortOption.nearest,
        onSelectSort: (_) {},
      ),
    );

    expect(find.byType(ChoiceChip), findsNWidgets(3));
    expect(
      find.text('pharmacy_booking.select_pharmacy.filter_open_now'.tr()),
      findsOneWidget,
    );
    expect(
      find.text('pharmacy_booking.select_pharmacy.filter_top_rated'.tr()),
      findsOneWidget,
    );
    expect(
      find.text('pharmacy_booking.select_pharmacy.filter_nearest'.tr()),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('marks the nearest chip as selected by default', (tester) async {
    await pumpLocalizedWidget(
      tester,
      PharmacyFilterChipBar(
        openNowOnly: false,
        onToggleOpenNow: () {},
        selectedSort: PharmacySortOption.nearest,
        onSelectSort: (_) {},
      ),
    );

    final chips = tester
        .widgetList<ChoiceChip>(find.byType(ChoiceChip))
        .toList();
    // open-now, top-rated, nearest — nearest is the last chip.
    expect(chips[0].selected, isFalse);
    expect(chips[1].selected, isFalse);
    expect(chips[2].selected, isTrue);
  });

  testWidgets('marks the top-rated chip as selected when chosen', (
    tester,
  ) async {
    await pumpLocalizedWidget(
      tester,
      PharmacyFilterChipBar(
        openNowOnly: false,
        onToggleOpenNow: () {},
        selectedSort: PharmacySortOption.topRated,
        onSelectSort: (_) {},
      ),
    );

    final chips = tester
        .widgetList<ChoiceChip>(find.byType(ChoiceChip))
        .toList();
    expect(chips[1].selected, isTrue);
    expect(chips[2].selected, isFalse);
  });

  testWidgets('marks the open-now chip as selected when the filter is on', (
    tester,
  ) async {
    await pumpLocalizedWidget(
      tester,
      PharmacyFilterChipBar(
        openNowOnly: true,
        onToggleOpenNow: () {},
        selectedSort: PharmacySortOption.nearest,
        onSelectSort: (_) {},
      ),
    );

    final chips = tester
        .widgetList<ChoiceChip>(find.byType(ChoiceChip))
        .toList();
    expect(chips[0].selected, isTrue);
  });

  testWidgets('tapping the open-now chip invokes onToggleOpenNow', (
    tester,
  ) async {
    var toggled = false;
    await pumpLocalizedWidget(
      tester,
      PharmacyFilterChipBar(
        openNowOnly: false,
        onToggleOpenNow: () => toggled = true,
        selectedSort: PharmacySortOption.nearest,
        onSelectSort: (_) {},
      ),
    );

    tester.widgetList<ChoiceChip>(find.byType(ChoiceChip)).first.onSelected!(
      true,
    );
    await tester.pump();

    expect(toggled, isTrue);
  });

  testWidgets(
    'tapping the top-rated chip reports PharmacySortOption.topRated',
    (tester) async {
      PharmacySortOption? received;
      await pumpLocalizedWidget(
        tester,
        PharmacyFilterChipBar(
          openNowOnly: false,
          onToggleOpenNow: () {},
          selectedSort: PharmacySortOption.nearest,
          onSelectSort: (sort) => received = sort,
        ),
      );

      tester
          .widgetList<ChoiceChip>(find.byType(ChoiceChip))
          .elementAt(1)
          .onSelected!(true);
      await tester.pump();

      expect(received, PharmacySortOption.topRated);
    },
  );
}

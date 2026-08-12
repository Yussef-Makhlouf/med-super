import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:med_super/features/lab_booking/domain/entities/suggested_lab.dart';
import 'package:med_super/features/lab_booking/presentation/widgets/suggested_lab_card.dart';

import '../../../../helpers/pump_localized_widget.dart';

void main() {
  const lab = SuggestedLab(
    id: 'l1',
    name: 'Alpha Labs',
    distanceKm: 2.5,
    rating: 4.7,
  );

  testWidgets('renders lab name, rating and distance', (tester) async {
    await pumpLocalizedWidget(
      tester,
      SuggestedLabCard(lab: lab, onAdd: () {}),
    );

    expect(find.text('Alpha Labs'), findsOneWidget);
    expect(find.text('4.7'), findsOneWidget);
    expect(find.textContaining('2.5'), findsOneWidget);
    expect(find.byIcon(Icons.star), findsOneWidget);
    expect(find.byIcon(Icons.place_outlined), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('tapping the add button invokes onAdd', (tester) async {
    var tapped = false;
    await pumpLocalizedWidget(
      tester,
      SuggestedLabCard(lab: lab, onAdd: () => tapped = true),
    );

    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();

    expect(tapped, isTrue);
  });

  testWidgets('add button is disabled when onAdd is null', (tester) async {
    await pumpLocalizedWidget(tester, SuggestedLabCard(lab: lab));

    final button = tester.widget<IconButton>(find.byType(IconButton));
    expect(button.onPressed, isNull);
  });
}

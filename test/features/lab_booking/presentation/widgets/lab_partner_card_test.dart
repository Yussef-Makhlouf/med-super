import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:med_super/features/lab_booking/domain/entities/lab_partner.dart';
import 'package:med_super/features/lab_booking/presentation/widgets/lab_partner_card.dart';

import '../../../../helpers/pump_localized_widget.dart';

void main() {
  const partner = LabPartner(
    id: 'p1',
    name: 'Alpha Labs',
    distanceKm: 3.2,
    rating: 4.5,
    ratingCount: 120,
    totalPrice: 500,
    latitude: 24.7,
    longitude: 46.6,
  );

  testWidgets('renders partner name/price and no check badge when unselected', (
    tester,
  ) async {
    await pumpLocalizedWidget(
      tester,
      LabPartnerCard(partner: partner, isSelected: false, onSelect: () {}),
    );

    expect(find.text('Alpha Labs'), findsOneWidget);
    expect(find.text('500 ج.م'), findsOneWidget);
    expect(find.byIcon(Icons.check), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('shows a check badge when selected', (tester) async {
    await pumpLocalizedWidget(
      tester,
      LabPartnerCard(partner: partner, isSelected: true, onSelect: () {}),
    );

    expect(find.byIcon(Icons.check), findsOneWidget);
  });

  testWidgets('tapping the choose CTA invokes onSelect when unselected', (
    tester,
  ) async {
    var tapped = false;
    await pumpLocalizedWidget(
      tester,
      LabPartnerCard(
        partner: partner,
        isSelected: false,
        onSelect: () => tapped = true,
      ),
    );

    await tester.tap(find.byType(InkWell));
    await tester.pump();

    expect(tapped, isTrue);
  });
}

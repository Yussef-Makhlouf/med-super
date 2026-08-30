import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:med_super/features/pharmacy_booking/domain/entities/pharmacy.dart';
import 'package:med_super/features/pharmacy_booking/presentation/widgets/pharmacy_card.dart';

import '../../../../helpers/pump_localized_widget.dart';

void main() {
  const pharmacyWithDistance = Pharmacy(
    id: 'ph1',
    name: 'صيدلية النهدي',
    address: 'شارع التحلية، الرياض',
    latitude: 24.7,
    longitude: 46.6,
    deliveryCapable: true,
    distanceKm: 1.2,
  );

  const pharmacyWithoutDistance = Pharmacy(
    id: 'ph2',
    name: 'صيدلية الدواء',
    address: 'طريق الملك فهد، الرياض',
    latitude: 24.72,
    longitude: 46.68,
    deliveryCapable: false,
  );

  testWidgets('renders name, address and distance', (tester) async {
    await pumpLocalizedWidget(
      tester,
      PharmacyCard(
        pharmacy: pharmacyWithDistance,
        isSelected: true,
        onSelect: () {},
      ),
    );

    expect(find.text('صيدلية النهدي'), findsOneWidget);
    expect(find.text('شارع التحلية، الرياض'), findsOneWidget);
    expect(
      find.text(
        'pharmacy_booking.select_pharmacy.distance_km'.tr(args: ['1.2']),
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('hides the distance row when distance is unknown', (
    tester,
  ) async {
    await pumpLocalizedWidget(
      tester,
      PharmacyCard(
        pharmacy: pharmacyWithoutDistance,
        isSelected: false,
        onSelect: () {},
      ),
    );

    expect(find.byIcon(Icons.directions_car), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('shows the delivery badge for a branch that delivers', (
    tester,
  ) async {
    await pumpLocalizedWidget(
      tester,
      PharmacyCard(
        pharmacy: pharmacyWithDistance,
        isSelected: true,
        onSelect: () {},
      ),
    );

    expect(
      find.text('pharmacy_booking.select_pharmacy.delivery_available'.tr()),
      findsOneWidget,
    );
    expect(find.byIcon(Icons.delivery_dining_outlined), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('hides the delivery badge for a branch that does not deliver', (
    tester,
  ) async {
    await pumpLocalizedWidget(
      tester,
      PharmacyCard(
        pharmacy: pharmacyWithoutDistance,
        isSelected: false,
        onSelect: () {},
      ),
    );

    expect(
      find.text('pharmacy_booking.select_pharmacy.delivery_available'.tr()),
      findsNothing,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('shows a filled CTA when selected', (tester) async {
    await pumpLocalizedWidget(
      tester,
      PharmacyCard(
        pharmacy: pharmacyWithDistance,
        isSelected: true,
        onSelect: () {},
      ),
    );

    expect(
      find.widgetWithText(
        ElevatedButton,
        'pharmacy_booking.select_pharmacy.choose_cta'.tr(),
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('shows an outlined CTA when not selected', (tester) async {
    await pumpLocalizedWidget(
      tester,
      PharmacyCard(
        pharmacy: pharmacyWithDistance,
        isSelected: false,
        onSelect: () {},
      ),
    );

    expect(
      find.widgetWithText(
        OutlinedButton,
        'pharmacy_booking.select_pharmacy.choose_cta'.tr(),
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('tapping the CTA invokes onSelect', (tester) async {
    var tapped = false;
    await pumpLocalizedWidget(
      tester,
      PharmacyCard(
        pharmacy: pharmacyWithDistance,
        isSelected: true,
        onSelect: () => tapped = true,
      ),
    );

    final button = tester.widget<ElevatedButton>(
      find.widgetWithText(
        ElevatedButton,
        'pharmacy_booking.select_pharmacy.choose_cta'.tr(),
      ),
    );
    button.onPressed!();
    await tester.pump();

    expect(tapped, isTrue);
  });

  testWidgets('tapping the header invokes onViewDetails', (tester) async {
    var viewed = false;
    await pumpLocalizedWidget(
      tester,
      PharmacyCard(
        pharmacy: pharmacyWithDistance,
        isSelected: true,
        onSelect: () {},
        onViewDetails: () => viewed = true,
      ),
    );

    await tester.tap(find.text('صيدلية النهدي'));
    await tester.pump();

    expect(viewed, isTrue);
  });
}

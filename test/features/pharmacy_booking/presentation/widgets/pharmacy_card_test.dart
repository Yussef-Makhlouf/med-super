import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:med_super/features/pharmacy_booking/domain/entities/pharmacy.dart';
import 'package:med_super/features/pharmacy_booking/domain/entities/pharmacy_status.dart';
import 'package:med_super/features/pharmacy_booking/presentation/widgets/pharmacy_card.dart';

import '../../../../helpers/pump_localized_widget.dart';

void main() {
  const openPharmacy = Pharmacy(
    id: 'ph1',
    name: 'صيدلية النهدي',
    address: 'شارع التحلية، الرياض',
    distanceKm: 1.2,
    rating: 4.8,
    ratingCount: 1200,
    latitude: 24.7,
    longitude: 46.6,
    status: PharmacyStatus(state: PharmacyOpenState.open24h),
  );

  const openUntilPharmacy = Pharmacy(
    id: 'ph2',
    name: 'صيدلية الدواء',
    address: 'طريق الملك فهد، الرياض',
    distanceKm: 2.5,
    rating: 4.5,
    ratingCount: 850,
    latitude: 24.72,
    longitude: 46.68,
    status: PharmacyStatus(state: PharmacyOpenState.openUntil, time: '11:30 م'),
  );

  const closedPharmacy = Pharmacy(
    id: 'ph3',
    name: 'صيدلية المجتمع',
    address: 'حي العليا، الرياض',
    distanceKm: 3.8,
    rating: 4.2,
    ratingCount: 320,
    latitude: 24.69,
    longitude: 46.69,
    status: PharmacyStatus(
      state: PharmacyOpenState.closedUntilTomorrow,
      time: '8:00 ص',
    ),
  );

  testWidgets('renders name, address, distance, rating and review count', (
    tester,
  ) async {
    await pumpLocalizedWidget(
      tester,
      PharmacyCard(pharmacy: openPharmacy, isSelected: true, onSelect: () {}),
    );

    expect(find.text('صيدلية النهدي'), findsOneWidget);
    expect(find.text('شارع التحلية، الرياض'), findsOneWidget);
    expect(
      find.text(
        'pharmacy_booking.select_pharmacy.distance_km'.tr(args: ['1.2']),
      ),
      findsOneWidget,
    );
    expect(find.text('4.8'), findsOneWidget);
    expect(
      find.text(
        'pharmacy_booking.select_pharmacy.rating_count'.tr(args: ['1.2k']),
      ),
      findsOneWidget,
    );
    expect(find.byIcon(Icons.star), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('renders the open-24h status with no time argument', (
    tester,
  ) async {
    await pumpLocalizedWidget(
      tester,
      PharmacyCard(pharmacy: openPharmacy, isSelected: false, onSelect: () {}),
    );

    expect(find.text(PharmacyOpenState.open24h.labelKey.tr()), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('renders the open-until status with its closing time', (
    tester,
  ) async {
    await pumpLocalizedWidget(
      tester,
      PharmacyCard(
        pharmacy: openUntilPharmacy,
        isSelected: false,
        onSelect: () {},
      ),
    );

    expect(
      find.text(PharmacyOpenState.openUntil.labelKey.tr(args: ['11:30 م'])),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('renders the closed status with its opening time', (
    tester,
  ) async {
    await pumpLocalizedWidget(
      tester,
      PharmacyCard(
        pharmacy: closedPharmacy,
        isSelected: false,
        onSelect: () {},
      ),
    );

    expect(
      find.text(
        PharmacyOpenState.closedUntilTomorrow.labelKey.tr(args: ['8:00 ص']),
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('shows a filled CTA when selected', (tester) async {
    await pumpLocalizedWidget(
      tester,
      PharmacyCard(pharmacy: openPharmacy, isSelected: true, onSelect: () {}),
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
      PharmacyCard(pharmacy: openPharmacy, isSelected: false, onSelect: () {}),
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

  testWidgets('shows a muted outlined CTA for a closed pharmacy', (
    tester,
  ) async {
    await pumpLocalizedWidget(
      tester,
      PharmacyCard(pharmacy: closedPharmacy, isSelected: true, onSelect: () {}),
    );

    // Even the "selected" (first-card) treatment must not force a filled
    // button once the pharmacy is closed.
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
        pharmacy: openPharmacy,
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
}

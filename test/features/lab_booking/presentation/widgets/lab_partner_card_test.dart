import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:med_super/core/theme/app_colors.dart';
import 'package:med_super/features/lab_booking/domain/entities/lab_partner.dart';
import 'package:med_super/features/lab_booking/domain/entities/lab_partner_status.dart';
import 'package:med_super/features/lab_booking/presentation/widgets/lab_partner_card.dart';

import '../../../../helpers/pump_localized_widget.dart';

/// Finds the status chip's own background [Container] — the closest
/// [Container] ancestor of its label text, as opposed to the card's outer
/// white background container further up the tree.
Container _chipContainerFor(WidgetTester tester, String label) =>
    tester.widget<Container>(
      find
          .ancestor(of: find.text(label), matching: find.byType(Container))
          .first,
    );

void main() {
  const partner = LabPartner(
    id: 'p1',
    name: 'Alpha Labs',
    address: '12 Tahrir St, Cairo',
    distanceKm: 3.2,
    rating: 4.5,
    ratingCount: 120,
    startingPrice: 500,
    latitude: 24.7,
    longitude: 46.6,
    status: LabPartnerStatus.openNow,
  );

  testWidgets('renders partner name, starting price and rating', (
    tester,
  ) async {
    await pumpLocalizedWidget(
      tester,
      LabPartnerCard(partner: partner, isSelected: false, onSelect: () {}),
    );

    expect(find.text('Alpha Labs'), findsOneWidget);
    expect(find.text('500 ج.م'), findsOneWidget);
    expect(
      find.text('lab_booking.select_lab.starting_price_label'.tr()),
      findsOneWidget,
    );
    expect(find.text('4.5'), findsOneWidget);
    expect(find.byIcon(Icons.star), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('renders the distance combined with the address, and no '
      'check badge (this design has no distinct selected-card state)', (
    tester,
  ) async {
    await pumpLocalizedWidget(
      tester,
      LabPartnerCard(partner: partner, isSelected: false, onSelect: () {}),
    );

    final distance = 'lab_booking.select_lab.distance_km'.tr(args: ['3.2']);
    expect(find.textContaining(distance), findsOneWidget);
    expect(find.textContaining('12 Tahrir St, Cairo'), findsOneWidget);
    expect(find.byIcon(Icons.check), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'always shows the choose CTA and an info button, selected or not',
    (tester) async {
      for (final isSelected in [false, true]) {
        await pumpLocalizedWidget(
          tester,
          LabPartnerCard(
            partner: partner,
            isSelected: isSelected,
            onSelect: () {},
          ),
        );

        expect(
          find.text('lab_booking.select_lab.choose_cta'.tr()),
          findsOneWidget,
          reason: 'isSelected: $isSelected',
        );
        expect(
          find.byIcon(Icons.info_outline),
          findsOneWidget,
          reason: 'isSelected: $isSelected',
        );
      }
    },
  );

  testWidgets('tapping the choose CTA invokes onSelect', (tester) async {
    var tapped = false;
    await pumpLocalizedWidget(
      tester,
      LabPartnerCard(
        partner: partner,
        isSelected: false,
        onSelect: () => tapped = true,
      ),
    );

    // AppButton.filled renders an ElevatedButton internally.
    final button = tester.widget<ElevatedButton>(
      find.widgetWithText(
        ElevatedButton,
        'lab_booking.select_lab.choose_cta'.tr(),
      ),
    );
    button.onPressed!();
    await tester.pump();

    expect(tapped, isTrue);
  });

  testWidgets(
    'tapping the info button opens a details sheet with the name, address '
    'and starting price',
    (tester) async {
      await pumpLocalizedWidget(
        tester,
        LabPartnerCard(partner: partner, isSelected: false, onSelect: () {}),
      );

      await tester.tap(find.byIcon(Icons.info_outline));
      await tester.pumpAndSettle();

      expect(find.text('Alpha Labs'), findsWidgets);
      expect(find.text('12 Tahrir St, Cairo'), findsOneWidget);
      expect(find.text('500 ج.م'), findsWidgets);
      expect(tester.takeException(), isNull);
    },
  );

  group('status chip', () {
    // Pixel-exact chip colors per the mockup contract: green for open,
    // red for closed. Busy reuses the shared AppColors amber warning
    // tokens (asserted separately below since those are importable).
    const openBg = Color(0xFFDCFCE7);
    const openText = Color(0xFF15803D);
    const closedBg = Color(0xFFFEE2E2);
    const closedText = Color(0xFFB91C1C);

    testWidgets('renders the open-now label for an open partner', (
      tester,
    ) async {
      await pumpLocalizedWidget(
        tester,
        LabPartnerCard(partner: partner, isSelected: false, onSelect: () {}),
      );

      final label = LabPartnerStatus.openNow.labelKey.tr();
      expect(find.text(label), findsOneWidget);

      final decoration =
          _chipContainerFor(tester, label).decoration as BoxDecoration;
      expect(decoration.color, openBg);
      final text = tester.widget<Text>(find.text(label));
      expect(text.style?.color, openText);
    });

    testWidgets('renders the closed-now label for a closed partner', (
      tester,
    ) async {
      const closedPartner = LabPartner(
        id: 'p2',
        name: 'Alpha Clinics',
        address: '3 Nile St, Cairo',
        distanceKm: 1,
        rating: 4,
        ratingCount: 10,
        startingPrice: 200,
        latitude: 24.7,
        longitude: 46.6,
        status: LabPartnerStatus.closedNow,
      );

      await pumpLocalizedWidget(
        tester,
        LabPartnerCard(
          partner: closedPartner,
          isSelected: false,
          onSelect: () {},
        ),
      );

      final label = LabPartnerStatus.closedNow.labelKey.tr();
      expect(find.text(label), findsOneWidget);

      final decoration =
          _chipContainerFor(tester, label).decoration as BoxDecoration;
      expect(decoration.color, closedBg);
      final text = tester.widget<Text>(find.text(label));
      expect(text.style?.color, closedText);
    });

    testWidgets('renders the busy-now label for a busy partner', (
      tester,
    ) async {
      const busyPartner = LabPartner(
        id: 'p3',
        name: 'Smart Lab',
        address: '9 Abdel Azim St, Cairo',
        distanceKm: 2,
        rating: 4.6,
        ratingCount: 30,
        startingPrice: 350,
        latitude: 24.7,
        longitude: 46.6,
        status: LabPartnerStatus.busyNow,
      );

      await pumpLocalizedWidget(
        tester,
        LabPartnerCard(
          partner: busyPartner,
          isSelected: false,
          onSelect: () {},
        ),
      );

      final label = LabPartnerStatus.busyNow.labelKey.tr();
      expect(find.text(label), findsOneWidget);

      // Busy reuses the shared warning-amber tokens rather than a
      // chip-local color, per the implementation's own doc comment.
      final decoration =
          _chipContainerFor(tester, label).decoration as BoxDecoration;
      expect(decoration.color, AppColors.warningAmberBg);
      final text = tester.widget<Text>(find.text(label));
      expect(text.style?.color, AppColors.warningAmberText);
    });
  });
}

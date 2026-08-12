import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart' show FlutterMap;
import 'package:flutter_test/flutter_test.dart';
import 'package:med_super/features/lab_booking/domain/entities/lab_partner.dart';
import 'package:med_super/features/lab_booking/presentation/widgets/lab_partners_map_view.dart';

import '../../../../helpers/pump_localized_widget.dart';

void main() {
  const partners = [
    LabPartner(
      id: 'p1',
      name: 'Alpha',
      distanceKm: 1,
      rating: 4.5,
      ratingCount: 10,
      totalPrice: 300,
      latitude: 24.71,
      longitude: 46.67,
    ),
    LabPartner(
      id: 'p2',
      name: 'Beta',
      distanceKm: 2,
      rating: 4.2,
      ratingCount: 5,
      totalPrice: 250,
      latitude: 24.72,
      longitude: 46.68,
    ),
  ];

  testWidgets('renders a FlutterMap with a marker per partner, no exception', (
    tester,
  ) async {
    await pumpLocalizedWidget(
      tester,
      LabPartnersMapView(
        partners: partners,
        selectedId: 'p1',
        onSelect: (_) {},
      ),
    );

    expect(find.byType(FlutterMap), findsOneWidget);
    // flutter_map's `Marker` is a plain data object handed to `MarkerLayer`,
    // not itself inserted into the widget tree — assert on the icon each
    // marker's `child` renders instead of the `Marker` type.
    expect(find.byIcon(Icons.location_pin), findsNWidgets(partners.length));
    expect(find.byIcon(Icons.my_location), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('renders with an empty partner list without exception', (
    tester,
  ) async {
    await pumpLocalizedWidget(
      tester,
      LabPartnersMapView(partners: const [], selectedId: null, onSelect: (_) {}),
    );

    expect(find.byType(FlutterMap), findsOneWidget);
    expect(find.byIcon(Icons.location_pin), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('tapping a marker invokes onSelect with its partner id', (
    tester,
  ) async {
    String? selectedId;
    await pumpLocalizedWidget(
      tester,
      LabPartnersMapView(
        partners: partners,
        selectedId: null,
        onSelect: (id) => selectedId = id,
      ),
    );

    await tester.tap(find.byIcon(Icons.location_pin).first);
    await tester.pump();

    expect(selectedId, isNotNull);
  });
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart' show FlutterMap;
import 'package:flutter_test/flutter_test.dart';
import 'package:med_super/features/lab_booking/domain/entities/lab_partner.dart';
import 'package:med_super/features/lab_booking/domain/entities/lab_partner_status.dart';
import 'package:med_super/features/lab_booking/presentation/widgets/lab_partners_map_view.dart';

import '../../../../helpers/fake_tile_provider.dart';
import '../../../../helpers/pump_localized_widget.dart';

void main() {
  // flutter_map's built-in tile disk cache asks path_provider for a cache
  // directory as soon as the FlutterMap widget builds. There is no
  // path_provider platform implementation in `flutter test`, so without a
  // mock handler this throws a MissingPluginException asynchronously
  // *after* the test body has already finished, which flutter_test then
  // reports as a (spurious) failure of whichever test happens to be running
  // next. Stubbing the channel keeps that async plugin call from escaping
  // (mirrors clinic_location_map_view_test.dart's setup).
  const pathProviderChannel = MethodChannel('plugins.flutter.io/path_provider');

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(pathProviderChannel, (call) async {
          switch (call.method) {
            case 'getApplicationCacheDirectory':
            case 'getTemporaryDirectory':
            case 'getApplicationSupportDirectory':
              return '.dart_tool/test_cache';
            default:
              return null;
          }
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(pathProviderChannel, null);
  });

  const partners = [
    LabPartner(
      id: 'p1',
      name: 'Alpha',
      address: '1 Tahrir St, Cairo',
      distanceKm: 1,
      rating: 4.5,
      ratingCount: 10,
      startingPrice: 300,
      latitude: 24.71,
      longitude: 46.67,
      status: LabPartnerStatus.openNow,
    ),
    LabPartner(
      id: 'p2',
      name: 'Beta',
      address: '2 Nile St, Cairo',
      distanceKm: 2,
      rating: 4.2,
      ratingCount: 5,
      startingPrice: 250,
      latitude: 24.72,
      longitude: 46.68,
      status: LabPartnerStatus.openNow,
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
        tileProvider: FakeTileProvider(),
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
      LabPartnersMapView(
        partners: const [],
        selectedId: null,
        onSelect: (_) {},
        tileProvider: FakeTileProvider(),
      ),
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
        tileProvider: FakeTileProvider(),
      ),
    );

    await tester.tap(find.byIcon(Icons.location_pin).first);
    await tester.pump();

    expect(selectedId, isNotNull);
  });
}

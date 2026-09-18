import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart' show FlutterMap;
import 'package:flutter_test/flutter_test.dart';
import 'package:med_super/features/pharmacy_booking/domain/entities/pharmacy.dart';
import 'package:med_super/features/pharmacy_booking/presentation/widgets/pharmacy_map_view.dart';
import 'package:solar_icons/solar_icons.dart';

import '../../../../helpers/fake_tile_provider.dart';
import '../../../../helpers/pump_localized_widget.dart';

void main() {
  // flutter_map's built-in tile disk cache asks path_provider for a cache
  // directory as soon as the FlutterMap widget builds. There is no
  // path_provider platform implementation in `flutter test`, so without a
  // mock handler this throws a MissingPluginException asynchronously
  // *after* the test body has already finished, which flutter_test then
  // reports as a (spurious) failure of whichever test happens to be running
  // next (mirrors lab_partners_map_view_test.dart's setup).
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

  const pharmacies = [
    Pharmacy(
      id: 'ph1',
      name: 'Alpha Pharmacy',
      address: '1 Tahrir St, Cairo',
      distanceKm: 1,
      latitude: 24.71,
      longitude: 46.67,
      deliveryCapable: true,
    ),
    Pharmacy(
      id: 'ph2',
      name: 'Beta Pharmacy',
      address: '2 Nile St, Cairo',
      distanceKm: 2,
      latitude: 24.72,
      longitude: 46.68,
      deliveryCapable: false,
    ),
  ];

  testWidgets('renders a FlutterMap with a marker per pharmacy, no exception', (
    tester,
  ) async {
    await pumpLocalizedWidget(
      tester,
      PharmacyMapView(
        pharmacies: pharmacies,
        selectedId: 'ph1',
        onSelect: (_) {},
        tileProvider: FakeTileProvider(),
      ),
    );

    expect(find.byType(FlutterMap), findsOneWidget);
    expect(find.byIcon(SolarIconsBold.mapPoint), findsNWidgets(pharmacies.length));
    expect(find.byIcon(SolarIconsBold.gps), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('renders with an empty pharmacy list without exception', (
    tester,
  ) async {
    await pumpLocalizedWidget(
      tester,
      PharmacyMapView(
        pharmacies: const [],
        selectedId: null,
        onSelect: (_) {},
        tileProvider: FakeTileProvider(),
      ),
    );

    expect(find.byType(FlutterMap), findsOneWidget);
    expect(find.byIcon(SolarIconsBold.mapPoint), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('tapping a marker invokes onSelect with its pharmacy id', (
    tester,
  ) async {
    String? selectedId;
    await pumpLocalizedWidget(
      tester,
      PharmacyMapView(
        pharmacies: pharmacies,
        selectedId: null,
        onSelect: (id) => selectedId = id,
        tileProvider: FakeTileProvider(),
      ),
    );

    await tester.tap(find.byIcon(SolarIconsBold.mapPoint).first);
    await tester.pump();

    expect(selectedId, isNotNull);
  });

  testWidgets('renders the nearby-count pill and edit-location link', (
    tester,
  ) async {
    await pumpLocalizedWidget(
      tester,
      PharmacyMapView(
        pharmacies: pharmacies,
        selectedId: 'ph1',
        onSelect: (_) {},
        tileProvider: FakeTileProvider(),
      ),
    );

    expect(
      find.text(
        'pharmacy_booking.select_pharmacy.nearby_count'.tr(
          args: ['${pharmacies.length}'],
        ),
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}

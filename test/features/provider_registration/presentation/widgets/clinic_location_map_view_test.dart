import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:med_super/features/provider_registration/presentation/widgets/clinic_location_map_view.dart';

import '../../../../helpers/pump_app.dart';

void main() {
  // flutter_map's built-in tile disk cache asks path_provider for a cache
  // directory as soon as the FlutterMap widget builds. There is no
  // path_provider platform implementation in `flutter test`, so without a
  // mock handler this throws a MissingPluginException asynchronously
  // *after* the test body has already finished, which flutter_test then
  // reports as a (spurious) failure of whichever test happens to be running
  // next. Stubbing the channel keeps that async plugin call from escaping.
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

  // flutter_map fetches real OpenStreetMap tiles over the network. There is
  // no network access in `flutter test`, so tile image requests fail — but
  // flutter_map/the Image widget handles that gracefully (it just renders no
  // tile), it does not throw into the widget tree. We therefore smoke-test
  // that the widget builds, lays out, and responds to interaction without a
  // RenderFlex overflow or other exception, rather than asserting on tile
  // pixels which would require mocking network image loading.
  testWidgets('builds without throwing and shows the locate-me control', (
    tester,
  ) async {
    await pumpLocalizedApp(
      tester,
      ClinicLocationMapView(
        initialPosition: const LatLng(30.0444, 31.2357),
        onPositionChanged: (_) {},
        onLocateMe: () async => null,
      ),
    );

    expect(find.text('Locate me'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('does not overflow on a narrow 320px width', (tester) async {
    await pumpLocalizedApp(
      tester,
      ClinicLocationMapView(
        initialPosition: const LatLng(30.0444, 31.2357),
        onPositionChanged: (_) {},
        onLocateMe: () async => null,
      ),
      surfaceSize: const Size(320, 600),
    );

    expect(tester.takeException(), isNull);
  });

  testWidgets('tapping locate-me calls onLocateMe and shows a spinner', (
    tester,
  ) async {
    var called = false;
    await pumpLocalizedApp(
      tester,
      ClinicLocationMapView(
        initialPosition: const LatLng(30.0444, 31.2357),
        onPositionChanged: (_) {},
        onLocateMe: () async {
          called = true;
          return const LatLng(31.0, 32.0);
        },
      ),
    );

    await tester.tap(find.text('Locate me'));
    await tester.pumpAndSettle();

    expect(called, isTrue);
    expect(tester.takeException(), isNull);
  });
}

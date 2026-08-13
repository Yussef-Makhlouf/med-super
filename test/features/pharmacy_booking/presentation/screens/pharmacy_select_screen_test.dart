import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:med_super/features/pharmacy_booking/domain/entities/pharmacy.dart';
import 'package:med_super/features/pharmacy_booking/domain/entities/pharmacy_status.dart';
import 'package:med_super/features/pharmacy_booking/presentation/controllers/pharmacy_search_providers.dart';
import 'package:med_super/features/pharmacy_booking/presentation/screens/pharmacy_select_screen.dart';
import 'package:med_super/features/pharmacy_booking/presentation/widgets/pharmacy_card.dart';
import 'package:med_super/features/pharmacy_booking/presentation/widgets/pharmacy_filter_chip_bar.dart';
import 'package:med_super/features/pharmacy_booking/presentation/widgets/pharmacy_map_view.dart';
import 'package:med_super/features/pharmacy_booking/presentation/widgets/pharmacy_search_skeleton.dart';
import 'package:riverpod/misc.dart' show Override;
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../helpers/fake_tile_provider.dart';
import '../../../../helpers/pump_localized_widget.dart';

/// Wraps [child] in a real [GoRouter] (so `context.push`/`context.pop` work)
/// plus the same EasyLocalization/ProviderScope shell `pumpLocalizedWidget`
/// builds internally — mirrors `lab_select_partner_screen_test.dart`'s
/// `pumpWithRouter` helper.
Future<GoRouter> pumpWithRouter(
  WidgetTester tester,
  Widget child, {
  required List<Override> overrides,
}) async {
  SharedPreferences.setMockInitialValues({});

  tester.view.physicalSize = const Size(2400, 1400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final router = GoRouter(
    initialLocation: '/start',
    routes: [
      GoRoute(
        path: '/start',
        builder: (context, state) =>
            const Scaffold(body: Text('start-placeholder')),
      ),
      GoRoute(path: '/select-pharmacy', builder: (context, state) => child),
      GoRoute(
        path: '/patient/pharmacy/review',
        builder: (context, state) =>
            const Scaffold(body: Text('review-screen')),
      ),
    ],
  );
  addTearDown(router.dispose);

  Widget shell() => ProviderScope(
    overrides: overrides,
    child: EasyLocalization(
      supportedLocales: const [Locale('en'), Locale('ar')],
      path: 'assets/translations',
      fallbackLocale: const Locale('en'),
      startLocale: const Locale('en'),
      saveLocale: false,
      useOnlyLangCode: true,
      child: Builder(
        builder: (context) {
          return MaterialApp.router(
            debugShowCheckedModeBanner: false,
            localizationsDelegates: context.localizationDelegates,
            supportedLocales: context.supportedLocales,
            locale: context.locale,
            routerConfig: router,
          );
        },
      ),
    ),
  );

  await tester.runAsync(() async {
    await EasyLocalization.ensureInitialized();
    await tester.pumpWidget(shell());
    await tester.pumpAndSettle();

    router.push('/select-pharmacy');
    for (var i = 0; i < 3; i++) {
      await tester.pump();
    }
    await tester.pumpAndSettle();
  });

  return router;
}

/// A bounded stand-in for `tester.pumpAndSettle()` — mirrors
/// `lab_select_partner_screen_test.dart`'s `_settle` helper.
Future<void> _settle(WidgetTester tester) => tester.runAsync(() async {
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 20));
  }
});

void main() {
  // Same path_provider stub as pharmacy_map_view_test.dart — this screen
  // renders a PharmacyMapView (FlutterMap) whose tile disk cache asks
  // path_provider for a cache directory as soon as it builds.
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
      distanceKm: 1.2,
      rating: 4.8,
      ratingCount: 120,
      latitude: 24.71,
      longitude: 46.67,
      status: PharmacyStatus(state: PharmacyOpenState.open24h),
    ),
    Pharmacy(
      id: 'ph2',
      name: 'Beta Pharmacy',
      address: '2 Nile St, Cairo',
      distanceKm: 3.4,
      rating: 4.2,
      ratingCount: 40,
      latitude: 24.72,
      longitude: 46.68,
      status: PharmacyStatus(
        state: PharmacyOpenState.closedUntilTomorrow,
        time: '8:00 ص',
      ),
    ),
  ];

  List<Override> overrides() => [
    pharmaciesProvider.overrideWith((ref) async => pharmacies),
  ];

  testWidgets(
    'renders header (no stepper), map, filter chips and a card per pharmacy',
    (tester) async {
      await pumpLocalizedWidget(
        tester,
        PharmacySelectScreen(mapTileProvider: FakeTileProvider()),
        overrides: overrides(),
      );
      await _settle(tester);

      expect(find.byIcon(Icons.arrow_forward), findsOneWidget);
      expect(
        find.text('pharmacy_booking.select_pharmacy.title'.tr()),
        findsOneWidget,
      );

      expect(find.byType(PharmacyMapView), findsOneWidget);
      expect(find.byType(PharmacyFilterChipBar), findsOneWidget);
      expect(find.byType(PharmacyCard), findsNWidgets(pharmacies.length));
      expect(find.text('Alpha Pharmacy'), findsWidgets);
      expect(find.text('Beta Pharmacy'), findsOneWidget);

      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('shows the skeleton (not a spinner) before pharmacies resolve', (
    tester,
  ) async {
    final completer = Completer<List<Pharmacy>>();

    await pumpLocalizedWidget(
      tester,
      PharmacySelectScreen(mapTileProvider: FakeTileProvider()),
      overrides: [pharmaciesProvider.overrideWith((ref) => completer.future)],
    );

    expect(find.byType(PharmacySearchSkeleton), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.byType(PharmacyCard), findsNothing);

    completer.complete(pharmacies);
    await _settle(tester);

    expect(find.byType(PharmacySearchSkeleton), findsNothing);
    expect(find.byType(PharmacyCard), findsNWidgets(pharmacies.length));
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'defaults the first pharmacy as selected when none chosen explicitly',
    (tester) async {
      await pumpLocalizedWidget(
        tester,
        PharmacySelectScreen(mapTileProvider: FakeTileProvider()),
        overrides: overrides(),
      );
      await _settle(tester);

      final cards = tester
          .widgetList<PharmacyCard>(find.byType(PharmacyCard))
          .toList();
      expect(cards[0].pharmacy.id, 'ph1');
      expect(cards[0].isSelected, isTrue);
      expect(cards[1].isSelected, isFalse);

      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'tapping a pharmacy card choose CTA selects it and navigates to the '
    'review route',
    (tester) async {
      await pumpWithRouter(
        tester,
        PharmacySelectScreen(mapTileProvider: FakeTileProvider()),
        overrides: overrides(),
      );
      await _settle(tester);

      final secondCardChoose = find.descendant(
        of: find.byType(PharmacyCard).at(1),
        matching: find.widgetWithText(
          OutlinedButton,
          'pharmacy_booking.select_pharmacy.choose_cta'.tr(),
        ),
      );
      tester.widget<OutlinedButton>(secondCardChoose).onPressed!();
      await tester.pumpAndSettle();

      expect(find.text('review-screen'), findsOneWidget);
      expect(find.text('start-placeholder'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('tapping the back button pops the screen', (tester) async {
    await pumpWithRouter(
      tester,
      PharmacySelectScreen(mapTileProvider: FakeTileProvider()),
      overrides: overrides(),
    );
    await _settle(tester);

    expect(find.text('start-placeholder'), findsNothing);

    final backButton = tester.widget<IconButton>(
      find.ancestor(
        of: find.byIcon(Icons.arrow_forward),
        matching: find.byType(IconButton),
      ),
    );
    backButton.onPressed!();
    await tester.pumpAndSettle();

    expect(find.text('start-placeholder'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'renders no cards and does not crash when the pharmacy list is empty',
    (tester) async {
      await pumpLocalizedWidget(
        tester,
        PharmacySelectScreen(mapTileProvider: FakeTileProvider()),
        overrides: [pharmaciesProvider.overrideWith((ref) async => const [])],
      );
      await _settle(tester);

      expect(find.byType(PharmacyCard), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('typing in the search field filters the pharmacy list', (
    tester,
  ) async {
    await pumpLocalizedWidget(
      tester,
      PharmacySelectScreen(mapTileProvider: FakeTileProvider()),
      overrides: overrides(),
    );
    await _settle(tester);

    await tester.enterText(find.byType(TextField), 'Beta');
    await _settle(tester);

    expect(find.byType(PharmacyCard), findsOneWidget);
    expect(find.text('Beta Pharmacy'), findsOneWidget);
    expect(find.text('Alpha Pharmacy'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('toggling the open-now filter chip hides the closed pharmacy', (
    tester,
  ) async {
    await pumpLocalizedWidget(
      tester,
      PharmacySelectScreen(mapTileProvider: FakeTileProvider()),
      overrides: overrides(),
    );
    await _settle(tester);

    expect(find.byType(PharmacyCard), findsNWidgets(2));

    tester.widgetList<ChoiceChip>(find.byType(ChoiceChip)).first.onSelected!(
      true,
    );
    await _settle(tester);

    expect(find.byType(PharmacyCard), findsOneWidget);
    expect(find.text('Alpha Pharmacy'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

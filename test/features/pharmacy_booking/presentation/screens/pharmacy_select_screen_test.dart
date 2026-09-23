import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:med_super/core/widgets/step_progress_header.dart';
import 'package:med_super/features/pharmacy_booking/domain/entities/delivery_method.dart';
import 'package:med_super/features/pharmacy_booking/domain/entities/pharmacy.dart';
import 'package:med_super/features/pharmacy_booking/presentation/controllers/pharmacy_search_providers.dart';
import 'package:med_super/features/pharmacy_booking/presentation/controllers/pharmacy_upload_providers.dart';
import 'package:med_super/features/pharmacy_booking/presentation/screens/pharmacy_select_screen.dart';
import 'package:med_super/features/pharmacy_booking/presentation/widgets/pharmacy_card.dart';
import 'package:med_super/features/pharmacy_booking/presentation/widgets/pharmacy_map_view.dart';
import 'package:med_super/features/pharmacy_booking/presentation/widgets/pharmacy_search_skeleton.dart';
import 'package:riverpod/misc.dart' show Override;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:solar_icons/solar_icons.dart';

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

  // A single `pumpAndSettle()` isn't enough: while the (large) translation
  // JSON is still loading via real `rootBundle` I/O nothing is scheduled on
  // the fake clock, so it returns immediately with an empty tree. Interleave
  // real delays with frame pumps until each route is actually mounted.
  await tester.runAsync(() async {
    await EasyLocalization.ensureInitialized();
    await tester.pumpWidget(shell());
    for (var i = 0; i < 200 && !tester.any(find.text('start-placeholder')); i++) {
      await Future<void>.delayed(const Duration(milliseconds: 10));
      await tester.pump(const Duration(milliseconds: 20));
    }
    await tester.pumpAndSettle();

    router.push('/select-pharmacy');
    for (var i = 0; i < 200 && !tester.any(find.byWidget(child)); i++) {
      await Future<void>.delayed(const Duration(milliseconds: 10));
      await tester.pump(const Duration(milliseconds: 20));
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

class _FixedDeliveryMethod extends SelectedDeliveryMethod {
  _FixedDeliveryMethod(this._value);

  final DeliveryMethod _value;

  @override
  DeliveryMethod build() => _value;
}

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
      latitude: 24.71,
      longitude: 46.67,
      deliveryCapable: true,
    ),
    Pharmacy(
      id: 'ph2',
      name: 'Beta Pharmacy',
      address: '2 Nile St, Cairo',
      distanceKm: 3.4,
      latitude: 24.72,
      longitude: 46.68,
      deliveryCapable: false,
    ),
  ];

  List<Override> overrides({DeliveryMethod? deliveryMethod}) => [
    pharmaciesProvider.overrideWith((ref) async => pharmacies),
    if (deliveryMethod != null)
      selectedDeliveryMethodProvider.overrideWith(
        () => _FixedDeliveryMethod(deliveryMethod),
      ),
  ];

  testWidgets(
    'renders header, stepper, map and a card per pharmacy',
    (tester) async {
      await pumpLocalizedWidget(
        tester,
        PharmacySelectScreen(mapTileProvider: FakeTileProvider()),
        overrides: overrides(),
      );
      await _settle(tester);

      expect(find.byIcon(SolarIconsOutline.arrowRight), findsOneWidget);
      expect(
        find.text('pharmacy_booking.select_pharmacy.title'.tr()),
        findsOneWidget,
      );
      expect(find.byType(StepProgressHeader), findsOneWidget);

      expect(find.byType(PharmacyMapView), findsOneWidget);
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
    'no pharmacy is pre-selected on entry — the patient must explicitly '
    'choose one, and "التالي" starts disabled',
    (tester) async {
      await pumpWithRouter(
        tester,
        PharmacySelectScreen(mapTileProvider: FakeTileProvider()),
        overrides: overrides(deliveryMethod: DeliveryMethod.pickup),
      );
      await _settle(tester);

      final cards = tester
          .widgetList<PharmacyCard>(find.byType(PharmacyCard))
          .toList();
      expect(cards[0].isSelected, isFalse);
      expect(cards[1].isSelected, isFalse);

      final nextButton = find.widgetWithText(
        ElevatedButton,
        'pharmacy_booking.select_pharmacy.next_cta'.tr(),
      );
      expect(tester.widget<ElevatedButton>(nextButton).onPressed, isNull);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'tapping a pharmacy card choose CTA only selects it — it does not '
    'navigate, so the patient can change their mind',
    (tester) async {
      await pumpWithRouter(
        tester,
        PharmacySelectScreen(mapTileProvider: FakeTileProvider()),
        // PICKUP, not the homeDelivery default — ph2 isn't delivery-capable
        // and this test isn't about that, just about tap-to-select.
        overrides: overrides(deliveryMethod: DeliveryMethod.pickup),
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

      expect(find.text('review-screen'), findsNothing);
      expect(
        tester
            .widgetList<PharmacyCard>(find.byType(PharmacyCard))
            .toList()[1]
            .isSelected,
        isTrue,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'a non-delivery-capable card is disabled and unselectable when the '
    'patient chose home delivery on step 1',
    (tester) async {
      await pumpWithRouter(
        tester,
        PharmacySelectScreen(mapTileProvider: FakeTileProvider()),
        overrides: overrides(deliveryMethod: DeliveryMethod.homeDelivery),
      );
      await _settle(tester);

      final cards = tester
          .widgetList<PharmacyCard>(find.byType(PharmacyCard))
          .toList();
      expect(cards[0].disabled, isFalse); // ph1: deliveryCapable
      expect(cards[1].disabled, isTrue); // ph2: !deliveryCapable

      final secondCardChoose = find.descendant(
        of: find.byType(PharmacyCard).at(1),
        matching: find.byType(OutlinedButton),
      );
      expect(tester.widget<OutlinedButton>(secondCardChoose).onPressed, isNull);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'tapping a card then the bottom "التالي" bar navigates to the review route',
    (tester) async {
      await pumpWithRouter(
        tester,
        PharmacySelectScreen(mapTileProvider: FakeTileProvider()),
        overrides: overrides(deliveryMethod: DeliveryMethod.pickup),
      );
      await _settle(tester);

      final firstCardChoose = find.descendant(
        of: find.byType(PharmacyCard).at(0),
        matching: find.byType(OutlinedButton),
      );
      tester.widget<OutlinedButton>(firstCardChoose).onPressed!();
      await tester.pumpAndSettle();

      final nextButton = find.widgetWithText(
        ElevatedButton,
        'pharmacy_booking.select_pharmacy.next_cta'.tr(),
      );
      expect(nextButton, findsOneWidget);
      tester.widget<ElevatedButton>(nextButton).onPressed!();
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
        of: find.byIcon(SolarIconsOutline.arrowRight),
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
}

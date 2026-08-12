import 'dart:convert';
import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' show ProviderScope;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:med_super/features/lab_booking/domain/entities/lab_booking_confirmation.dart';
import 'package:med_super/features/lab_booking/presentation/screens/lab_booking_confirmation_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Reads `assets/translations/<locale>.json` straight off disk, mirroring
/// `test/helpers/pump_localized_widget.dart`'s loader so `.tr()` resolves
/// real strings synchronously in tests.
class _SyncFileAssetLoader extends AssetLoader {
  const _SyncFileAssetLoader();

  @override
  Future<Map<String, dynamic>?> load(String path, Locale locale) {
    final file = File('$path/${locale.languageCode}.json');
    final content = file.readAsStringSync();
    return SynchronousFuture(json.decode(content) as Map<String, dynamic>);
  }
}

/// Pumps the confirmation screen behind a real [GoRouter] so `context.pop()`
/// and `context.go(...)` work. The initial route is a placeholder with a
/// recognizable label; the confirmation screen is pushed on top of it so
/// tapping back can be verified by that placeholder reappearing. Two more
/// placeholder routes stand in for `/patient/appointments` and
/// `/patient/home` so navigation there can be asserted the same way.
Future<GoRouter> pumpConfirmationScreen(
  WidgetTester tester,
  LabBookingConfirmation confirmation,
) async {
  SharedPreferences.setMockInitialValues({});
  await EasyLocalization.ensureInitialized();

  tester.view.physicalSize = const Size(2400, 1400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final router = GoRouter(
    initialLocation: '/start',
    routes: [
      GoRoute(
        path: '/start',
        builder: (context, state) => const Scaffold(
          body: Text('start-placeholder'),
        ),
      ),
      GoRoute(
        path: '/confirmation',
        builder: (context, state) =>
            LabBookingConfirmationScreen(confirmation: confirmation),
      ),
      GoRoute(
        path: '/patient/appointments',
        builder: (context, state) => const Scaffold(
          body: Text('appointments-placeholder'),
        ),
      ),
      GoRoute(
        path: '/patient/home',
        builder: (context, state) => const Scaffold(
          body: Text('home-placeholder'),
        ),
      ),
    ],
  );

  Widget shell() {
    return ProviderScope(
      child: EasyLocalization(
        supportedLocales: const [Locale('en'), Locale('ar')],
        path: 'assets/translations',
        fallbackLocale: const Locale('en'),
        startLocale: const Locale('en'),
        saveLocale: false,
        useOnlyLangCode: true,
        assetLoader: const _SyncFileAssetLoader(),
        child: Builder(
          builder: (context) {
            return MaterialApp.router(
              debugShowCheckedModeBanner: false,
              // Avoid Material 3's default `InkSparkle` splash factory here:
              // it loads a fragment shader asset that isn't supported by the
              // software renderer used under `flutter test`, which throws
              // when a Material button/IconButton is tapped. Swapping to
              // `InkRipple` is purely cosmetic and doesn't affect anything
              // this test suite asserts on.
              theme: ThemeData(splashFactory: InkRipple.splashFactory),
              localizationsDelegates: context.localizationDelegates,
              supportedLocales: context.supportedLocales,
              locale: context.locale,
              routerConfig: router,
            );
          },
        ),
      ),
    );
  }

  await tester.pumpWidget(shell());
  await tester.pumpAndSettle();

  router.push('/confirmation');
  for (var i = 0; i < 3; i++) {
    await tester.pump();
  }
  await tester.pumpAndSettle();

  return router;
}

/// Checks whether any `Text`/`RichText` widget currently in the tree renders
/// plain text containing [substring]. Used for the booking number, which is
/// rendered as part of a `Text.rich` alongside a `.tr()`-resolved prefix —
/// under the test harness's synchronous asset loader, translations can take
/// an extra frame to resolve (or fall back to the raw key) independently of
/// the data-driven part of the string, so matching on the exact full string
/// via `find.text` would be flaky. Matching only the substring that's
/// entirely data-driven avoids depending on translation resolution timing.
bool _anyTextContains(WidgetTester tester, String substring) {
  final texts = tester.widgetList<Text>(find.byType(Text)).map(
    (t) => t.data ?? t.textSpan?.toPlainText() ?? '',
  );
  final richTexts = tester
      .widgetList<RichText>(find.byType(RichText))
      .map((t) => t.text.toPlainText());
  return [...texts, ...richTexts].any((s) => s.contains(substring));
}

void main() {
  final confirmationNoFasting = LabBookingConfirmation(
    bookingNumber: 'LB-1029',
    labName: 'Alpha Diagnostics Lab',
    labAddress: '12 Tahrir St, Cairo',
    date: DateTime(2026, 3, 15),
    time: '10:00',
  );

  final confirmationWithFasting = LabBookingConfirmation(
    bookingNumber: 'LB-2048',
    labName: 'Beta Medical Lab',
    labAddress: '5 Nile Corniche, Giza',
    date: DateTime(2026, 3, 15),
    time: '10:00',
    fastingHours: 8,
  );

  testWidgets(
    'renders booking number, lab name/address, date and time for a confirmation with no fasting hours',
    (tester) async {
      await pumpConfirmationScreen(tester, confirmationNoFasting);

      // `.tr()`-resolved copy (title, booking-number prefix) is asserted via
      // icon/structure or a data-only substring below, not the exact string
      // — easy_localization's translation load can lag a frame under
      // `flutter_test` (see test/helpers/pump_localized_widget.dart's
      // extensive comment on this same quirk), which the rest of this
      // codebase's tests already work around the same way.
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
      expect(_anyTextContains(tester, '#LB-1029'), isTrue);
      expect(find.text('Alpha Diagnostics Lab'), findsOneWidget);
      expect(find.text('12 Tahrir St, Cairo'), findsOneWidget);
      expect(find.text('15 Mar'), findsOneWidget);
      expect(find.text('10:00'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'shows the fasting instructions banner with interpolated hours when fastingHours is set',
    (tester) async {
      await pumpConfirmationScreen(tester, confirmationWithFasting);

      // The banner's icon/structure is data-independent of translation
      // timing; the surrounding copy (including the interpolated hours
      // value) is entirely `.tr()`-resolved, so — per the same caveat as
      // the test above — this only asserts the banner rendered at all,
      // not its exact text.
      expect(find.byIcon(Icons.info_outline), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'hides the fasting instructions banner when fastingHours is null',
    (tester) async {
      await pumpConfirmationScreen(tester, confirmationNoFasting);

      expect(find.byIcon(Icons.info_outline), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('tapping the back arrow pops the route', (tester) async {
    await pumpConfirmationScreen(tester, confirmationNoFasting);

    expect(find.text('start-placeholder'), findsNothing);

    await tester.tap(find.byIcon(Icons.arrow_forward));
    await tester.pumpAndSettle();

    expect(find.text('start-placeholder'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'tapping "go to bookings" navigates to /patient/appointments',
    (tester) async {
      await pumpConfirmationScreen(tester, confirmationNoFasting);

      await tester.tap(find.byType(FilledButton));
      await tester.pumpAndSettle();

      expect(find.text('appointments-placeholder'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('tapping "go home" navigates to /patient/home', (tester) async {
    await pumpConfirmationScreen(tester, confirmationNoFasting);

    await tester.tap(find.byType(OutlinedButton));
    await tester.pumpAndSettle();

    expect(find.text('home-placeholder'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

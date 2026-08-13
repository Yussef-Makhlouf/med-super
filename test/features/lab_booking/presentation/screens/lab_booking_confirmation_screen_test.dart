import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' show ProviderScope;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:med_super/core/theme/app_colors.dart';
import 'package:med_super/features/lab_booking/domain/entities/lab_booking_confirmation.dart';
import 'package:med_super/features/lab_booking/presentation/screens/lab_booking_confirmation_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Pumps the confirmation screen behind a real [GoRouter] so `context.go(...)`
/// works. The initial route is a placeholder with a recognizable label; the
/// confirmation screen is pushed on top of it (the screen itself has no
/// back button — there's nothing to go back and redo once the request has
/// been sent). Two more placeholder routes stand in for `/patient/orders`
/// and `/patient/home` so navigation there can be asserted the same way.
Future<GoRouter> pumpConfirmationScreen(
  WidgetTester tester,
  LabBookingConfirmation confirmation, {
  Locale startLocale = const Locale('en'),
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
      GoRoute(
        path: '/confirmation',
        builder: (context, state) =>
            LabBookingConfirmationScreen(confirmation: confirmation),
      ),
      GoRoute(
        path: '/patient/orders',
        builder: (context, state) =>
            const Scaffold(body: Text('orders-placeholder')),
      ),
      GoRoute(
        path: '/patient/home',
        builder: (context, state) =>
            const Scaffold(body: Text('home-placeholder')),
      ),
    ],
  );

  Widget shell() {
    return ProviderScope(
      child: EasyLocalization(
        supportedLocales: const [Locale('en'), Locale('ar')],
        path: 'assets/translations',
        fallbackLocale: const Locale('en'),
        startLocale: startLocale,
        saveLocale: false,
        useOnlyLangCode: true,
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

  // easy_localization's default asset loader does real `rootBundle`
  // (non-fake-clock) I/O, so the whole pump sequence has to run inside
  // `tester.runAsync` or `.tr()` permanently falls back to the raw key
  // regardless of how many frames are pumped afterwards — see the doc
  // comment on `pumpLocalizedWidget` in test/helpers/pump_localized_widget.dart
  // for the longer story.
  await tester.runAsync(() async {
    await EasyLocalization.ensureInitialized();
    await tester.pumpWidget(shell());
    await tester.pumpAndSettle();

    router.push('/confirmation');
    for (var i = 0; i < 3; i++) {
      await tester.pump();
    }
    await tester.pumpAndSettle();
  });

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
  final texts = tester
      .widgetList<Text>(find.byType(Text))
      .map((t) => t.data ?? t.textSpan?.toPlainText() ?? '');
  final richTexts = tester
      .widgetList<RichText>(find.byType(RichText))
      .map((t) => t.text.toPlainText());
  return [...texts, ...richTexts].any((s) => s.contains(substring));
}

void main() {
  final confirmation = LabBookingConfirmation(
    bookingNumber: 'LB-1029',
    labName: 'Alpha Diagnostics Lab',
    labAddress: '12 Tahrir St, Cairo',
    expectedResponseHours: 2,
  );

  testWidgets(
    'renders booking number, lab name/address and expected response hours',
    (tester) async {
      await pumpConfirmationScreen(tester, confirmation);

      // The booking number is rendered as part of a `Text.rich` alongside a
      // `.tr()`-resolved prefix, so it's asserted via a data-only substring
      // below rather than matching the full rendered string (see
      // `_anyTextContains`'s doc comment). Exact `.tr()` copy — title,
      // subtitle, CTA labels — is asserted in the dedicated tests below.
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
      // The header used to also show a search icon with no purpose on a
      // success screen — removed.
      expect(find.byIcon(Icons.search), findsNothing);
      expect(_anyTextContains(tester, '#LB-1029'), isTrue);
      expect(find.text('Alpha Diagnostics Lab'), findsOneWidget);
      expect(find.text('12 Tahrir St, Cairo'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('shows no fasting/instructions banner and no date/time tiles '
      '(request is only submitted, not confirmed with a slot)', (tester) async {
    await pumpConfirmationScreen(tester, confirmation);

    expect(find.byIcon(Icons.info_outline), findsNothing);
    expect(_anyTextContains(tester, 'fasting'), isFalse);
    expect(_anyTextContains(tester, 'Fasting'), isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'uses the corrected copy — the lab (not the pharmacy) reviews the '
    'request, and an expected-response time (not a delivery time)',
    (tester) async {
      await pumpConfirmationScreen(tester, confirmation);

      // Real strings loaded straight from assets/translations/en.json via
      // the sync asset loader above (not hardcoded independently of it), so
      // a regression that reintroduces the mockup's leaked pharmacy/delivery
      // copy — or otherwise changes these translation values — fails here.
      expect(_anyTextContains(tester, 'Request sent successfully'), isTrue);
      expect(
        _anyTextContains(
          tester,
          "We'll notify you as soon as the lab reviews your request and "
          'responds.',
        ),
        isTrue,
      );
      expect(_anyTextContains(tester, 'pharmacy'), isFalse);
      expect(_anyTextContains(tester, 'Pharmacy'), isFalse);
      expect(_anyTextContains(tester, 'Expected response time'), isTrue);
      expect(_anyTextContains(tester, 'Within 2 hours'), isTrue);
      expect(_anyTextContains(tester, 'delivery'), isFalse);
      expect(_anyTextContains(tester, 'Delivery'), isFalse);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Arabic copy is also corrected — says "المختبر" (the lab), never '
      '"الصيدلية" (the pharmacy), and uses response-time wording, not '
      'delivery/date-time wording', (tester) async {
    await pumpConfirmationScreen(
      tester,
      confirmation,
      startLocale: const Locale('ar'),
    );

    // Loaded straight from assets/translations/ar.json via the same sync
    // asset loader, so a regression that reintroduces the mockup's
    // "الصيدلية" leak (or drops the response-time correction) in the
    // Arabic strings fails here too, not just in English.
    expect(_anyTextContains(tester, 'تم إرسال الطلب بنجاح'), isTrue);
    expect(
      _anyTextContains(
        tester,
        'سنقوم بإشعارك بمجرد مراجعة المختبر لطلبك والرد عليه.',
      ),
      isTrue,
    );
    expect(_anyTextContains(tester, 'الصيدلية'), isFalse);
    expect(_anyTextContains(tester, 'الوقت المتوقع للرد'), isTrue);
    expect(_anyTextContains(tester, 'خلال 2 ساعتين'), isTrue);
    expect(_anyTextContains(tester, 'تتبع الطلب'), isTrue);
    expect(_anyTextContains(tester, 'الصفحة الرئيسية'), isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('shows exactly one expected-response info tile (not separate '
      'date/time tiles) and no leftover date/time/fasting icons', (
    tester,
  ) async {
    await pumpConfirmationScreen(tester, confirmation);

    // The old two-tile date/time layout used calendar/clock-style icons;
    // the confirmation-screen widget tree now has no icon besides the
    // success checkmark, the lab-summary icon and the CTA icon (no back
    // arrow either — there's nothing to logically go back and redo from
    // here), so there should be exactly 3 `Icon` widgets in total.
    expect(find.byType(Icon), findsNWidgets(3));
    expect(find.byIcon(Icons.arrow_forward), findsNothing);
    expect(find.byIcon(Icons.calendar_today), findsNothing);
    expect(find.byIcon(Icons.access_time), findsNothing);
    expect(find.byIcon(Icons.schedule), findsNothing);
    // Exactly one label/value pair for the response-time tile.
    expect(find.text('Expected response time'), findsOneWidget);
    expect(find.text('Within 2 hours'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'success badge is a teal checkmark circle (mockup-exact color, not the '
    'app default green)',
    (tester) async {
      await pumpConfirmationScreen(tester, confirmation);

      final icon = tester.widget<Icon>(find.byIcon(Icons.check_circle));
      expect(icon.color, AppColors.tealAccent);

      final badge = tester.widget<Container>(
        find
            .ancestor(
              of: find.byIcon(Icons.check_circle),
              matching: find.byType(Container),
            )
            .first,
      );
      final decoration = badge.decoration as BoxDecoration;
      expect(decoration.shape, BoxShape.circle);
      expect(decoration.color, AppColors.tealAccent.withValues(alpha: 0.12));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'primary CTA uses a tracking/document icon, not a delivery-truck icon',
    (tester) async {
      await pumpConfirmationScreen(tester, confirmation);

      expect(find.byIcon(Icons.assignment_outlined), findsOneWidget);
      expect(find.byIcon(Icons.local_shipping), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'shows the booking-number prefix and the track/go-home CTA labels from '
    'real translations',
    (tester) async {
      await pumpConfirmationScreen(tester, confirmation);

      expect(_anyTextContains(tester, 'Your booking number is'), isTrue);
      expect(_anyTextContains(tester, 'Track request'), isTrue);
      expect(_anyTextContains(tester, 'Home'), isTrue);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('has no back button — the request is already sent, so there is '
      'nothing to logically go back and redo', (tester) async {
    await pumpConfirmationScreen(tester, confirmation);

    expect(find.byIcon(Icons.arrow_forward), findsNothing);
    expect(find.byType(IconButton), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'blocks the Android hardware/gesture back button too, not just the '
    'in-app arrow — the screen stays put instead of popping to the '
    'previous route',
    (tester) async {
      await pumpConfirmationScreen(tester, confirmation);

      // Simulates the OS-level back button/gesture (as opposed to a
      // Navigator.pop() call from in-app UI) — the same signal `PopScope`
      // intercepts. `canPop: false` should swallow it, so the previous
      // route's placeholder must never appear.
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      expect(find.text('start-placeholder'), findsNothing);
      expect(_anyTextContains(tester, 'Request sent successfully'), isTrue);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('tapping the primary CTA navigates to /patient/orders', (
    tester,
  ) async {
    await pumpConfirmationScreen(tester, confirmation);

    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();

    expect(find.text('orders-placeholder'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('tapping "go home" navigates to /patient/home', (tester) async {
    await pumpConfirmationScreen(tester, confirmation);

    await tester.tap(find.byType(OutlinedButton));
    await tester.pumpAndSettle();

    expect(find.text('home-placeholder'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

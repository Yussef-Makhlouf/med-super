import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' show ProviderScope;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:med_super/core/theme/app_colors.dart';
import 'package:med_super/features/pharmacy_booking/domain/entities/pharmacy_order_confirmation.dart';
import 'package:med_super/features/pharmacy_booking/presentation/screens/pharmacy_order_confirmation_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:solar_icons/solar_icons.dart';

/// Pumps the confirmation screen behind a real [GoRouter] so `context.go(...)`
/// works. The initial route is a placeholder with a recognizable label; the
/// confirmation screen is pushed on top of it (the screen itself has no
/// back button — there's nothing to go back and redo once the order has
/// been sent). Two more placeholder routes stand in for
/// `/patient/orders/:orderId` and `/patient/home` so navigation
/// there can be asserted the same way.
Future<GoRouter> pumpConfirmationScreen(
  WidgetTester tester,
  PharmacyOrderConfirmation confirmation, {
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
            PharmacyOrderConfirmationScreen(confirmation: confirmation),
      ),
      GoRoute(
        path: '/patient/orders/:orderId',
        builder: (context, state) => Scaffold(
          body: Text('order-detail-placeholder:${state.pathParameters['orderId']}'),
        ),
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
  //
  // A single `pumpAndSettle()` isn't enough: while the (large) translation
  // JSON is still loading nothing is scheduled on the fake clock, so it
  // returns immediately and the tree is still empty. Interleave real delays
  // with frame pumps until the expected route is actually mounted.
  await tester.runAsync(() async {
    await EasyLocalization.ensureInitialized();
    await tester.pumpWidget(shell());
    for (var i = 0; i < 200 && !tester.any(find.text('start-placeholder')); i++) {
      await Future<void>.delayed(const Duration(milliseconds: 10));
      await tester.pump(const Duration(milliseconds: 20));
    }
    await tester.pumpAndSettle();

    router.push('/confirmation');
    for (
      var i = 0;
      i < 200 && !tester.any(find.byType(PharmacyOrderConfirmationScreen));
      i++
    ) {
      await Future<void>.delayed(const Duration(milliseconds: 10));
      await tester.pump(const Duration(milliseconds: 20));
    }
    await tester.pumpAndSettle();
  });

  return router;
}

/// Checks whether any `Text`/`RichText` widget currently in the tree renders
/// plain text containing [substring].
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
  const confirmation = PharmacyOrderConfirmation(
    orderNumber: 'PH-2048',
    pharmacyName: 'Alpha Pharmacy',
  );

  testWidgets('renders the success badge, title/subtitle and order number', (
    tester,
  ) async {
    await pumpConfirmationScreen(tester, confirmation);

    expect(find.byIcon(SolarIconsBold.checkCircle), findsOneWidget);
    expect(_anyTextContains(tester, '#PH-2048'), isTrue);
    expect(_anyTextContains(tester, 'Order sent successfully'), isTrue);
    expect(
      _anyTextContains(
        tester,
        "We'll notify you once the pharmacy confirms your prescription "
        'and starts preparing your order.',
      ),
      isTrue,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('shows the ETA label/value and track/go-home CTA labels', (
    tester,
  ) async {
    await pumpConfirmationScreen(tester, confirmation);

    expect(_anyTextContains(tester, 'Delivery time'), isTrue);
    expect(_anyTextContains(tester, 'Set by the pharmacist'), isTrue);
    expect(_anyTextContains(tester, 'Track order'), isTrue);
    expect(_anyTextContains(tester, 'Back to home'), isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Arabic copy renders the exact screenshot strings', (
    tester,
  ) async {
    await pumpConfirmationScreen(
      tester,
      confirmation,
      startLocale: const Locale('ar'),
    );

    expect(_anyTextContains(tester, 'تم إرسال الطلب بنجاح'), isTrue);
    expect(
      _anyTextContains(
        tester,
        'سنقوم بإشعارك بمجرد تأكيد الصيدلية لوصفتك والبدء في تجهيز طلبك.',
      ),
      isTrue,
    );
    expect(_anyTextContains(tester, 'رقم الطلب'), isTrue);
    expect(_anyTextContains(tester, 'مدة التوصيل'), isTrue);
    expect(_anyTextContains(tester, 'يحددها الصيدلي'), isTrue);
    expect(_anyTextContains(tester, 'تتبع الطلب'), isTrue);
    expect(_anyTextContains(tester, 'العودة للرئيسية'), isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'success badge is a teal checkmark circle matching lab_booking style',
    (tester) async {
      await pumpConfirmationScreen(tester, confirmation);

      final icon = tester.widget<Icon>(find.byIcon(SolarIconsBold.checkCircle));
      expect(icon.color, AppColors.tealAccent);

      final badge = tester.widget<Container>(
        find
            .ancestor(
              of: find.byIcon(SolarIconsBold.checkCircle),
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
    'primary CTA uses a delivery-truck icon and secondary uses a home icon',
    (tester) async {
      await pumpConfirmationScreen(tester, confirmation);

      expect(find.byIcon(SolarIconsOutline.delivery), findsOneWidget);
      expect(find.byIcon(SolarIconsOutline.home), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('has no back button — the order is already sent, so there is '
      'nothing to logically go back and redo', (tester) async {
    await pumpConfirmationScreen(tester, confirmation);

    expect(find.byType(IconButton), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'blocks the Android hardware/gesture back button too, not just the '
    'in-app arrow — the screen stays put instead of popping to the '
    'previous route',
    (tester) async {
      await pumpConfirmationScreen(tester, confirmation);

      final popScope = tester.widget<PopScope>(find.byType(PopScope));
      expect(popScope.canPop, isFalse);

      // Simulates the OS-level back button/gesture (as opposed to a
      // Navigator.pop() call from in-app UI) — the same signal `PopScope`
      // intercepts. `canPop: false` should swallow it, so the previous
      // route's placeholder must never appear.
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      expect(find.text('start-placeholder'), findsNothing);
      expect(_anyTextContains(tester, 'Order sent successfully'), isTrue);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'tapping the primary CTA navigates to the order\'s real detail route',
    (tester) async {
      await pumpConfirmationScreen(tester, confirmation);

      await tester.tap(find.byType(FilledButton));
      await tester.pumpAndSettle();

      expect(
        find.text('order-detail-placeholder:${confirmation.orderNumber}'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('tapping "go home" navigates to /patient/home', (tester) async {
    await pumpConfirmationScreen(tester, confirmation);

    await tester.tap(find.byType(OutlinedButton));
    await tester.pumpAndSettle();

    expect(find.text('home-placeholder'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

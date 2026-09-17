import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' show ProviderScope;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:med_super/features/auth/presentation/screens/account_login_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Pumps [AccountLoginScreen] behind a real [GoRouter] (so any `context.go`
/// on success/signup would work, even though the tests below never reach it
/// — they only submit invalid/empty input and assert the surfaced
/// validation text).
///
/// Harness copied from
/// test/features/lab_booking/presentation/screens/lab_booking_confirmation_screen_test.dart
/// to match this repo's existing ProviderScope + EasyLocalization + GoRouter
/// widget-test conventions.
Future<void> pumpAccountLoginScreen(
  WidgetTester tester, {
  Locale startLocale = const Locale('en'),
}) async {
  SharedPreferences.setMockInitialValues({});

  tester.view.physicalSize = const Size(1200, 2400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final router = GoRouter(
    initialLocation: '/account-login',
    routes: [
      GoRoute(
        path: '/account-login',
        builder: (context, state) => const AccountLoginScreen(),
      ),
      GoRoute(
        path: '/',
        builder: (context, state) =>
            const Scaffold(body: Text('home-placeholder')),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) =>
            const Scaffold(body: Text('signup-placeholder')),
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
              // when a Material button is tapped.
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
  // `tester.runAsync` or `.tr()` permanently falls back to the raw key.
  await tester.runAsync(() async {
    await EasyLocalization.ensureInitialized();
    await tester.pumpWidget(shell());
    await tester.pumpAndSettle();
  });
}

void main() {
  testWidgets(
    'submitting with both phone and password empty shows both required '
    'errors',
    (tester) async {
      await pumpAccountLoginScreen(tester);

      await tester.tap(find.text('Log in'));
      await tester.pumpAndSettle();

      expect(find.text('Mobile number is required'), findsOneWidget);
      expect(find.text('Password is required'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'submitting an invalid phone prefix (013) shows the phone-invalid error',
    (tester) async {
      await pumpAccountLoginScreen(tester);

      await tester.enterText(
        find.byType(TextField).first,
        '01312345678',
      );
      await tester.enterText(find.byType(TextFormField), 'Str0ng!Pass');
      await tester.tap(find.text('Log in'));
      await tester.pumpAndSettle();

      expect(find.text('Enter a valid mobile number'), findsOneWidget);
      expect(find.text('Mobile number is required'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'submitting a too-short phone shows the phone-invalid error',
    (tester) async {
      await pumpAccountLoginScreen(tester);

      await tester.enterText(find.byType(TextField).first, '0101234');
      await tester.enterText(find.byType(TextFormField), 'Str0ng!Pass');
      await tester.tap(find.text('Log in'));
      await tester.pumpAndSettle();

      expect(find.text('Enter a valid mobile number'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'a valid phone with an empty password shows only the password-required '
    'error',
    (tester) async {
      await pumpAccountLoginScreen(tester);

      await tester.enterText(find.byType(TextField).first, '01012345678');
      await tester.tap(find.text('Log in'));
      await tester.pumpAndSettle();

      expect(find.text('Password is required'), findsOneWidget);
      expect(find.text('Enter a valid mobile number'), findsNothing);
      expect(find.text('Mobile number is required'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}

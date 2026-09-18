import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' show ProviderScope;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:med_super/features/auth/presentation/screens/set_password_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Pumps [SetPasswordScreen] behind a real [GoRouter] (so any `context.go(...)`
/// on success would work, even though the tests below never reach it — they
/// only submit invalid/empty input and assert the surfaced validation text).
///
/// Harness copied from
/// test/features/lab_booking/presentation/screens/lab_booking_confirmation_screen_test.dart
/// to match this repo's existing ProviderScope + EasyLocalization + GoRouter
/// widget-test conventions.
Future<void> pumpSetPasswordScreen(
  WidgetTester tester, {
  Locale startLocale = const Locale('en'),
}) async {
  SharedPreferences.setMockInitialValues({});

  tester.view.physicalSize = const Size(1200, 2400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final router = GoRouter(
    initialLocation: '/set-password',
    routes: [
      GoRoute(
        path: '/set-password',
        builder: (context, state) =>
            const SetPasswordScreen(phone: '+201012345678'),
      ),
      GoRoute(
        path: '/',
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
    'submitting with both fields empty shows password-required error',
    (tester) async {
      await pumpSetPasswordScreen(tester);

      await tester.tap(find.text('Save & continue'));
      await tester.pumpAndSettle();

      expect(find.text('Password is required'), findsOneWidget);
      expect(find.text('Please confirm your password'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'submitting a too-short password shows the too-short error',
    (tester) async {
      await pumpSetPasswordScreen(tester);

      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), 'Ab1!');
      await tester.enterText(fields.at(1), 'Ab1!');
      await tester.tap(find.text('Save & continue'));
      await tester.pumpAndSettle();

      expect(
        find.text('Password must be at least 8 characters'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'submitting a password missing an uppercase letter shows that error',
    (tester) async {
      await pumpSetPasswordScreen(tester);

      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), 'lowercase1!');
      await tester.enterText(fields.at(1), 'lowercase1!');
      await tester.tap(find.text('Save & continue'));
      await tester.pumpAndSettle();

      expect(find.text('Add at least one uppercase letter'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'submitting a password missing a special character shows that error',
    (tester) async {
      await pumpSetPasswordScreen(tester);

      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), 'Password1');
      await tester.enterText(fields.at(1), 'Password1');
      await tester.tap(find.text('Save & continue'));
      await tester.pumpAndSettle();

      expect(
        find.text('Add at least one special character'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'a valid strong password with a mismatched confirmation shows the '
    'mismatch error, not the password error',
    (tester) async {
      await pumpSetPasswordScreen(tester);

      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), 'Str0ng!Pass');
      await tester.enterText(fields.at(1), 'Different1!');
      await tester.tap(find.text('Save & continue'));
      await tester.pumpAndSettle();

      expect(find.text("Passwords don't match"), findsOneWidget);
      expect(
        find.text('Password must be at least 8 characters'),
        findsNothing,
      );
      expect(tester.takeException(), isNull);
    },
  );
}

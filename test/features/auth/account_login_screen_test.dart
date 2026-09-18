import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' show ProviderScope;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:med_super/core/error/failure.dart';
import 'package:med_super/core/error/result.dart';
import 'package:med_super/core/widgets/auth_role_toggle.dart';
import 'package:med_super/features/auth/domain/entities/user.dart';
import 'package:med_super/features/auth/domain/entities/user_role.dart';
import 'package:med_super/features/auth/presentation/controllers/session_provider.dart';
import 'package:med_super/features/auth/presentation/screens/account_login_screen.dart';
import 'package:med_super/features/auth/presentation/screens/provider_login_screen.dart';
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
  AccountLoginScreen? screen,
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
        builder: (context, state) => screen ?? const AccountLoginScreen(),
      ),
      GoRoute(
        path: '/provider-login',
        builder: (context, state) => const ProviderLoginScreen(),
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

Session _sessionFor(UserRole role) => Session(
  user: User(
    id: 'user-1',
    phone: '+201012345678',
    roles: [role],
    activeRole: role,
    displayName: 'Test user',
  ),
  onboardingComplete: true,
  passwordComplete: true,
);

Future<void> _enterValidCredentials(WidgetTester tester) async {
  await tester.enterText(find.byType(TextField).first, '01012345678');
  await tester.enterText(find.byType(TextFormField), 'Str0ng!Pass');
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

      await tester.enterText(find.byType(TextField).first, '01312345678');
      await tester.enterText(find.byType(TextFormField), 'Str0ng!Pass');
      await tester.tap(find.text('Log in'));
      await tester.pumpAndSettle();

      expect(find.text('Enter a valid mobile number'), findsOneWidget);
      expect(find.text('Mobile number is required'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('submitting a too-short phone shows the phone-invalid error', (
    tester,
  ) async {
    await pumpAccountLoginScreen(tester);

    await tester.enterText(find.byType(TextField).first, '0101234');
    await tester.enterText(find.byType(TextFormField), 'Str0ng!Pass');
    await tester.tap(find.text('Log in'));
    await tester.pumpAndSettle();

    expect(find.text('Enter a valid mobile number'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

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

  testWidgets(
    'patient login has no role selector and shows the provider entry action',
    (tester) async {
      await pumpAccountLoginScreen(tester);

      expect(find.byType(AuthRoleToggle<UserRole>), findsNothing);
      expect(find.text('Patient'), findsNothing);
      expect(find.text('Are you a healthcare provider?'), findsOneWidget);
      expect(find.text('Doctor or Assistant Login'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('provider entry opens a dedicated provider login route', (
    tester,
  ) async {
    await pumpAccountLoginScreen(tester);

    await tester.tap(find.text('Doctor or Assistant Login'));
    await tester.pumpAndSettle();

    expect(find.text('Healthcare provider login'), findsOneWidget);
    expect(find.text('Doctor'), findsOneWidget);
    expect(find.text('Clinic assistant'), findsOneWidget);
    expect(find.byType(AuthRoleToggle<UserRole>), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('patient login submits the patient role', (tester) async {
    UserRole? submittedRole;
    await pumpAccountLoginScreen(
      tester,
      screen: AccountLoginScreen(
        loginHandler: ({required phone, required password, required role}) {
          submittedRole = role;
          return Future.value(Result.ok(_sessionFor(role)));
        },
      ),
    );
    await _enterValidCredentials(tester);

    await tester.tap(find.text('Log in'));
    await tester.pumpAndSettle();

    expect(submittedRole, UserRole.patient);
  });

  testWidgets('provider role switching submits the selected provider role', (
    tester,
  ) async {
    UserRole? submittedRole;
    await pumpAccountLoginScreen(
      tester,
      screen: AccountLoginScreen(
        isProviderLogin: true,
        loginHandler: ({required phone, required password, required role}) {
          submittedRole = role;
          return Future.value(Result.ok(_sessionFor(role)));
        },
      ),
    );
    await tester.tap(find.text('Clinic assistant'));
    await tester.pump();
    await _enterValidCredentials(tester);

    await tester.tap(find.text('Log in'));
    await tester.pumpAndSettle();

    expect(submittedRole, UserRole.clinicStaff);
  });

  testWidgets('a pending login prevents duplicate submissions', (tester) async {
    final completion = Completer<Result<Session>>();
    var calls = 0;
    await pumpAccountLoginScreen(
      tester,
      screen: AccountLoginScreen(
        loginHandler: ({required phone, required password, required role}) {
          calls++;
          return completion.future;
        },
      ),
    );
    await _enterValidCredentials(tester);

    await tester.tap(find.text('Log in'));
    await tester.pump();
    await tester.tap(find.byType(ElevatedButton));
    await tester.pump();

    expect(calls, 1);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    completion.complete(Result.err(Failure.network()));
    await tester.pumpAndSettle();
  });

  testWidgets('login failures remain visible to the user', (tester) async {
    await pumpAccountLoginScreen(
      tester,
      screen: AccountLoginScreen(
        loginHandler: ({required phone, required password, required role}) =>
            Future.value(Result.err(Failure.network())),
      ),
    );
    await _enterValidCredentials(tester);

    await tester.tap(find.text('Log in'));
    await tester.pump();
    await tester.pump();

    expect(find.byType(SnackBar), findsOneWidget);
  });

  testWidgets('Arabic patient login renders without a layout exception', (
    tester,
  ) async {
    await pumpAccountLoginScreen(tester, startLocale: const Locale('ar'));

    expect(find.text('هل أنت مقدم خدمة صحية؟'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

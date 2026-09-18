import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:med_super/features/provider_profile/domain/entities/doctor_profile.dart';
import 'package:med_super/features/provider_profile/presentation/controllers/doctor_availability_providers.dart';
import 'package:med_super/features/provider_profile/presentation/controllers/doctor_profile_providers.dart';
import 'package:med_super/features/provider_profile/presentation/screens/doctor_details_screen.dart';
import 'package:riverpod/misc.dart' show Override;
import 'package:shared_preferences/shared_preferences.dart';

const _doctorId = 'doc-1';
const _clinicBranchId = 'branch-doc-1';

const _profile = DoctorProfile(
  id: _doctorId,
  name: 'Dr. Amina Youssef',
  specialty: 'Cardiology',
  experienceYears: 8,
  rating: 4.8,
  reviewCount: 120,
  clinicName: 'Nile Medical Center',
  bio: 'Bio',
  qualifications: [],
  consultationFee: 300,
  currency: 'EGP',
  isVerified: true,
  availableDays: [],
  affiliations: [],
  clinicBranchId: _clinicBranchId,
  ianaTimezone: 'Africa/Cairo',
);

/// A bounded stand-in for `pumpAndSettle()`.
///
/// Must interleave real `Future.delayed` waits with frame pumps, not just
/// pump frames — `EasyLocalization`'s asset loader reads the translation
/// JSON via real (non-fake-clock) `rootBundle.loadString` I/O, which
/// `tester.pump()`/`pumpAndSettle()` alone never drives to completion (see
/// `test/helpers/pump_localized_widget.dart`'s doc comment for the full
/// explanation). A fixed pump-only loop races that load and silently
/// renders an empty tree (`Localizations` still waiting on its delegate)
/// when it loses.
Future<void> _settle(WidgetTester tester) => tester.runAsync(() async {
  for (var i = 0; i < 200 && find.byType(Scaffold).evaluate().isEmpty; i++) {
    await Future<void>.delayed(const Duration(milliseconds: 10));
    await tester.pump(const Duration(milliseconds: 20));
  }
  for (var i = 0; i < 3; i++) {
    await tester.pump(const Duration(milliseconds: 20));
  }
});

/// Wraps [child] in a real [GoRouter] (so `context.push`/`context.pop` work)
/// — mirrors `pharmacy_select_screen_test.dart`'s `pumpWithRouter` helper.
Future<GoRouter> _pumpWithRouter(
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
      GoRoute(path: '/doctor-details', builder: (context, state) => child),
      GoRoute(
        path: '/patient/home/clinic-branches/:branchId',
        builder: (context, state) => Scaffold(
          body: Text('branch-details-${state.pathParameters['branchId']}'),
        ),
      ),
    ],
  );
  addTearDown(router.dispose);

  Widget shell() => ProviderScope(
    overrides: overrides,
    child: EasyLocalization(
      supportedLocales: const [Locale('ar'), Locale('en')],
      path: 'assets/translations',
      fallbackLocale: const Locale('ar'),
      startLocale: const Locale('ar'),
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

    router.push('/doctor-details');
    for (var i = 0; i < 3; i++) {
      await tester.pump();
    }
    await tester.pumpAndSettle();
  });

  return router;
}

void main() {
  testWidgets(
    'tapping the clinic-affiliation chip navigates to its branch details route',
    (tester) async {
      await _pumpWithRouter(
        tester,
        const DoctorDetailsScreen(doctorId: _doctorId),
        overrides: [
          doctorProfileProvider.overrideWith((ref, id) async => _profile),
          // Empty days so the async availability card resolves immediately
          // without needing a real network/mock round trip.
          doctorAvailabilityProvider.overrideWith((ref, params) async => []),
        ],
      );
      await _settle(tester);

      expect(find.text('Nile Medical Center'), findsOneWidget);

      await tester.tap(find.text('Nile Medical Center'));
      await tester.pumpAndSettle();

      expect(find.text('branch-details-$_clinicBranchId'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}

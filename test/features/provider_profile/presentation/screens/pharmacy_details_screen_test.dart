import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:med_super/core/error/failure.dart';
import 'package:med_super/features/provider_profile/domain/entities/pharmacy_profile.dart';
import 'package:med_super/features/provider_profile/presentation/controllers/pharmacy_providers.dart';
import 'package:med_super/features/provider_profile/presentation/screens/pharmacy_details_screen.dart';
import 'package:riverpod/misc.dart' show Override;
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../helpers/pump_localized_widget.dart';

const _pharmacyId = 'pharmacy-1';

const _pharmacy = PharmacyProfile(
  id: _pharmacyId,
  legalName: 'Nile Pharma LLC',
  brandName: 'Nile Pharmacy',
  status: 'VERIFIED',
  regionCode: 'CAI',
  branches: [
    PharmacyBranchInfo(
      id: 'b1',
      phone: '+201234567890',
      ianaTimezone: 'Africa/Cairo',
      deliveryCapable: true,
      status: 'VERIFIED',
      address: PharmacyAddress(
        line1: '12 Tahrir St',
        city: 'Cairo',
        regionCode: 'CAI',
        countryCode: 'EG',
        geoLat: 30.04,
        geoLng: 31.23,
      ),
    ),
  ],
);

/// Mirrors `clinic_details_screen_test.dart`'s `_settle` helper — a bounded
/// stand-in for `pumpAndSettle()` that won't hang on a perpetual animation.
Future<void> _settle(WidgetTester tester) => tester.runAsync(() async {
  for (var i = 0; i < 10; i++) {
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
      GoRoute(path: '/pharmacy-details', builder: (context, state) => child),
      GoRoute(
        path: '/patient/pharmacy-branches/:branchId',
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

    router.push('/pharmacy-details');
    for (var i = 0; i < 3; i++) {
      await tester.pump();
    }
    await tester.pumpAndSettle();
  });

  return router;
}

void main() {
  testWidgets('shows a loading indicator before the pharmacy resolves', (
    tester,
  ) async {
    final completer = Completer<PharmacyProfile>();

    await pumpLocalizedWidget(
      tester,
      const PharmacyDetailsScreen(pharmacyId: _pharmacyId),
      overrides: [
        pharmacyProfileProvider.overrideWith((ref, id) => completer.future),
      ],
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    completer.complete(_pharmacy);
    await _settle(tester);

    expect(tester.takeException(), isNull);
  });

  testWidgets('renders pharmacy header and branch details once resolved', (
    tester,
  ) async {
    await pumpLocalizedWidget(
      tester,
      const PharmacyDetailsScreen(pharmacyId: _pharmacyId),
      overrides: [
        pharmacyProfileProvider.overrideWith((ref, id) async => _pharmacy),
      ],
    );
    await _settle(tester);

    expect(find.text('Nile Pharmacy'), findsOneWidget);
    expect(find.text('Nile Pharma LLC'), findsOneWidget);
    expect(find.text('12 Tahrir St'), findsOneWidget);
    expect(find.text('+201234567890'), findsOneWidget);
    expect(find.text('Africa/Cairo'), findsOneWidget);
    expect(find.byIcon(Icons.verified), findsOneWidget);
    // delivery_capable is true on the seeded branch — its chip must render.
    expect(find.byIcon(Icons.local_shipping_outlined), findsOneWidget);

    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'hides the delivery chip when the branch is not delivery-capable',
    (tester) async {
      const pharmacy = PharmacyProfile(
        id: _pharmacyId,
        legalName: 'L',
        brandName: 'B',
        status: 'VERIFIED',
        branches: [
          PharmacyBranchInfo(
            id: 'b1',
            phone: '+2010',
            ianaTimezone: 'Africa/Cairo',
            deliveryCapable: false,
            status: 'VERIFIED',
            address: PharmacyAddress(
              line1: 'X',
              city: 'Y',
              regionCode: 'CAI',
              countryCode: 'EG',
            ),
          ),
        ],
      );

      await pumpLocalizedWidget(
        tester,
        const PharmacyDetailsScreen(pharmacyId: _pharmacyId),
        overrides: [
          pharmacyProfileProvider.overrideWith((ref, id) async => pharmacy),
        ],
      );
      await _settle(tester);

      expect(find.byIcon(Icons.local_shipping_outlined), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('shows an empty state when the pharmacy has no branches', (
    tester,
  ) async {
    await pumpLocalizedWidget(
      tester,
      const PharmacyDetailsScreen(pharmacyId: _pharmacyId),
      overrides: [
        pharmacyProfileProvider.overrideWith(
          (ref, id) async => const PharmacyProfile(
            id: _pharmacyId,
            legalName: 'L',
            brandName: 'B',
            status: 'VERIFIED',
            branches: [],
          ),
        ),
      ],
    );
    await _settle(tester);

    expect(find.text('pharmacy_profile.no_branches'.tr()), findsOneWidget);

    expect(tester.takeException(), isNull);
  });

  testWidgets('shows a retry-able error banner when the load fails', (
    tester,
  ) async {
    await pumpLocalizedWidget(
      tester,
      const PharmacyDetailsScreen(pharmacyId: _pharmacyId),
      overrides: [
        pharmacyProfileProvider.overrideWith(
          (ref, id) async => throw const Failure.network(),
        ),
      ],
    );
    await _settle(tester);

    expect(find.text('Retry'), findsOneWidget);
    expect(
      find.text('No internet connection. Check your network and try again.'),
      findsOneWidget,
    );

    expect(tester.takeException(), isNull);
  });

  testWidgets('tapping a branch card navigates to its branch details route', (
    tester,
  ) async {
    await _pumpWithRouter(
      tester,
      const PharmacyDetailsScreen(pharmacyId: _pharmacyId),
      overrides: [
        pharmacyProfileProvider.overrideWith((ref, id) async => _pharmacy),
      ],
    );
    await _settle(tester);

    await tester.tap(find.text('Cairo'));
    await tester.pumpAndSettle();

    expect(find.text('branch-details-b1'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

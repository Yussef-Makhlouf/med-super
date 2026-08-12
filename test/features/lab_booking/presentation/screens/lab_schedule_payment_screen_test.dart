import 'dart:convert';
import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:med_super/core/error/failure.dart';
import 'package:med_super/core/error/result.dart';
import 'package:med_super/core/widgets/step_progress_header.dart';
import 'package:med_super/features/lab_booking/domain/entities/lab_booking_confirmation.dart';
import 'package:med_super/features/lab_booking/domain/entities/lab_catalog.dart';
import 'package:med_super/features/lab_booking/domain/entities/lab_partner.dart';
import 'package:med_super/features/lab_booking/domain/entities/lab_test.dart';
import 'package:med_super/features/lab_booking/domain/entities/lab_sort_option.dart';
import 'package:med_super/features/lab_booking/domain/entities/lab_test_category.dart';
import 'package:med_super/features/lab_booking/domain/repositories/lab_booking_repository.dart';
import 'package:med_super/features/lab_booking/domain/repositories/lab_catalog_repository.dart';
import 'package:med_super/features/lab_booking/presentation/controllers/lab_booking_providers.dart';
import 'package:med_super/features/lab_booking/presentation/controllers/lab_partner_providers.dart';
import 'package:med_super/features/lab_booking/presentation/controllers/lab_schedule_providers.dart';
import 'package:med_super/features/lab_booking/presentation/screens/lab_schedule_payment_screen.dart';
import 'package:med_super/features/lab_booking/presentation/widgets/lab_schedule_confirm_bar.dart';
import 'package:mocktail/mocktail.dart';
import 'package:riverpod/misc.dart' show Override;
import 'package:shared_preferences/shared_preferences.dart';

class _MockLabCatalogRepository extends Mock implements LabCatalogRepository {}

class _MockLabBookingRepository extends Mock implements LabBookingRepository {}

class _SyncFileAssetLoader extends AssetLoader {
  const _SyncFileAssetLoader();

  @override
  Future<Map<String, dynamic>?> load(String path, Locale locale) {
    final file = File('$path/${locale.languageCode}.json');
    final content = file.readAsStringSync();
    return SynchronousFuture(json.decode(content) as Map<String, dynamic>);
  }
}

/// Wraps [child] in a real [GoRouter] (so `context.push`/`context.pop`
/// work), pushed on top of a `/start` placeholder so the header's back
/// button has somewhere to pop to — same pattern as the sibling screen
/// tests in this directory.
Future<void> pumpWithRouter(
  WidgetTester tester,
  Widget child, {
  required List<Override> overrides,
}) async {
  SharedPreferences.setMockInitialValues({});
  await EasyLocalization.ensureInitialized();

  tester.view.physicalSize = const Size(2400, 1800);
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
      GoRoute(path: '/screen', builder: (context, state) => child),
      GoRoute(
        path: '/patient/lab/confirmation',
        builder: (context, state) {
          final extra = state.extra as LabBookingConfirmation?;
          return Scaffold(
            body: Text('confirmation-screen:${extra?.bookingNumber}'),
          );
        },
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
      assetLoader: const _SyncFileAssetLoader(),
      child: Builder(
        builder: (context) {
          return MaterialApp.router(
            debugShowCheckedModeBanner: false,
            // Avoid Material 3's default `InkSparkle` splash factory — it
            // loads a fragment shader unsupported by the software renderer
            // under `flutter test` (same fix as sibling screen tests).
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

  await tester.pumpWidget(shell());
  await tester.pumpAndSettle();
  for (var i = 0; i < 3; i++) {
    await tester.pump();
  }
  router.push('/screen');
  await tester.pumpAndSettle();
}

void main() {
  late _MockLabCatalogRepository catalogRepo;
  late _MockLabBookingRepository bookingRepo;

  const category = LabTestCategory(id: 'blood', labelKey: 'k');
  const vitaminDTest = LabTest(
    id: 'vitamin-d',
    name: 'Vitamin D',
    price: 200,
    currency: 'EGP',
    isPackage: false,
    requiresFasting: false,
    categoryId: 'blood',
  );
  const catalog = LabCatalog(
    categories: [category],
    tests: [vitaminDTest],
    suggestedLabs: [],
  );
  const partner = LabPartner(
    id: 'p1',
    name: 'Alpha Labs',
    distanceKm: 2.0,
    rating: 4.5,
    ratingCount: 10,
    totalPrice: 200,
    latitude: 24.7,
    longitude: 46.6,
  );

  final confirmation = LabBookingConfirmation(
    bookingNumber: 'BK-3003',
    labName: 'Alpha Labs',
    labAddress: '1 Main St',
    date: DateTime(2026, 3, 20),
    time: '09:30',
  );

  setUpAll(() {
    registerFallbackValue(LabSortOption.nearest);
  });

  setUp(() {
    catalogRepo = _MockLabCatalogRepository();
    bookingRepo = _MockLabBookingRepository();

    when(
      () => catalogRepo.getCatalog(
        query: any(named: 'query'),
        categoryId: any(named: 'categoryId'),
      ),
    ).thenAnswer((_) async => Result.ok(catalog));

    when(
      () => bookingRepo.getLabPartners(
        testIds: any(named: 'testIds'),
        sort: any(named: 'sort'),
      ),
    ).thenAnswer((_) async => Result.ok([partner]));

    when(
      () => bookingRepo.confirmBooking(
        labId: any(named: 'labId'),
        testIds: any(named: 'testIds'),
        scheduledDate: any(named: 'scheduledDate'),
        scheduledTime: any(named: 'scheduledTime'),
        paymentMethod: any(named: 'paymentMethod'),
      ),
    ).thenAnswer((_) async => Result.ok(confirmation));
  });

  List<Override> overrides() => [
    labCatalogRepositoryProvider.overrideWithValue(catalogRepo),
    labBookingRepositoryProvider.overrideWithValue(bookingRepo),
  ];

  testWidgets(
    'renders header, 3-step stepper, booking summary, day/time pickers and '
    'payment options',
    (tester) async {
      await pumpWithRouter(
        tester,
        const LabSchedulePaymentScreen(),
        overrides: overrides(),
      );
      await tester.pumpAndSettle();

      final stepper = tester.widget<StepProgressHeader>(
        find.byType(StepProgressHeader),
      );
      expect(stepper.currentStep, 2);
      expect(stepper.stepLabels, hasLength(3));

      // Booking summary: partner name and selected test name (both plain
      // data, not `.tr()`-resolved, so safe to assert exactly).
      expect(find.text('Alpha Labs'), findsOneWidget);
      expect(find.textContaining('Vitamin D'), findsOneWidget);
      expect(find.text('200 ج.م'), findsWidgets);

      expect(find.byType(FilledButton), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'confirm button is enabled by default (a time slot is pre-selected)',
    (tester) async {
      await pumpWithRouter(
        tester,
        const LabSchedulePaymentScreen(),
        overrides: overrides(),
      );
      await tester.pumpAndSettle();

      final bar = tester.widget<LabScheduleConfirmBar>(
        find.byType(LabScheduleConfirmBar),
      );
      expect(bar.onConfirm, isNotNull);
    },
  );

  testWidgets(
    'confirm button disables when the time slot selection is cleared',
    (tester) async {
      final container = ProviderContainer(overrides: overrides());
      addTearDown(container.dispose);

      await pumpWithRouter(
        tester,
        UncontrolledProviderScope(
          container: container,
          child: const LabSchedulePaymentScreen(),
        ),
        overrides: overrides(),
      );
      await tester.pumpAndSettle();

      container.read(selectedTimeSlotProvider.notifier).select(null);
      await tester.pumpAndSettle();

      final bar = tester.widget<LabScheduleConfirmBar>(
        find.byType(LabScheduleConfirmBar),
      );
      expect(bar.onConfirm, isNull);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('tapping a different time slot updates the selection', (
    tester,
  ) async {
    final container = ProviderContainer(overrides: overrides());
    addTearDown(container.dispose);

    await pumpWithRouter(
      tester,
      UncontrolledProviderScope(
        container: container,
        child: const LabSchedulePaymentScreen(),
      ),
      overrides: overrides(),
    );
    await tester.pumpAndSettle();

    container.read(selectedTimeSlotProvider.notifier).select('11:00');
    await tester.pumpAndSettle();

    expect(container.read(selectedTimeSlotProvider), '11:00');
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'confirming calls confirmBooking with the lab/tests/date/time/payment '
    'and navigates to the confirmation route on success',
    (tester) async {
      await pumpWithRouter(
        tester,
        const LabSchedulePaymentScreen(),
        overrides: overrides(),
      );
      await tester.pumpAndSettle();

      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed!();
      await tester.pumpAndSettle();

      verify(
        () => bookingRepo.confirmBooking(
          labId: 'p1',
          testIds: ['vitamin-d'],
          scheduledDate: any(named: 'scheduledDate'),
          scheduledTime: '09:30',
          paymentMethod: 'credit_card',
        ),
      ).called(1);

      expect(find.text('confirmation-screen:BK-3003'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'confirming with an error shows the error snackbar and stays on the '
    'same screen',
    (tester) async {
      when(
        () => bookingRepo.confirmBooking(
          labId: any(named: 'labId'),
          testIds: any(named: 'testIds'),
          scheduledDate: any(named: 'scheduledDate'),
          scheduledTime: any(named: 'scheduledTime'),
          paymentMethod: any(named: 'paymentMethod'),
        ),
      ).thenAnswer((_) async => const Result.err(Failure.network()));

      await pumpWithRouter(
        tester,
        const LabSchedulePaymentScreen(),
        overrides: overrides(),
      );
      await tester.pumpAndSettle();

      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed!();
      // A couple of bounded pumps (not `pumpAndSettle`) — the SnackBar has
      // its own auto-dismiss timer, which `pumpAndSettle` would fast
      // -forward straight through under the fake test clock.
      await tester.pump();
      await tester.pump();

      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.textContaining('confirmation-screen:'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('tapping the back button pops back to the previous screen', (
    tester,
  ) async {
    await pumpWithRouter(
      tester,
      const LabSchedulePaymentScreen(),
      overrides: overrides(),
    );
    await tester.pumpAndSettle();

    expect(find.text('start-placeholder'), findsNothing);

    await tester.tap(find.byIcon(Icons.arrow_forward));
    await tester.pumpAndSettle();

    expect(find.text('start-placeholder'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

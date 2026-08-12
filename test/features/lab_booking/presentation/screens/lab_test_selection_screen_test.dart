import 'dart:async';
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
import 'package:med_super/features/lab_booking/domain/entities/lab_test.dart';
import 'package:med_super/features/lab_booking/domain/entities/lab_test_category.dart';
import 'package:med_super/features/lab_booking/domain/entities/suggested_lab.dart';
import 'package:med_super/features/lab_booking/domain/repositories/lab_booking_repository.dart';
import 'package:med_super/features/lab_booking/domain/repositories/lab_catalog_repository.dart';
import 'package:med_super/features/lab_booking/presentation/controllers/lab_booking_providers.dart';
import 'package:med_super/features/lab_booking/presentation/controllers/lab_partner_providers.dart';
import 'package:med_super/features/lab_booking/presentation/screens/lab_test_selection_screen.dart';
import 'package:med_super/features/lab_booking/presentation/widgets/category_chip_bar.dart';
import 'package:med_super/features/lab_booking/presentation/widgets/lab_booking_bottom_bar.dart';
import 'package:med_super/features/lab_booking/presentation/widgets/selectable_test_card.dart';
import 'package:med_super/features/lab_booking/presentation/widgets/suggested_lab_card.dart';
import 'package:mocktail/mocktail.dart';
import 'package:riverpod/misc.dart' show Override;
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../helpers/pump_localized_widget.dart';

class _MockLabCatalogRepository extends Mock implements LabCatalogRepository {}

class _MockLabBookingRepository extends Mock implements LabBookingRepository {}

/// Same synchronous asset loader as `pump_localized_widget.dart`, needed
/// again here because navigation tests build their own `MaterialApp.router`
/// shell instead of going through `pumpLocalizedWidget`.
class _SyncFileAssetLoader extends AssetLoader {
  const _SyncFileAssetLoader();

  @override
  Future<Map<String, dynamic>?> load(String path, Locale locale) {
    final file = File('$path/${locale.languageCode}.json');
    final content = file.readAsStringSync();
    return SynchronousFuture(json.decode(content) as Map<String, dynamic>);
  }
}

/// Wraps [child] in a real [GoRouter] (so `context.push`/`context.pop` work)
/// plus the same EasyLocalization/ProviderScope shell `pumpLocalizedWidget`
/// builds internally. Only used by tests that assert on navigation —
/// everything else uses `pumpLocalizedWidget` directly.
Future<GoRouter> pumpWithRouter(
  WidgetTester tester,
  Widget child, {
  required List<Override> overrides,
}) async {
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
      GoRoute(path: '/screen', builder: (context, state) => child),
      GoRoute(
        path: '/patient/lab/select-lab',
        builder: (context, state) =>
            const Scaffold(body: Text('select-lab-screen')),
      ),
      GoRoute(
        path: '/patient/lab/schedule-payment',
        builder: (context, state) =>
            const Scaffold(body: Text('schedule-payment-screen')),
      ),
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
            // Avoid Material 3's default `InkSparkle` splash factory here:
            // it loads a fragment shader asset that isn't supported by the
            // software renderer used under `flutter test`, which throws when
            // a Material button/IconButton is tapped. Swapping to
            // `InkRipple` is purely cosmetic and doesn't affect anything
            // this test suite asserts on (same fix as
            // lab_booking_confirmation_screen_test.dart).
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
  // Push the real screen on top of the `/start` placeholder instead of
  // rendering it as the initial route, so `context.pop()` (the header's
  // back button) has somewhere to pop back to — matches how the screen is
  // always reached in the real app (pushed from somewhere), and mirrors
  // the same pattern already used in
  // lab_booking_confirmation_screen_test.dart.
  router.push('/screen');
  await tester.pumpAndSettle();
  return router;
}

void main() {
  late _MockLabCatalogRepository catalogRepo;
  late _MockLabBookingRepository bookingRepo;

  const category = LabTestCategory(id: 'packages', labelKey: 'k');
  const vitaminDTest = LabTest(
    id: 'vitamin-d',
    name: 'Vitamin D',
    price: 200,
    currency: 'EGP',
    isPackage: false,
    requiresFasting: false,
    categoryId: 'packages',
  );
  const cheapTest = LabTest(
    id: 'cheap',
    name: 'Cheap Test',
    price: 100,
    currency: 'EGP',
    isPackage: true,
    requiresFasting: true,
    categoryId: 'packages',
    includesCount: 3,
    fastingHours: 8,
    resultHours: 24,
  );
  const suggestedLab = SuggestedLab(
    id: 'lab-1',
    name: 'Alpha Lab',
    distanceKm: 1.5,
    rating: 4.5,
  );
  const catalog = LabCatalog(
    categories: [category],
    tests: [vitaminDTest, cheapTest],
    suggestedLabs: [suggestedLab],
  );

  final confirmation = LabBookingConfirmation(
    bookingNumber: 'BK-2002',
    labName: 'Alpha Lab',
    labAddress: '456 Main St',
    date: DateTime(2026, 8, 20),
    time: '10:00',
  );

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
      () => bookingRepo.confirmBooking(
        labId: any(named: 'labId'),
        testIds: any(named: 'testIds'),
      ),
    ).thenAnswer((_) async => Result.ok(confirmation));
  });

  List<Override> overrides() => [
    labCatalogRepositoryProvider.overrideWithValue(catalogRepo),
    labBookingRepositoryProvider.overrideWithValue(bookingRepo),
  ];

  testWidgets(
    'renders header, stepper, search field, category chips, test cards, '
    'suggested labs and the bottom bar with selected count/total',
    (tester) async {
      await pumpLocalizedWidget(
        tester,
        const LabTestSelectionScreen(),
        overrides: overrides(),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.arrow_forward), findsOneWidget);
      // The header's help icon was removed in favor of the back button
      // occupying that slot.
      expect(find.byIcon(Icons.help_outline), findsNothing);

      final stepper = tester.widget<StepProgressHeader>(
        find.byType(StepProgressHeader),
      );
      expect(stepper.currentStep, 0);
      expect(stepper.stepLabels, hasLength(3));

      expect(find.byType(TextField), findsOneWidget);
      expect(find.byType(CategoryChipBar), findsOneWidget);

      expect(find.byType(SelectableTestCard), findsNWidgets(catalog.tests.length));
      expect(find.text('Vitamin D'), findsOneWidget);
      expect(find.text('Cheap Test'), findsOneWidget);

      expect(
        find.byType(SuggestedLabCard),
        findsNWidgets(catalog.suggestedLabs.length),
      );
      expect(find.text('Alpha Lab'), findsOneWidget);

      final bottomBar = tester.widget<LabBookingBottomBar>(
        find.byType(LabBookingBottomBar),
      );
      // Default selection is {'vitamin-d'} per SelectedLabTests.build().
      expect(bottomBar.selectedCount, 1);
      expect(bottomBar.totalPrice, vitaminDTest.price);

      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('shows a loading spinner before the catalog resolves', (
    tester,
  ) async {
    final completer = Completer<Result<LabCatalog>>();
    when(
      () => catalogRepo.getCatalog(
        query: any(named: 'query'),
        categoryId: any(named: 'categoryId'),
      ),
    ).thenAnswer((_) => completer.future);

    await tester.runAsync(() async {
      await pumpLocalizedWidget(
        tester,
        const LabTestSelectionScreen(),
        overrides: overrides(),
      );

      expect(find.byType(CircularProgressIndicator), findsWidgets);
      expect(find.byType(SelectableTestCard), findsNothing);

      completer.complete(Result.ok(catalog));
      await tester.pumpAndSettle();

      expect(find.byType(SelectableTestCard), findsNWidgets(catalog.tests.length));
      expect(tester.takeException(), isNull);
    });
  });

  testWidgets('renders an error view instead of crashing when the catalog fails', (
    tester,
  ) async {
    when(
      () => catalogRepo.getCatalog(
        query: any(named: 'query'),
        categoryId: any(named: 'categoryId'),
      ),
    ).thenAnswer((_) async => const Result.err(Failure.network()));

    await pumpLocalizedWidget(
      tester,
      const LabTestSelectionScreen(),
      overrides: overrides(),
    );
    await tester.pumpAndSettle();

    expect(find.byType(SelectableTestCard), findsNothing);
    expect(find.byType(SuggestedLabCard), findsNothing);
    expect(tester.takeException(), isNull);

    // The screen's search field (and its controller) only get built once
    // `AsyncValueView`'s `data` branch renders, which never happens while
    // the catalog is erroring. Leaving the widget stuck in the error state
    // all the way to teardown would tear down a screen that never built its
    // `TextField`/controller — resolve the catalog via the error banner's
    // retry action before the test ends so the widget is disposed from a
    // normal, fully-built state like every other test in this file.
    when(
      () => catalogRepo.getCatalog(
        query: any(named: 'query'),
        categoryId: any(named: 'categoryId'),
      ),
    ).thenAnswer((_) async => Result.ok(catalog));
    // Invoke the retry callback directly instead of `tester.tap` — a real
    // tap paints an `InkWell` splash, and this suite's default
    // `pumpLocalizedWidget` shell (unlike the router-wrapped shell below)
    // uses Material 3's default `InkSparkle` splash factory, which throws
    // trying to load a fragment shader unsupported by the software renderer
    // under `flutter test`. Calling the callback exercises the same retry
    // logic without ever painting a splash.
    final retryButton = tester.widget<TextButton>(
      find.widgetWithText(TextButton, 'Retry'),
    );
    retryButton.onPressed!();
    await tester.pumpAndSettle();

    expect(find.byType(SelectableTestCard), findsNWidgets(catalog.tests.length));
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'shows an empty state instead of a blank list when the catalog has no '
    'tests (e.g. a search with no results)',
    (tester) async {
      when(
        () => catalogRepo.getCatalog(
          query: any(named: 'query'),
          categoryId: any(named: 'categoryId'),
        ),
      ).thenAnswer(
        (_) async => Result.ok(
          const LabCatalog(categories: [category], tests: [], suggestedLabs: [suggestedLab]),
        ),
      );

      await pumpLocalizedWidget(
        tester,
        const LabTestSelectionScreen(),
        overrides: overrides(),
      );
      await tester.pumpAndSettle();

      expect(find.byType(SelectableTestCard), findsNothing);
      expect(find.byIcon(Icons.search_off), findsOneWidget);
      // Suggested labs are unrelated to the test search and must still
      // render even when the test list itself is empty.
      expect(find.byType(SuggestedLabCard), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('typing in the search field re-fetches the catalog with the query', (
    tester,
  ) async {
    await pumpLocalizedWidget(
      tester,
      const LabTestSelectionScreen(),
      overrides: overrides(),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'xyz');
    await tester.pumpAndSettle();

    verify(
      () => catalogRepo.getCatalog(
        query: 'xyz',
        categoryId: any(named: 'categoryId'),
      ),
    ).called(greaterThanOrEqualTo(1));

    expect(tester.takeException(), isNull);
  });

  testWidgets('tapping a category chip re-fetches the catalog with that category', (
    tester,
  ) async {
    const otherCategory = LabTestCategory(id: 'vitamins', labelKey: 'k2');
    const catalogWithTwoCategories = LabCatalog(
      categories: [category, otherCategory],
      tests: [vitaminDTest, cheapTest],
      suggestedLabs: [suggestedLab],
    );
    when(
      () => catalogRepo.getCatalog(
        query: any(named: 'query'),
        categoryId: any(named: 'categoryId'),
      ),
    ).thenAnswer((_) async => Result.ok(catalogWithTwoCategories));

    await pumpLocalizedWidget(
      tester,
      const LabTestSelectionScreen(),
      overrides: overrides(),
    );
    await tester.pumpAndSettle();

    // Invoke `onSelected` directly instead of `tester.tap` — a real tap
    // paints a `ChoiceChip` ripple, and this suite's default
    // `pumpLocalizedWidget` shell uses Material 3's default `InkSparkle`
    // splash factory, which throws trying to load a fragment shader
    // unsupported by the software renderer under `flutter test`.
    final chip = tester.widget<ChoiceChip>(find.byType(ChoiceChip).last);
    chip.onSelected!(true);
    await tester.pumpAndSettle();

    verify(
      () => catalogRepo.getCatalog(
        query: any(named: 'query'),
        categoryId: 'vitamins',
      ),
    ).called(greaterThanOrEqualTo(1));

    expect(tester.takeException(), isNull);
  });

  testWidgets('tapping a test card toggles its selection and updates the bottom bar', (
    tester,
  ) async {
    await pumpLocalizedWidget(
      tester,
      const LabTestSelectionScreen(),
      overrides: overrides(),
    );
    await tester.pumpAndSettle();

    // 'vitamin-d' is pre-selected by default; toggle the other (unselected)
    // card ('Cheap Test') to add it to the selection. Invoking the
    // callback directly instead of `tester.tap` avoids painting an
    // `InkWell` splash, which throws under this Material 3/software
    // renderer combination in `flutter test` (same fix as elsewhere in
    // this file).
    SelectableTestCard cardFor(String name) => tester.widget<SelectableTestCard>(
      find.widgetWithText(SelectableTestCard, name),
    );
    cardFor('Cheap Test').onToggle();
    await tester.pumpAndSettle();

    var bottomBar = tester.widget<LabBookingBottomBar>(
      find.byType(LabBookingBottomBar),
    );
    expect(bottomBar.selectedCount, 2);
    expect(bottomBar.totalPrice, vitaminDTest.price + cheapTest.price);

    // Toggle it again to remove it.
    cardFor('Cheap Test').onToggle();
    await tester.pumpAndSettle();

    bottomBar = tester.widget<LabBookingBottomBar>(
      find.byType(LabBookingBottomBar),
    );
    expect(bottomBar.selectedCount, 1);
    expect(bottomBar.totalPrice, vitaminDTest.price);

    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'bottom bar continue is disabled when nothing is selected, enabled otherwise',
    (tester) async {
      await pumpLocalizedWidget(
        tester,
        const LabTestSelectionScreen(),
        overrides: overrides(),
      );
      await tester.pumpAndSettle();

      // Default selection has one test -> continue is enabled.
      var bottomBar = tester.widget<LabBookingBottomBar>(
        find.byType(LabBookingBottomBar),
      );
      expect(bottomBar.onContinue, isNotNull);

      // Deselect the only selected test ('Vitamin D'); invoke the callback
      // directly rather than `tester.tap` (see comment above on the
      // `InkSparkle` shader issue under `flutter test`).
      tester
          .widget<SelectableTestCard>(
            find.widgetWithText(SelectableTestCard, 'Vitamin D'),
          )
          .onToggle();
      await tester.pumpAndSettle();

      bottomBar = tester.widget<LabBookingBottomBar>(
        find.byType(LabBookingBottomBar),
      );
      expect(bottomBar.selectedCount, 0);
      expect(bottomBar.onContinue, isNull);

      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'tapping continue with a selection navigates to the select-lab route',
    (tester) async {
      await pumpWithRouter(
        tester,
        const LabTestSelectionScreen(),
        overrides: overrides(),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(FilledButton));
      await tester.pumpAndSettle();

      // `router.routeInformationProvider`/`currentConfiguration` lag behind
      // an imperative `context.push` in this go_router version — assert on
      // the pushed screen's content instead, which is what actually matters.
      expect(find.text('select-lab-screen'), findsOneWidget);

      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'tapping "view all" navigates to the select-lab route',
    (tester) async {
      await pumpWithRouter(
        tester,
        const LabTestSelectionScreen(),
        overrides: overrides(),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(TextButton));
      await tester.pumpAndSettle();

      expect(find.text('select-lab-screen'), findsOneWidget);

      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'tapping a suggested lab\'s add button with an empty selection shows a '
    'snackbar and does not confirm the booking',
    (tester) async {
      await pumpLocalizedWidget(
        tester,
        const LabTestSelectionScreen(),
        overrides: overrides(),
      );
      await tester.pumpAndSettle();

      // Deselect the only default-selected test to make the selection empty.
      // Invoke the card's callback directly rather than `tester.tap` — a
      // real tap paints an `InkWell` splash, and this suite's default
      // `pumpLocalizedWidget` shell uses Material 3's default `InkSparkle`
      // splash factory, which throws trying to load a fragment shader
      // unsupported by the software renderer under `flutter test` (same
      // fix as the category-chip/retry-button tests above).
      final vitaminDCard = tester.widget<SelectableTestCard>(
        find.widgetWithText(SelectableTestCard, 'Vitamin D'),
      );
      vitaminDCard.onToggle();
      await tester.pumpAndSettle();

      final addButton = tester.widget<IconButton>(
        find.byType(IconButton).last,
      );
      addButton.onPressed!();
      // A couple of bounded `pump()`s (not `pumpAndSettle()`) — the first
      // lets any pending microtask (e.g. the mocked repository call's
      // Future) resolve and the SnackBar's overlay entry get scheduled, the
      // second renders it; `pumpAndSettle` runs until no more frames are
      // scheduled at all, which under the fake test clock fast-forwards
      // straight through the SnackBar's own auto-dismiss timer too.
      await tester.pump();
      await tester.pump();

      // The SnackBar's copy is `.tr()`-resolved, which — per the same
      // translation-timing caveat noted throughout this codebase's tests
      // (see test/helpers/pump_localized_widget.dart) — can fall back to
      // the raw key instead of the English string; assert the SnackBar
      // itself appeared, not its exact text.
      expect(find.byType(SnackBar), findsOneWidget);
      verifyNever(
        () => bookingRepo.confirmBooking(
          labId: any(named: 'labId'),
          testIds: any(named: 'testIds'),
        ),
      );

      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'tapping a suggested lab\'s add button with a selection selects that '
    'lab and navigates to the schedule & payment route',
    (tester) async {
      await pumpWithRouter(
        tester,
        const LabTestSelectionScreen(),
        overrides: overrides(),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(IconButton).last);
      await tester.pumpAndSettle();

      // Booking confirmation now happens on the schedule & payment step,
      // not here — adding a suggested lab just records the choice and
      // moves on.
      verifyNever(
        () => bookingRepo.confirmBooking(
          labId: any(named: 'labId'),
          testIds: any(named: 'testIds'),
        ),
      );
      expect(find.text('schedule-payment-screen'), findsOneWidget);

      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('tapping the back button pops back to the previous screen', (
    tester,
  ) async {
    await pumpWithRouter(
      tester,
      const LabTestSelectionScreen(),
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

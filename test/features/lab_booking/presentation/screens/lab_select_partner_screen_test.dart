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
import 'package:med_super/features/lab_booking/domain/entities/lab_partner.dart';
import 'package:med_super/features/lab_booking/domain/entities/lab_sort_option.dart';
import 'package:med_super/features/lab_booking/domain/entities/lab_test.dart';
import 'package:med_super/features/lab_booking/domain/repositories/lab_booking_repository.dart';
import 'package:med_super/features/lab_booking/domain/repositories/lab_catalog_repository.dart';
import 'package:med_super/features/lab_booking/presentation/controllers/lab_booking_providers.dart';
import 'package:med_super/features/lab_booking/presentation/controllers/lab_partner_providers.dart';
import 'package:med_super/features/lab_booking/presentation/screens/lab_select_partner_screen.dart';
import 'package:med_super/features/lab_booking/presentation/widgets/lab_confirm_bottom_bar.dart';
import 'package:med_super/features/lab_booking/presentation/widgets/lab_partner_card.dart';
import 'package:med_super/features/lab_booking/presentation/widgets/lab_partners_map_view.dart';
import 'package:med_super/features/lab_booking/presentation/widgets/lab_sort_chip_bar.dart';
import 'package:mocktail/mocktail.dart';
import 'package:riverpod/misc.dart' show Override;
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../helpers/pump_localized_widget.dart';

class _MockLabBookingRepository extends Mock implements LabBookingRepository {}

class _MockLabCatalogRepository extends Mock implements LabCatalogRepository {}

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
///
/// The initial route is a placeholder with a recognizable label; [child] is
/// pushed on top of it (mirroring
/// `lab_booking_confirmation_screen_test.dart`'s `pumpConfirmationScreen`
/// helper) so tapping the back arrow can be verified by that placeholder
/// reappearing, instead of hitting go_router's "nothing to pop" error on a
/// single-route stack.
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
        builder: (context, state) =>
            const Scaffold(body: Text('start-placeholder')),
      ),
      GoRoute(path: '/select-lab', builder: (context, state) => child),
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

  router.push('/select-lab');
  for (var i = 0; i < 3; i++) {
    await tester.pump();
  }
  await tester.pumpAndSettle();

  return router;
}

void main() {
  setUpAll(() {
    registerFallbackValue(LabSortOption.nearest);
  });

  late _MockLabBookingRepository bookingRepo;
  late _MockLabCatalogRepository catalogRepo;

  const partners = [
    LabPartner(
      id: 'p1',
      name: 'Alpha Lab',
      distanceKm: 1.2,
      rating: 4.8,
      ratingCount: 120,
      totalPrice: 300,
      latitude: 24.71,
      longitude: 46.67,
    ),
    LabPartner(
      id: 'p2',
      name: 'Beta Lab',
      distanceKm: 3.4,
      rating: 4.2,
      ratingCount: 40,
      totalPrice: 250,
      latitude: 24.72,
      longitude: 46.68,
    ),
  ];

  const catalog = LabCatalog(
    categories: [],
    tests: [
      LabTest(
        id: 'vitamin-d',
        name: 'Vitamin D',
        price: 150,
        currency: 'EGP',
        isPackage: false,
        requiresFasting: false,
        categoryId: 'vitamins',
      ),
    ],
    suggestedLabs: [],
  );

  final confirmation = LabBookingConfirmation(
    bookingNumber: 'BK-1001',
    labName: 'Alpha Lab',
    labAddress: '123 Main St',
    date: DateTime(2026, 8, 20),
    time: '10:00',
  );

  /// Scopes an [Icons.check] search to a single [LabPartnerCard] — the
  /// screen also renders sort chips, whose Material 3 [ChoiceChip] already
  /// paints its own check icon when selected, so a bare
  /// `find.byIcon(Icons.check)` over-matches.
  Finder checkIconIn(Finder card) =>
      find.descendant(of: card, matching: find.byIcon(Icons.check));

  setUp(() {
    bookingRepo = _MockLabBookingRepository();
    catalogRepo = _MockLabCatalogRepository();

    when(
      () => bookingRepo.getLabPartners(
        testIds: any(named: 'testIds'),
        sort: any(named: 'sort'),
      ),
    ).thenAnswer((_) async => Result.ok(partners));

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
    labBookingRepositoryProvider.overrideWithValue(bookingRepo),
    labCatalogRepositoryProvider.overrideWithValue(catalogRepo),
  ];

  testWidgets(
    'renders header, stepper, map, sort bar, a card per partner and the '
    'bottom bar with the resolved total',
    (tester) async {
      await pumpLocalizedWidget(
        tester,
        const LabSelectPartnerScreen(),
        overrides: overrides(),
      );
      await tester.pumpAndSettle();

      // Header: title + back icon (the help icon was removed — the back
      // button now occupies that slot). The title text itself is a
      // `.tr()` key ("lab_booking.step_select_lab" — same wording as the
      // stepper's own label for this step) — this suite follows the
      // codebase convention (see lab_confirm_bottom_bar_test.dart,
      // lab_partner_card_test.dart) of asserting structure/icons rather
      // than exact translated copy, since translation resolution timing
      // under flutter_test is not reliable enough to assert on.
      expect(find.byIcon(Icons.arrow_forward), findsOneWidget);
      expect(find.byIcon(Icons.help_outline), findsNothing);

      final stepper = tester.widget<StepProgressHeader>(
        find.byType(StepProgressHeader),
      );
      expect(stepper.currentStep, 1);
      expect(stepper.stepLabels, hasLength(3));
      // The header title must read identically to the stepper's own label
      // for this step, matching what all three screens of this flow show
      // — comparing against `stepLabels[1]` (not a hardcoded string) stays
      // correct regardless of translation-resolution timing, since both
      // are sourced from the exact same `.tr()` call in production code.
      expect(find.text(stepper.stepLabels[1]), findsWidgets);

      expect(find.byType(LabPartnersMapView), findsOneWidget);
      expect(find.byType(LabSortChipBar), findsOneWidget);
      expect(find.byType(LabPartnerCard), findsNWidgets(partners.length));
      expect(find.text('Alpha Lab'), findsWidgets);
      expect(find.text('Beta Lab'), findsOneWidget);

      final bottomBar = tester.widget<LabConfirmBottomBar>(
        find.byType(LabConfirmBottomBar),
      );
      expect(bottomBar.totalPrice, 150);
      expect(bottomBar.isSubmitting, isFalse);

      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('shows a loading spinner before partners resolve', (
    tester,
  ) async {
    final completer = Completer<Result<List<LabPartner>>>();
    when(
      () => bookingRepo.getLabPartners(
        testIds: any(named: 'testIds'),
        sort: any(named: 'sort'),
      ),
    ).thenAnswer((_) => completer.future);

    await tester.runAsync(() async {
      await pumpLocalizedWidget(
        tester,
        const LabSelectPartnerScreen(),
        overrides: overrides(),
      );

      expect(find.byType(CircularProgressIndicator), findsWidgets);
      expect(find.byType(LabPartnerCard), findsNothing);

      completer.complete(Result.ok(partners));
      await tester.pumpAndSettle();

      expect(find.byType(LabPartnerCard), findsNWidgets(partners.length));
      expect(tester.takeException(), isNull);
    });
  });

  testWidgets('renders an error view instead of crashing when partners fail', (
    tester,
  ) async {
    when(
      () => bookingRepo.getLabPartners(
        testIds: any(named: 'testIds'),
        sort: any(named: 'sort'),
      ),
    ).thenAnswer((_) async => const Result.err(Failure.network()));

    await pumpLocalizedWidget(
      tester,
      const LabSelectPartnerScreen(),
      overrides: overrides(),
    );
    await tester.pumpAndSettle();

    expect(find.byType(LabPartnerCard), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'defaults the first partner as selected when none chosen explicitly',
    (tester) async {
      await pumpLocalizedWidget(
        tester,
        const LabSelectPartnerScreen(),
        overrides: overrides(),
      );
      await tester.pumpAndSettle();

      final cards = tester
          .widgetList<LabPartnerCard>(find.byType(LabPartnerCard))
          .toList();
      expect(cards[0].partner.id, 'p1');
      expect(cards[0].isSelected, isTrue);
      expect(cards[1].isSelected, isFalse);

      // The selected-only check badge renders once, on the first card.
      expect(checkIconIn(find.byType(LabPartnerCard).at(0)), findsOneWidget);
      expect(checkIconIn(find.byType(LabPartnerCard).at(1)), findsNothing);

      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('tapping a partner card moves the selection indicator to it', (
    tester,
  ) async {
    await pumpLocalizedWidget(
      tester,
      const LabSelectPartnerScreen(),
      overrides: overrides(),
    );
    await tester.pumpAndSettle();

    // Only the currently-unselected card renders its "choose" CTA InkWell
    // (LabPartnerCard hides it once `isSelected` is true), so with the
    // first partner pre-selected by default there's exactly one inside a
    // LabPartnerCard to tap. Scope past `find.byType(InkWell)` since
    // Material's own chips/buttons elsewhere on screen use InkWell too.
    final chooseCta = find.descendant(
      of: find.byType(LabPartnerCard),
      matching: find.byType(InkWell),
    );
    expect(chooseCta, findsOneWidget);
    // Invoke `onTap` directly instead of `tester.tap(...)`: a simulated
    // pointer down/up starts the InkWell's ripple, which needs the
    // `ink_sparkle` shader — unavailable under `flutter_test`'s default
    // backend, and it throws once flushed (even across a bounded pump
    // budget, since the framework flushes leftover animation microtasks at
    // test teardown regardless). Calling the callback directly exercises
    // the same `onSelect` wiring without going through the gesture/ripple
    // pipeline.
    tester.widget<InkWell>(chooseCta).onTap!();
    await tester.pumpAndSettle();

    final cards = tester
        .widgetList<LabPartnerCard>(find.byType(LabPartnerCard))
        .toList();
    final selected = cards.firstWhere((c) => c.partner.id == 'p2');
    final unselected = cards.firstWhere((c) => c.partner.id == 'p1');
    expect(selected.isSelected, isTrue);
    expect(unselected.isSelected, isFalse);
    expect(checkIconIn(find.byType(LabPartnerCard).at(1)), findsOneWidget);
    expect(checkIconIn(find.byType(LabPartnerCard).at(0)), findsNothing);

    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'tapping a sort chip re-fetches partners with the new sort option',
    (tester) async {
      await pumpLocalizedWidget(
        tester,
        const LabSelectPartnerScreen(),
        overrides: overrides(),
      );
      await tester.pumpAndSettle();

      // LabSortChipBar renders its chips in this fixed order: priceAsc,
      // ratingDesc, nearest (see lab_sort_chip_bar.dart's `_chip(...)`
      // calls) — select the first chip's "lowest price" option. Invoke
      // `onSelected` directly instead of `tester.tap(...)` — see the
      // comment in the partner-card-tap test above on why a simulated
      // pointer tap on a ripple-based Material widget is flaky under
      // `flutter_test` (missing `ink_sparkle` shader).
      final chip = tester.widget<ChoiceChip>(find.byType(ChoiceChip).first);
      chip.onSelected!(true);
      await tester.pumpAndSettle();

      verify(
        () => bookingRepo.getLabPartners(
          testIds: any(named: 'testIds'),
          sort: LabSortOption.priceAsc,
        ),
      ).called(greaterThanOrEqualTo(1));

      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'tapping continue selects the lab and navigates to the schedule & '
    'payment route',
    (tester) async {
      await pumpWithRouter(
        tester,
        const LabSelectPartnerScreen(),
        overrides: overrides(),
      );
      await tester.pumpAndSettle();

      // Invoke `onPressed` directly rather than `tester.tap(...)` — see the
      // comment in the partner-card-tap test above on why a simulated
      // pointer tap on a ripple-based Material widget (FilledButton here)
      // is flaky under `flutter_test` (missing `ink_sparkle` shader).
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed!();
      await tester.pumpAndSettle();

      // Booking confirmation now happens on the schedule & payment step,
      // not here — this screen's job is just to record the choice and move
      // on.
      verifyNever(
        () => bookingRepo.confirmBooking(
          labId: any(named: 'labId'),
          testIds: any(named: 'testIds'),
        ),
      );
      expect(find.text('schedule-payment-screen'), findsOneWidget);
      expect(find.text('start-placeholder'), findsNothing);

      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('tapping the back button pops the screen', (tester) async {
    await pumpWithRouter(
      tester,
      const LabSelectPartnerScreen(),
      overrides: overrides(),
    );
    await tester.pumpAndSettle();

    expect(find.text('start-placeholder'), findsNothing);

    // Invoke `onPressed` directly rather than `tester.tap(...)` — see the
    // comment in the partner-card-tap test above on why a simulated
    // pointer tap on a ripple-based Material widget (IconButton here) is
    // flaky under `flutter_test` (missing `ink_sparkle` shader).
    final backButton = tester.widget<IconButton>(
      find.ancestor(
        of: find.byIcon(Icons.arrow_forward),
        matching: find.byType(IconButton),
      ),
    );
    backButton.onPressed!();
    await tester.pumpAndSettle();

    expect(find.text('start-placeholder'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

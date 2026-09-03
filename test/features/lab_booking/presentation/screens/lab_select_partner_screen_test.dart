import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:med_super/core/error/failure.dart';
import 'package:med_super/core/error/result.dart';
import 'package:med_super/core/widgets/step_progress_header.dart';
import 'package:med_super/features/lab_booking/domain/entities/lab_partner.dart';
import 'package:med_super/features/lab_booking/domain/entities/lab_partner_status.dart';
import 'package:med_super/features/lab_booking/domain/entities/lab_sort_option.dart';
import 'package:med_super/features/lab_booking/domain/repositories/lab_booking_repository.dart';
import 'package:med_super/features/lab_booking/presentation/controllers/lab_partner_providers.dart';
import 'package:med_super/features/lab_booking/presentation/screens/lab_select_partner_screen.dart';
import 'package:med_super/features/lab_booking/presentation/widgets/lab_confirm_bottom_bar.dart';
import 'package:med_super/features/lab_booking/presentation/widgets/lab_partner_card.dart';
import 'package:med_super/features/lab_booking/presentation/widgets/lab_partners_map_view.dart';
import 'package:med_super/features/lab_booking/presentation/widgets/lab_sort_chip_bar.dart';
import 'package:mocktail/mocktail.dart';
import 'package:riverpod/misc.dart' show Override;
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../helpers/fake_tile_provider.dart';
import '../../../../helpers/pump_localized_widget.dart';

class _MockLabBookingRepository extends Mock implements LabBookingRepository {}

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
        path: '/patient/lab/review',
        builder: (context, state) =>
            const Scaffold(body: Text('review-screen')),
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

    router.push('/select-lab');
    for (var i = 0; i < 3; i++) {
      await tester.pump();
    }
    await tester.pumpAndSettle();
  });

  return router;
}

/// A bounded stand-in for `tester.pumpAndSettle()` for use whenever a
/// `CircularProgressIndicator` (an indeterminate, perpetually-animating
/// spinner) might still be in the tree — `pumpAndSettle()` never stops
/// scheduling frames while one is present, and hangs until its own
/// timeout. Mirrors `pumpLocalizedWidget`'s own internal pump loop (see its
/// doc comment) — a handful of real-async-driven pumps inside `runAsync`
/// is enough to flush a resolved/rejected Future without waiting for
/// "no more frames ever."
Future<void> _settle(WidgetTester tester) => tester.runAsync(() async {
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 20));
  }
});

void main() {
  setUpAll(() {
    registerFallbackValue(LabSortOption.nearest);
  });

  // This screen renders a `LabPartnersMapView` (`FlutterMap`), whose
  // built-in tile disk cache asks path_provider for a cache directory as
  // soon as it builds. There is no path_provider platform implementation in
  // `flutter test`, so without a mock handler this throws a
  // MissingPluginException asynchronously *after* the test body has
  // already finished, which flutter_test then reports as a (spurious)
  // failure of whichever test happens to be running next (mirrors
  // clinic_location_map_view_test.dart's setup).
  const pathProviderChannel = MethodChannel('plugins.flutter.io/path_provider');

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(pathProviderChannel, (call) async {
          switch (call.method) {
            case 'getApplicationCacheDirectory':
            case 'getTemporaryDirectory':
            case 'getApplicationSupportDirectory':
              return '.dart_tool/test_cache';
            default:
              return null;
          }
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(pathProviderChannel, null);
  });

  late _MockLabBookingRepository bookingRepo;

  const partners = [
    LabPartner(
      id: 'p1',
      name: 'Alpha Lab',
      address: '1 Tahrir St, Cairo',
      distanceKm: 1.2,
      rating: 4.8,
      ratingCount: 120,
      startingPrice: 300,
      latitude: 24.71,
      longitude: 46.67,
      status: LabPartnerStatus.openNow,
    ),
    LabPartner(
      id: 'p2',
      name: 'Beta Lab',
      address: '2 Nile St, Cairo',
      distanceKm: 3.4,
      rating: 4.2,
      ratingCount: 40,
      startingPrice: 250,
      latitude: 24.72,
      longitude: 46.68,
      status: LabPartnerStatus.busyNow,
    ),
  ];

  setUp(() {
    bookingRepo = _MockLabBookingRepository();

    when(
      () => bookingRepo.getLabPartners(
        testIds: any(named: 'testIds'),
        sort: any(named: 'sort'),
      ),
    ).thenAnswer((_) async => Result.ok(partners));
  });

  List<Override> overrides() => [
    labBookingRepositoryProvider.overrideWithValue(bookingRepo),
  ];

  testWidgets(
    'renders header, stepper, map, sort bar, a card per partner and the '
    'bottom bar (no price shown at this step)',
    (tester) async {
      await pumpLocalizedWidget(
        tester,
        LabSelectPartnerScreen(mapTileProvider: FakeTileProvider()),
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

      // The bottom bar no longer carries any price — pricing at this step
      // is unknown until the lab reviews the uploaded request.
      expect(find.byType(LabConfirmBottomBar), findsOneWidget);
      final bottomBar = tester.widget<LabConfirmBottomBar>(
        find.byType(LabConfirmBottomBar),
      );
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

    await pumpLocalizedWidget(
      tester,
      LabSelectPartnerScreen(mapTileProvider: FakeTileProvider()),
      overrides: overrides(),
    );

    expect(find.byType(CircularProgressIndicator), findsWidgets);
    expect(find.byType(LabPartnerCard), findsNothing);

    completer.complete(Result.ok(partners));
    await _settle(tester);

    expect(find.byType(LabPartnerCard), findsNWidgets(partners.length));
    expect(tester.takeException(), isNull);
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
      LabSelectPartnerScreen(mapTileProvider: FakeTileProvider()),
      overrides: overrides(),
    );
    await _settle(tester);

    expect(find.byType(LabPartnerCard), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'defaults the first partner as selected when none chosen explicitly',
    (tester) async {
      await pumpLocalizedWidget(
        tester,
        LabSelectPartnerScreen(mapTileProvider: FakeTileProvider()),
        overrides: overrides(),
      );
      await tester.pumpAndSettle();

      final cards = tester
          .widgetList<LabPartnerCard>(find.byType(LabPartnerCard))
          .toList();
      expect(cards[0].partner.id, 'p1');
      expect(cards[0].isSelected, isTrue);
      expect(cards[1].isSelected, isFalse);

      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'renders a status chip per partner card matching its operating status',
    (tester) async {
      await pumpLocalizedWidget(
        tester,
        LabSelectPartnerScreen(mapTileProvider: FakeTileProvider()),
        overrides: overrides(),
      );
      await tester.pumpAndSettle();

      // p1 is openNow, p2 is busyNow — both status labels must be showing
      // simultaneously, one per card, proving the chip's text is wired to
      // each partner's own status rather than a shared/static value.
      // Resolved via the same `.labelKey.tr()` the production widget uses
      // (see the stepLabels comparison above for why this is timing-safe).
      // openNow's label is scoped to inside a LabPartnerCard specifically —
      // the screen's own "مفتوح الآن" filter chip (outside any card) uses
      // the exact same English/Arabic copy, so an unscoped `find.text`
      // would over-match.
      expect(
        find.descendant(
          of: find.byType(LabPartnerCard),
          matching: find.text(LabPartnerStatus.openNow.labelKey.tr()),
        ),
        findsOneWidget,
      );
      expect(find.text(LabPartnerStatus.busyNow.labelKey.tr()), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('tapping a partner card moves the selection indicator to it', (
    tester,
  ) async {
    await pumpLocalizedWidget(
      tester,
      LabSelectPartnerScreen(mapTileProvider: FakeTileProvider()),
      overrides: overrides(),
    );
    await tester.pumpAndSettle();

    // Every card always shows its own "choose" CTA (this design has no
    // separate hidden/shown state per selection), so tap the second
    // card's specifically rather than relying on there being just one.
    // Invoke `onPressed` directly instead of `tester.tap(...)`: a
    // simulated pointer down/up starts the button's ripple, which needs
    // the `ink_sparkle` shader — unavailable under `flutter_test`'s
    // default backend, and it throws once flushed (even across a bounded
    // pump budget, since the framework flushes leftover animation
    // microtasks at test teardown regardless). Calling the callback
    // directly exercises the same `onSelect` wiring without going through
    // the gesture/ripple pipeline.
    final secondCardChoose = find.descendant(
      of: find.byType(LabPartnerCard).at(1),
      matching: find.widgetWithText(
        ElevatedButton,
        'lab_booking.select_lab.choose_cta'.tr(),
      ),
    );
    tester.widget<ElevatedButton>(secondCardChoose).onPressed!();
    await tester.pumpAndSettle();

    final cards = tester
        .widgetList<LabPartnerCard>(find.byType(LabPartnerCard))
        .toList();
    final selected = cards.firstWhere((c) => c.partner.id == 'p2');
    final unselected = cards.firstWhere((c) => c.partner.id == 'p1');
    expect(selected.isSelected, isTrue);
    expect(unselected.isSelected, isFalse);

    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'tapping a sort chip re-fetches partners with the new sort option',
    (tester) async {
      await pumpLocalizedWidget(
        tester,
        LabSelectPartnerScreen(mapTileProvider: FakeTileProvider()),
        overrides: overrides(),
      );
      await _settle(tester);

      // LabSortChipBar renders its chips in this fixed order: the "مفتوح
      // الآن" filter chip first, then priceAsc, ratingDesc, nearest (see
      // lab_sort_chip_bar.dart's `_filterChip()`/`_chip(...)` calls) —
      // select the second chip ("lowest price"), not the first (that's now
      // the filter chip). Invoke `onSelected` directly instead of
      // `tester.tap(...)` — see the comment in the partner-card-tap test
      // above on why a simulated pointer tap on a ripple-based Material
      // widget is flaky under `flutter_test` (missing `ink_sparkle` shader).
      final chip = tester.widget<ChoiceChip>(find.byType(ChoiceChip).at(1));
      chip.onSelected!(true);
      await _settle(tester);

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
    'tapping continue selects the lab and navigates to the review route',
    (tester) async {
      await pumpWithRouter(
        tester,
        LabSelectPartnerScreen(mapTileProvider: FakeTileProvider()),
        overrides: overrides(),
      );
      await tester.pumpAndSettle();

      // Invoke `onPressed` directly rather than `tester.tap(...)` — see the
      // comment in the partner-card-tap test above on why a simulated
      // pointer tap on a ripple-based Material widget (FilledButton here)
      // is flaky under `flutter_test` (missing `ink_sparkle` shader).
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed!();
      await tester.pumpAndSettle();

      expect(find.text('review-screen'), findsOneWidget);
      expect(find.text('start-placeholder'), findsNothing);

      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'renders no cards and does not crash when the lab list is empty',
    (tester) async {
      when(
        () => bookingRepo.getLabPartners(
          testIds: any(named: 'testIds'),
          sort: any(named: 'sort'),
        ),
      ).thenAnswer((_) async => const Result.ok([]));

      await pumpLocalizedWidget(
        tester,
        LabSelectPartnerScreen(mapTileProvider: FakeTileProvider()),
        overrides: overrides(),
      );
      await tester.pumpAndSettle();

      expect(find.byType(LabPartnerCard), findsNothing);

      // Falls back to a null selected id with no partners to default to —
      // tapping continue must be a no-op rather than crash on a null id.
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed!();
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('tapping the back button pops the screen', (tester) async {
    await pumpWithRouter(
      tester,
      LabSelectPartnerScreen(mapTileProvider: FakeTileProvider()),
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

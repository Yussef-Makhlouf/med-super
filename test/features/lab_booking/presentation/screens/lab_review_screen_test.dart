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
import 'package:med_super/features/lab_booking/domain/entities/lab_booking_confirmation.dart';
import 'package:med_super/features/lab_booking/domain/entities/lab_partner.dart';
import 'package:med_super/features/lab_booking/domain/entities/lab_partner_status.dart';
import 'package:med_super/features/lab_booking/domain/entities/lab_payment_method.dart';
import 'package:med_super/features/lab_booking/domain/entities/lab_service_type.dart';
import 'package:med_super/features/lab_booking/domain/entities/lab_sort_option.dart';
import 'package:med_super/features/lab_booking/domain/repositories/lab_booking_repository.dart';
import 'package:med_super/features/lab_booking/presentation/controllers/lab_partner_providers.dart';
import 'package:med_super/features/lab_booking/presentation/controllers/lab_schedule_providers.dart';
import 'package:med_super/features/lab_booking/presentation/controllers/lab_upload_providers.dart';
import 'package:med_super/features/lab_booking/presentation/screens/lab_review_screen.dart';
import 'package:med_super/features/lab_booking/presentation/widgets/lab_cost_estimate_section.dart';
import 'package:med_super/features/lab_booking/presentation/widgets/lab_schedule_edit_modal.dart';
import 'package:med_super/features/lab_booking/presentation/widgets/payment_method_option.dart';
import 'package:mocktail/mocktail.dart';
import 'package:riverpod/misc.dart' show Override;
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../helpers/pump_localized_widget.dart';

class _MockLabBookingRepository extends Mock implements LabBookingRepository {}

/// Same synchronous asset loader as `pump_localized_widget.dart`, needed
/// again here because the router-based tests build their own
/// `MaterialApp.router` shell instead of going through `pumpLocalizedWidget`.
class _SyncFileAssetLoader extends AssetLoader {
  const _SyncFileAssetLoader();

  @override
  Future<Map<String, dynamic>?> load(String path, Locale locale) {
    final file = File('$path/${locale.languageCode}.json');
    final content = file.readAsStringSync();
    return SynchronousFuture(json.decode(content) as Map<String, dynamic>);
  }
}

const _partner = LabPartner(
  id: 'p1',
  name: 'Alpha Lab',
  address: '1 Tahrir St, Cairo',
  distanceKm: 1.5,
  rating: 4.6,
  ratingCount: 80,
  startingPrice: 300,
  latitude: 24.7,
  longitude: 46.6,
  status: LabPartnerStatus.openNow,
);

const _confirmation = LabBookingConfirmation(
  bookingNumber: 'ORD-12345',
  labName: 'Alpha Lab',
  labAddress: 'Some address',
  expectedResponseHours: 2,
);

void main() {
  setUpAll(() {
    registerFallbackValue(LabSortOption.nearest);
    registerFallbackValue(LabServiceType.branchVisit);
    registerFallbackValue(LabPaymentMethod.onlinePayment);
  });

  late _MockLabBookingRepository repo;

  setUp(() {
    repo = _MockLabBookingRepository();
    when(
      () => repo.getLabPartners(
        testIds: any(named: 'testIds'),
        sort: any(named: 'sort'),
      ),
    ).thenAnswer((_) async => Result.ok(const [_partner]));
    when(
      () => repo.confirmBooking(
        labId: any(named: 'labId'),
        images: any(named: 'images'),
        serviceType: any(named: 'serviceType'),
        paymentMethod: any(named: 'paymentMethod'),
        scheduledDate: any(named: 'scheduledDate'),
        scheduledTime: any(named: 'scheduledTime'),
        address: any(named: 'address'),
      ),
    ).thenAnswer((_) async => const Result.ok(_confirmation));
  });

  List<Override> overrides() => [
    labBookingRepositoryProvider.overrideWithValue(repo),
  ];

  /// Invokes the "edit" link's `onTap` directly instead of
  /// `tester.tap(...)` — a simulated pointer down/up starts the `InkWell`'s
  /// ripple, which needs the `ink_sparkle` shader unavailable under
  /// `flutter_test`'s default backend (see the same convention in
  /// `lab_select_partner_screen_test.dart`).
  Future<void> tapEdit(WidgetTester tester) async {
    final inkWell = tester.widget<InkWell>(
      find.ancestor(
        of: find.text('lab_booking.review.edit_cta'.tr()),
        matching: find.byType(InkWell),
      ),
    );
    inkWell.onTap!();
    await tester.pumpAndSettle();
  }

  /// Pumps [LabReviewScreen] alongside an invisible [Consumer] used to
  /// capture a [WidgetRef] into the returned value — needed because this
  /// screen only *reads* the upload-step providers (images/service type),
  /// it doesn't set them; that happens on the previous screen in the real
  /// app, so tests seed them directly via the notifier.
  Future<WidgetRef> pumpReviewScreen(WidgetTester tester) async {
    late WidgetRef capturedRef;
    await pumpLocalizedWidget(
      tester,
      Stack(
        children: [
          const LabReviewScreen(),
          Consumer(
            builder: (context, ref, _) {
              capturedRef = ref;
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      overrides: overrides(),
    );
    return capturedRef;
  }

  Future<void> seedUpload(
    WidgetTester tester,
    WidgetRef ref, {
    required LabServiceType serviceType,
    List<String> imagePaths = const ['/tmp/request.png'],
  }) async {
    ref
        .read(uploadedLabRequestImagesProvider.notifier)
        .addImages(imagePaths.map((path) => (path: path, bytes: null)));
    ref.read(selectedLabServiceTypeProvider.notifier).select(serviceType);
    await tester.pumpAndSettle();
  }

  /// Router-backed shell (mirrors `lab_select_partner_screen_test.dart`'s
  /// `pumpWithRouter`), needed for the tests exercising `context.pop()` /
  /// `context.push()` navigation — the plain `pumpLocalizedWidget` shell has
  /// no `GoRouter` ancestor, so those calls would throw there.
  Future<void> pumpWithRouter(
    WidgetTester tester, {
    required void Function(WidgetRef ref) onRef,
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
        GoRoute(
          path: '/review',
          builder: (context, state) => Stack(
            children: [
              const LabReviewScreen(),
              Consumer(
                builder: (context, ref, _) {
                  onRef(ref);
                  return const SizedBox.shrink();
                },
              ),
            ],
          ),
        ),
        GoRoute(
          path: '/patient/lab/confirmation',
          builder: (context, state) =>
              const Scaffold(body: Text('confirmation-screen')),
        ),
        GoRoute(
          path: '/patient/lab/upload',
          builder: (context, state) =>
              const Scaffold(body: Text('upload-placeholder')),
        ),
      ],
    );
    addTearDown(router.dispose);

    Widget shell() => ProviderScope(
      overrides: overrides(),
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

    router.push('/review');
    for (var i = 0; i < 3; i++) {
      await tester.pump();
    }
    await tester.pumpAndSettle();
  }

  testWidgets(
    'renders the order-summary card with the lab name, distance and the '
    'generic request-description line',
    (tester) async {
      final ref = await pumpReviewScreen(tester);
      await seedUpload(tester, ref, serviceType: LabServiceType.branchVisit);

      expect(find.text('Alpha Lab'), findsOneWidget);
      expect(find.byIcon(Icons.place_outlined), findsWidgets);
      expect(find.byIcon(Icons.description_outlined), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'renders the header, the 3-step stepper and every section title with '
    'the real translated copy — would fail on a wrong copy string in '
    'ar.json/en.json',
    (tester) async {
      final ref = await pumpReviewScreen(tester);
      await seedUpload(tester, ref, serviceType: LabServiceType.branchVisit);

      expect(find.text('lab_booking.review.title'.tr()), findsOneWidget);
      expect(find.text('lab_booking.step_upload'.tr()), findsOneWidget);
      expect(find.text('lab_booking.step_select_lab'.tr()), findsOneWidget);
      expect(find.text('lab_booking.step_review'.tr()), findsOneWidget);
      expect(
        find.text('lab_booking.review.summary_title'.tr()),
        findsOneWidget,
      );
      expect(
        find.text('lab_booking.review.request_description'.tr()),
        findsOneWidget,
      );
      expect(
        find.text('lab_booking.review.payment_method_title'.tr()),
        findsOneWidget,
      );
      expect(
        find.text('lab_booking.review.service_method_title'.tr()),
        findsOneWidget,
      );
      expect(
        find.text('lab_booking.review.cost_estimate_title'.tr()),
        findsOneWidget,
      );
      expect(
        find.text('lab_booking.review.terms_agreement'.tr()),
        findsOneWidget,
      );
      expect(find.text('lab_booking.review.submit_cta'.tr()), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'renders both payment method options with their real translated label '
    'and subtitle',
    (tester) async {
      final ref = await pumpReviewScreen(tester);
      await seedUpload(tester, ref, serviceType: LabServiceType.branchVisit);

      expect(
        find.text(LabPaymentMethod.onlinePayment.labelKey.tr()),
        findsOneWidget,
      );
      expect(
        find.text(LabPaymentMethod.onlinePayment.subtitleKey.tr()),
        findsOneWidget,
      );
      expect(
        find.text(LabPaymentMethod.payAtService.labelKey.tr()),
        findsOneWidget,
      );
      expect(
        find.text(LabPaymentMethod.payAtService.subtitleKey.tr()),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('tapping the request-description row expands it, swapping the '
      'chevron icon', (tester) async {
    final ref = await pumpReviewScreen(tester);
    await seedUpload(tester, ref, serviceType: LabServiceType.branchVisit);

    final collapsedText = tester.widget<Text>(
      find.text('lab_booking.review.request_description'.tr()),
    );
    expect(collapsedText.maxLines, 1);
    expect(find.byIcon(Icons.keyboard_arrow_down), findsOneWidget);

    await tester.tap(find.byIcon(Icons.keyboard_arrow_down));
    await tester.pump();

    final expandedText = tester.widget<Text>(
      find.text('lab_booking.review.request_description'.tr()),
    );
    expect(expandedText.maxLines, isNull);
    expect(find.byIcon(Icons.keyboard_arrow_up), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'branch-visit service method shows the branch title and building icon, '
    'with no day/time/address row',
    (tester) async {
      final ref = await pumpReviewScreen(tester);
      await seedUpload(tester, ref, serviceType: LabServiceType.branchVisit);

      expect(
        find.text(LabServiceType.branchVisit.titleKey.tr()),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.apartment_outlined), findsOneWidget);
      expect(find.byIcon(Icons.home_outlined), findsNothing);
      expect(find.text(ref.read(selectedLabAddressProvider)), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'home-collection service method shows the home title, home icon, and '
    'the scheduled day/time and address',
    (tester) async {
      final ref = await pumpReviewScreen(tester);
      await seedUpload(tester, ref, serviceType: LabServiceType.homeCollection);

      expect(
        find.text(LabServiceType.homeCollection.titleKey.tr()),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.home_outlined), findsOneWidget);
      expect(find.byIcon(Icons.apartment_outlined), findsNothing);
      expect(find.text(ref.read(selectedLabAddressProvider)), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('selecting the pay-at-service option marks it selected and the '
      'online-payment option unselected', (tester) async {
    final ref = await pumpReviewScreen(tester);
    await seedUpload(tester, ref, serviceType: LabServiceType.branchVisit);

    final options = tester
        .widgetList<PaymentMethodOption>(find.byType(PaymentMethodOption))
        .toList();
    final payAtService = options.firstWhere(
      (o) => o.method == LabPaymentMethod.payAtService,
    );
    payAtService.onSelected();
    await tester.pump();

    final updated = tester
        .widgetList<PaymentMethodOption>(find.byType(PaymentMethodOption))
        .toList();
    expect(
      updated
          .firstWhere((o) => o.method == LabPaymentMethod.payAtService)
          .isSelected,
      isTrue,
    );
    expect(
      updated
          .firstWhere((o) => o.method == LabPaymentMethod.onlinePayment)
          .isSelected,
      isFalse,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('home collection shows the home-fee row; branch visit hides it', (
    tester,
  ) async {
    final ref = await pumpReviewScreen(tester);
    await seedUpload(tester, ref, serviceType: LabServiceType.homeCollection);

    var estimate = tester
        .widget<LabCostEstimateSection>(find.byType(LabCostEstimateSection))
        .estimate;
    expect(estimate.homeFee, kLabHomeServiceFeeEgp);
    expect(estimate.total, estimate.testsEstimate + kLabHomeServiceFeeEgp);

    ref
        .read(selectedLabServiceTypeProvider.notifier)
        .select(LabServiceType.branchVisit);
    await tester.pump();

    estimate = tester
        .widget<LabCostEstimateSection>(find.byType(LabCostEstimateSection))
        .estimate;
    expect(estimate.homeFee, 0);
    expect(estimate.total, estimate.testsEstimate);
    expect(tester.takeException(), isNull);
  });

  testWidgets('tapping "edit" on a home-collection service opens the schedule/'
      'address modal', (tester) async {
    final ref = await pumpReviewScreen(tester);
    await seedUpload(tester, ref, serviceType: LabServiceType.homeCollection);

    await tapEdit(tester);

    expect(find.byType(LabScheduleEditModal), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'saving the edit modal updates the address shown on the review screen',
    (tester) async {
      final ref = await pumpReviewScreen(tester);
      await seedUpload(tester, ref, serviceType: LabServiceType.homeCollection);

      await tapEdit(tester);

      await tester.enterText(find.byType(TextField), 'شارع الجديد');
      await tester.pump();

      final saveButtonFinder = find.descendant(
        of: find.byType(LabScheduleEditModal),
        matching: find.byType(FilledButton),
      );
      final saveButton = tester.widget<FilledButton>(saveButtonFinder);
      saveButton.onPressed!();
      await tester.pumpAndSettle();

      expect(find.byType(LabScheduleEditModal), findsNothing);
      expect(find.text('شارع الجديد'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'tapping "edit" on a branch-visit service navigates to the upload step '
    '(where the service-type choice itself is made) instead of opening a '
    'modal or going back to the select-lab step',
    (tester) async {
      late WidgetRef ref;
      await pumpWithRouter(tester, onRef: (r) => ref = r);
      await seedUpload(tester, ref, serviceType: LabServiceType.branchVisit);

      await tapEdit(tester);

      expect(find.byType(LabScheduleEditModal), findsNothing);
      expect(find.text('upload-placeholder'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'the submit CTA stays disabled until the terms checkbox is ticked',
    (tester) async {
      final ref = await pumpReviewScreen(tester);
      await seedUpload(tester, ref, serviceType: LabServiceType.branchVisit);

      final submitFinder = find.widgetWithText(
        FilledButton,
        'lab_booking.review.submit_cta'.tr(),
      );
      expect(tester.widget<FilledButton>(submitFinder).onPressed, isNull);

      // Invoke `onChanged` directly rather than `tester.tap(...)` — see
      // `tapEdit`'s doc comment on why a simulated pointer tap on a
      // ripple-based Material widget is flaky under `flutter_test`.
      tester.widget<Checkbox>(find.byType(Checkbox)).onChanged!(true);
      await tester.pump();

      expect(tester.widget<FilledButton>(submitFinder).onPressed, isNotNull);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'confirming submits the uploaded images, service type, payment method '
    'and lab id, then navigates to the confirmation screen',
    (tester) async {
      late WidgetRef ref;
      await pumpWithRouter(tester, onRef: (r) => ref = r);
      await seedUpload(tester, ref, serviceType: LabServiceType.branchVisit);

      // Invoke `onChanged` directly rather than `tester.tap(...)` — see
      // `tapEdit`'s doc comment on why a simulated pointer tap on a
      // ripple-based Material widget is flaky under `flutter_test`.
      tester.widget<Checkbox>(find.byType(Checkbox)).onChanged!(true);
      await tester.pump();

      final submitFinder = find.widgetWithText(
        FilledButton,
        'lab_booking.review.submit_cta'.tr(),
      );
      tester.widget<FilledButton>(submitFinder).onPressed!();
      await tester.pumpAndSettle();

      final captured = verify(
        () => repo.confirmBooking(
          labId: captureAny(named: 'labId'),
          images: captureAny(named: 'images'),
          serviceType: captureAny(named: 'serviceType'),
          paymentMethod: captureAny(named: 'paymentMethod'),
          scheduledDate: any(named: 'scheduledDate'),
          scheduledTime: any(named: 'scheduledTime'),
          address: any(named: 'address'),
        ),
      ).captured;
      expect(captured[0], 'p1');
      expect((captured[1] as List).length, 1);
      expect(captured[2], LabServiceType.branchVisit);
      expect(captured[3], LabPaymentMethod.onlinePayment);

      expect(find.text('confirmation-screen'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'shows the real translated error snackbar and stays on the review '
    'screen when confirming fails',
    (tester) async {
      when(
        () => repo.confirmBooking(
          labId: any(named: 'labId'),
          images: any(named: 'images'),
          serviceType: any(named: 'serviceType'),
          paymentMethod: any(named: 'paymentMethod'),
          scheduledDate: any(named: 'scheduledDate'),
          scheduledTime: any(named: 'scheduledTime'),
          address: any(named: 'address'),
        ),
      ).thenAnswer((_) async => const Result.err(Failure.network()));

      late WidgetRef ref;
      await pumpWithRouter(tester, onRef: (r) => ref = r);
      await seedUpload(tester, ref, serviceType: LabServiceType.branchVisit);

      // Invoke `onChanged` directly rather than `tester.tap(...)` — see
      // `tapEdit`'s doc comment on why a simulated pointer tap on a
      // ripple-based Material widget is flaky under `flutter_test`.
      tester.widget<Checkbox>(find.byType(Checkbox)).onChanged!(true);
      await tester.pump();

      final submitFinder = find.widgetWithText(
        FilledButton,
        'lab_booking.review.submit_cta'.tr(),
      );
      tester.widget<FilledButton>(submitFinder).onPressed!();
      await tester.pumpAndSettle();

      expect(
        find.text('lab_booking.select_lab.confirm_error'.tr()),
        findsOneWidget,
      );
      expect(find.text('confirmation-screen'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}

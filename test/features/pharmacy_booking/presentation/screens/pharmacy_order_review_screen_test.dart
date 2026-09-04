import 'dart:convert';
import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:med_super/features/pharmacy_booking/domain/entities/delivery_method.dart';
import 'package:med_super/features/pharmacy_booking/domain/entities/pharmacy.dart';
import 'package:med_super/features/pharmacy_booking/domain/entities/pharmacy_order_confirmation.dart';
import 'package:med_super/features/pharmacy_booking/domain/entities/pharmacy_order_create_result.dart';
import 'package:med_super/features/pharmacy_booking/domain/entities/prescription_image.dart';
import 'package:med_super/features/pharmacy_booking/domain/entities/prescription_upload_result.dart';
import 'package:med_super/features/pharmacy_booking/presentation/controllers/pharmacy_order_controller.dart';
import 'package:med_super/features/pharmacy_booking/presentation/controllers/pharmacy_search_providers.dart';
import 'package:med_super/features/pharmacy_booking/presentation/controllers/pharmacy_upload_providers.dart';
import 'package:med_super/features/pharmacy_booking/presentation/controllers/prescription_upload_controller.dart';
import 'package:med_super/features/pharmacy_booking/presentation/screens/pharmacy_order_review_screen.dart';
import 'package:riverpod/misc.dart' show Override;
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../helpers/pump_localized_widget.dart';

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

const _pharmacy = Pharmacy(
  id: 'ph1',
  name: 'صيدلية النهدي',
  address: 'شارع التحلية، الرياض',
  distanceKm: 1.2,
  latitude: 24.7136,
  longitude: 46.6753,
  deliveryCapable: true,
);

List<Override> _overrides({
  DeliveryMethod deliveryMethod = DeliveryMethod.homeDelivery,
  List<Pharmacy> pharmacies = const [_pharmacy],
  String? selectedPharmacyId,
  List<({String path, Uint8List? bytes})> images = const [
    (path: '/tmp/prescription.png', bytes: null),
  ],
}) {
  return [
    pharmaciesProvider.overrideWith((ref) async => pharmacies),
    selectedPharmacyProvider.overrideWith(
      () => _FixedSelectedPharmacy(selectedPharmacyId),
    ),
    uploadedPrescriptionImagesProvider.overrideWith(
      () => _SeededUploadedImages(images),
    ),
    selectedDeliveryMethodProvider.overrideWith(
      () => _FixedSelectedDeliveryMethod(deliveryMethod),
    ),
    // The real submit call needs an already-uploaded prescription id (step
    // 1) and hits the network/device location (step 3's confirm) — both
    // faked here so this screen's own tests never depend on geolocator or a
    // real HTTP round trip.
    prescriptionUploadControllerProvider.overrideWith(
      () => _FixedPrescriptionUpload(),
    ),
    pharmacyOrderControllerProvider.overrideWith(() => _FakePharmacyOrder()),
  ];
}

class _FixedPrescriptionUpload extends PrescriptionUploadController {
  @override
  AsyncValue<PrescriptionUploadResult?> build() => const AsyncData(
    PrescriptionUploadResult(
      prescriptionId: 'presc-1',
      status: 'QUALITY_CHECK_PASSED',
    ),
  );
}

/// Fakes the network round trip with a short delay (so the loading-state
/// assertion below has a frame to catch it) instead of a real datasource
/// call or device location read.
class _FakePharmacyOrder extends PharmacyOrderController {
  @override
  AsyncValue<PharmacyOrderCreateResult?> build() => const AsyncData(null);

  @override
  Future<void> submit({
    required String prescriptionId,
    required String fulfillmentType,
    String? pharmacyBranchId,
  }) async {
    state = const AsyncLoading();
    await Future<void>.delayed(const Duration(milliseconds: 50));
    state = const AsyncData(
      PharmacyOrderCreateResult(
        pharmacyOrderId: 'order-1',
        status: 'RECEIVED',
        broadcastedBranchIds: ['ph1'],
      ),
    );
  }
}

class _FixedSelectedPharmacy extends SelectedPharmacy {
  _FixedSelectedPharmacy(this._initial);
  final String? _initial;

  @override
  String? build() => _initial;
}

class _FixedSelectedDeliveryMethod extends SelectedDeliveryMethod {
  _FixedSelectedDeliveryMethod(this._initial);
  final DeliveryMethod _initial;

  @override
  DeliveryMethod build() => _initial;
}

class _SeededUploadedImages extends UploadedPrescriptionImages {
  _SeededUploadedImages(this._initial);
  final List<({String path, Uint8List? bytes})> _initial;

  @override
  List<PrescriptionImage> build() {
    // Not `super.build()` + `addImages(...)` — `addImages` reads `state`,
    // which isn't initialized yet while `build()` itself is still running.
    var id = 0;
    return [
      for (final file in _initial)
        PrescriptionImage(id: '${id++}', path: file.path, bytes: file.bytes),
    ];
  }
}

void main() {
  Future<void> pumpReviewScreen(
    WidgetTester tester, {
    List<Override>? overrides,
  }) async {
    await pumpLocalizedWidget(
      tester,
      const PharmacyOrderReviewScreen(),
      overrides: overrides ?? _overrides(),
    );
  }

  /// Invokes the "edit" link's `onTap` directly instead of
  /// `tester.tap(...)` — a simulated pointer down/up starts the `InkWell`'s
  /// ripple, which needs the `ink_sparkle` shader unavailable under
  /// `flutter_test`'s default backend (same convention as the lab booking
  /// review screen test).
  Future<void> tapEdit(WidgetTester tester) async {
    final inkWell = tester.widget<InkWell>(
      find.ancestor(
        of: find.text('pharmacy_booking.review.edit_cta'.tr()),
        matching: find.byType(InkWell),
      ),
    );
    inkWell.onTap!();
    await tester.pumpAndSettle();
  }

  Future<void> pumpWithRouter(
    WidgetTester tester, {
    List<Override>? overrides,
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
          builder: (context, state) => const PharmacyOrderReviewScreen(),
        ),
        GoRoute(
          path: '/patient/pharmacy/confirmation',
          builder: (context, state) => Scaffold(
            body: Text(
              'confirmation-screen:'
              '${(state.extra as PharmacyOrderConfirmation).pharmacyName}',
            ),
          ),
        ),
        GoRoute(
          path: '/patient/pharmacy/upload',
          builder: (context, state) =>
              const Scaffold(body: Text('upload-placeholder')),
        ),
      ],
    );
    addTearDown(router.dispose);

    Widget shell() => ProviderScope(
      overrides: overrides ?? _overrides(),
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
    'renders the header, stepper and every section title with the real '
    'translated copy — would fail on a wrong copy string in ar.json/en.json',
    (tester) async {
      await pumpReviewScreen(tester);

      expect(find.text('pharmacy_booking.review.title'.tr()), findsOneWidget);
      expect(
        find.text('pharmacy_booking.step_prescription'.tr()),
        findsOneWidget,
      );
      expect(find.text('pharmacy_booking.step_details'.tr()), findsOneWidget);
      expect(find.text('pharmacy_booking.step_review'.tr()), findsOneWidget);
      expect(
        find.text('pharmacy_booking.review.summary_title'.tr()),
        findsOneWidget,
      );
      expect(
        find.text('pharmacy_booking.review.delivery_method_title'.tr()),
        findsOneWidget,
      );
      expect(
        find.text('pharmacy_booking.review.payment_summary_title'.tr()),
        findsOneWidget,
      );
      expect(
        find.text('pharmacy_booking.review.confirm_cta'.tr()),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'renders the order-summary card with the selected pharmacy name and '
    'address',
    (tester) async {
      await pumpReviewScreen(tester);

      expect(find.text(_pharmacy.name), findsOneWidget);
      expect(find.text(_pharmacy.address), findsOneWidget);
      expect(
        find.text('pharmacy_booking.review.upload_success'.tr()),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'home-delivery method shows the delivery title, delivery icon and the '
    'mock home address',
    (tester) async {
      await pumpReviewScreen(
        tester,
        overrides: _overrides(deliveryMethod: DeliveryMethod.homeDelivery),
      );

      expect(
        find.text(DeliveryMethod.homeDelivery.titleKey.tr()),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.delivery_dining_outlined), findsOneWidget);
      expect(find.byIcon(Icons.storefront_outlined), findsOneWidget);
      expect(
        find.text('pharmacy_booking.review.home_label'.tr()),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'pickup method shows the pickup title and storefront icon, with no home '
    'address row',
    (tester) async {
      await pumpReviewScreen(
        tester,
        overrides: _overrides(deliveryMethod: DeliveryMethod.pickup),
      );

      expect(find.text(DeliveryMethod.pickup.titleKey.tr()), findsOneWidget);
      expect(
        find.text('pharmacy_booking.review.home_label'.tr()),
        findsNothing,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'clinic-handover method shows the clinic-handover title and hospital '
    'icon, with no home address row',
    (tester) async {
      await pumpReviewScreen(
        tester,
        overrides: _overrides(deliveryMethod: DeliveryMethod.clinicHandover),
      );

      expect(
        find.text(DeliveryMethod.clinicHandover.titleKey.tr()),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.local_hospital_outlined), findsOneWidget);
      expect(
        find.text('pharmacy_booking.review.home_label'.tr()),
        findsNothing,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'renders the payment summary rows with the real translated copy and '
    'mock values',
    (tester) async {
      await pumpReviewScreen(tester);

      expect(
        find.text('pharmacy_booking.review.subtotal_label'.tr()),
        findsOneWidget,
      );
      expect(
        find.text('pharmacy_booking.review.subtotal_value'.tr()),
        findsOneWidget,
      );
      expect(
        find.text('pharmacy_booking.review.delivery_fee_label'.tr()),
        findsOneWidget,
      );
      expect(find.text('15 ج.م'), findsOneWidget);
      expect(
        find.text('pharmacy_booking.review.vat_label'.tr()),
        findsOneWidget,
      );
      expect(
        find.text('pharmacy_booking.review.vat_value'.tr()),
        findsOneWidget,
      );
      expect(
        find.text('pharmacy_booking.review.total_label'.tr()),
        findsOneWidget,
      );
      expect(
        find.text(
          'pharmacy_booking.review.total_value'.tr(args: const ['15 ج.م']),
        ),
        findsOneWidget,
      );
      expect(
        find.text('pharmacy_booking.review.estimate_disclaimer'.tr()),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('tapping "edit" navigates to the upload step', (tester) async {
    await pumpWithRouter(tester);

    await tapEdit(tester);

    expect(find.text('upload-placeholder'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('confirming shows a brief loading state then navigates to the '
      'confirmation screen with the selected pharmacy name', (tester) async {
    await pumpWithRouter(tester);

    final submitFinder = find.widgetWithText(
      FilledButton,
      'pharmacy_booking.review.confirm_cta'.tr(),
    );
    tester.widget<FilledButton>(submitFinder).onPressed!();
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.pumpAndSettle();

    expect(find.text('confirmation-screen:${_pharmacy.name}'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

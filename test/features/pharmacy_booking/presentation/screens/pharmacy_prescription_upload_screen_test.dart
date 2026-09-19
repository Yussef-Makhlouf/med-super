import 'dart:typed_data';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/misc.dart' show Override;
import 'package:med_super/core/widgets/step_progress_header.dart';
import 'package:med_super/features/pharmacy_booking/domain/entities/delivery_method.dart';
import 'package:med_super/features/pharmacy_booking/domain/entities/prescription_image.dart';
import 'package:med_super/features/pharmacy_booking/presentation/controllers/pharmacy_upload_providers.dart';
import 'package:med_super/features/pharmacy_booking/presentation/screens/pharmacy_prescription_upload_screen.dart';
import 'package:solar_icons/solar_icons.dart';

import '../../../../helpers/pump_localized_widget.dart';

/// Seeds [UploadedPrescriptionImages] with a fixed list instead of the real
/// empty default, so thumbnail-row/delete-badge tests don't depend on the
/// (unmockable in `flutter_test`) real file picker plugin.
class _SeededImages extends UploadedPrescriptionImages {
  _SeededImages(this._seed);

  final List<PrescriptionImage> _seed;

  @override
  List<PrescriptionImage> build() => _seed;
}

class _SeededDeliveryMethod extends SelectedDeliveryMethod {
  _SeededDeliveryMethod(this._seed);

  final DeliveryMethod _seed;

  @override
  DeliveryMethod build() => _seed;
}

/// Matches only the selected-delivery-card's check badge (hardcoded as
/// `Icon(Icons.check, size: 14, color: Colors.white)` in the screen), not
/// `StepProgressHeader`'s own `Icons.check` rendered for the done "الرفع"
/// step — a bare `find.byIcon(Icons.check)` would match both and always
/// find 2, since this screen's stepper spec requires step 0 done-checked.
final Finder deliveryCardCheckIcon = find.byWidgetPredicate(
  (widget) => widget is Icon && widget.icon == Icons.check && widget.size == 14,
);

void main() {
  // A real, decodable 1x1 transparent PNG. Bytes (not just a null-able
  // placeholder) are required here: the screen only renders an
  // `Image.memory` thumbnail when `image.bytes != null`.
  final onePixelPng = Uint8List.fromList([
    137, 80, 78, 71, 13, 10, 26, 10, 0, 0, 0, 13, 73, 72, 68, 82, //
    0, 0, 0, 1, 0, 0, 0, 1, 8, 6, 0, 0, 0, 31, 21, 196, 137, //
    0, 0, 0, 10, 73, 68, 65, 84, 120, 156, 99, 0, 1, 0, 0, 5, 0, 1, //
    13, 10, 45, 180, 0, 0, 0, 0, 73, 69, 78, 68, 174, 66, 96, 130, //
  ]);
  final seededImages = [
    PrescriptionImage(id: 'img-1', path: '/tmp/one.png', bytes: onePixelPng),
    PrescriptionImage(id: 'img-2', path: '/tmp/two.png', bytes: onePixelPng),
  ];

  List<Override> overridesWith({
    List<PrescriptionImage>? images,
    DeliveryMethod? deliveryMethod,
  }) => [
    if (images != null)
      uploadedPrescriptionImagesProvider.overrideWith(
        () => _SeededImages(images),
      ),
    if (deliveryMethod != null)
      selectedDeliveryMethodProvider.overrideWith(
        () => _SeededDeliveryMethod(deliveryMethod),
      ),
  ];

  testWidgets(
    'renders the plain title header, a 3-step stepper on step 1, and the '
    'upload box, all with the real translated copy',
    (tester) async {
      await pumpLocalizedWidget(
        tester,
        const PharmacyPrescriptionUploadScreen(),
      );
      await tester.pumpAndSettle();

      // A single back-arrow IconButton (`context.pop()`), balanced by a
      // same-width trailing SizedBox so the title stays centered.
      expect(find.byIcon(SolarIconsOutline.arrowRight), findsOneWidget);
      expect(find.text('pharmacy_booking.upload.title'.tr()), findsOneWidget);

      final stepper = tester.widget<StepProgressHeader>(
        find.byType(StepProgressHeader),
      );
      expect(stepper.currentStep, 0);
      expect(stepper.stepLabels, [
        'pharmacy_booking.step_upload'.tr(),
        'pharmacy_booking.step_pharmacy'.tr(),
        'pharmacy_booking.step_delivery'.tr(),
      ]);

      expect(find.byIcon(SolarIconsOutline.cameraAdd), findsOneWidget);
      expect(
        find.text('pharmacy_booking.upload.upload_cta'.tr()),
        findsOneWidget,
      );
      expect(
        find.text('pharmacy_booking.upload.upload_hint'.tr()),
        findsOneWidget,
      );
      // No images yet, so no thumbnail row.
      expect(find.byIcon(Icons.close), findsNothing);
      expect(find.byType(Image), findsNothing);

      // Delivery method section with all three cards.
      expect(
        find.text('pharmacy_booking.upload.delivery_method_title'.tr()),
        findsOneWidget,
      );
      expect(
        find.text('pharmacy_booking.upload.pickup_title'.tr()),
        findsOneWidget,
      );
      expect(
        find.text('pharmacy_booking.upload.delivery_title'.tr()),
        findsOneWidget,
      );
      expect(
        find.text('pharmacy_booking.upload.clinic_handover_title'.tr()),
        findsOneWidget,
      );

      // Home delivery is selected by default -> exactly one check badge.
      // (find.byIcon(Icons.check) alone would also match StepProgressHeader's
      // done-step badge for step 0, which this screen's spec requires to
      // render checkmarked here — see deliveryCardCheckIcon's doc comment.)
      expect(deliveryCardCheckIcon, findsOneWidget);

      expect(
        find.text('pharmacy_booking.upload.notes_label'.tr()),
        findsOneWidget,
      );
      expect(find.byType(TextField), findsOneWidget);

      expect(
        find.text('pharmacy_booking.upload.submit_cta'.tr()),
        findsOneWidget,
      );

      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('the submit CTA starts disabled with no image attached', (
    tester,
  ) async {
    await pumpLocalizedWidget(tester, const PharmacyPrescriptionUploadScreen());
    await tester.pumpAndSettle();

    final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
    expect(button.onPressed, isNull);
  });

  testWidgets('enables the submit CTA once an image is attached', (
    tester,
  ) async {
    await pumpLocalizedWidget(
      tester,
      const PharmacyPrescriptionUploadScreen(),
      overrides: overridesWith(images: seededImages),
    );
    await tester.pumpAndSettle();

    final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
    expect(button.onPressed, isNotNull);
  });

  testWidgets(
    'renders one thumbnail plus one delete badge per attached image, and a '
    'trailing add tile',
    (tester) async {
      await pumpLocalizedWidget(
        tester,
        const PharmacyPrescriptionUploadScreen(),
        overrides: overridesWith(images: seededImages),
      );
      await tester.pumpAndSettle();

      expect(find.byType(Image), findsNWidgets(seededImages.length));
      expect(find.byIcon(Icons.close), findsNWidgets(seededImages.length));
      expect(find.byIcon(Icons.add), findsOneWidget);

      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('tapping an image delete badge removes only that image', (
    tester,
  ) async {
    final container = ProviderContainer(
      overrides: overridesWith(images: seededImages),
    );
    addTearDown(container.dispose);

    await pumpLocalizedWidget(
      tester,
      UncontrolledProviderScope(
        container: container,
        child: const PharmacyPrescriptionUploadScreen(),
      ),
    );
    await tester.pumpAndSettle();

    final firstThumbnail = find.byKey(const ValueKey('img-1'));
    final deleteBadge = find.descendant(
      of: firstThumbnail,
      matching: find.byIcon(Icons.close),
    );
    expect(deleteBadge, findsOneWidget);

    await tester.tap(deleteBadge);
    await tester.pumpAndSettle();

    final remaining = container.read(uploadedPrescriptionImagesProvider);
    expect(remaining.map((i) => i.id), ['img-2']);
    expect(find.byType(Image), findsOneWidget);

    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'the pickup card is selectable and shows the check badge once tapped',
    (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await pumpLocalizedWidget(
        tester,
        UncontrolledProviderScope(
          container: container,
          child: const PharmacyPrescriptionUploadScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Home delivery is the default -> already one check badge.
      expect(deliveryCardCheckIcon, findsOneWidget);
      expect(
        container.read(selectedDeliveryMethodProvider),
        DeliveryMethod.homeDelivery,
      );

      final pickupCard = find.ancestor(
        of: find.text('pharmacy_booking.upload.pickup_title'.tr()),
        matching: find.byType(InkWell),
      );
      expect(pickupCard, findsOneWidget);
      tester.widget<InkWell>(pickupCard).onTap!();
      await tester.pumpAndSettle();

      expect(
        container.read(selectedDeliveryMethodProvider),
        DeliveryMethod.pickup,
      );
      // Still exactly one check badge — mutually exclusive selection.
      expect(deliveryCardCheckIcon, findsOneWidget);

      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'the clinic-handover card is selectable and shows the check badge once '
    'tapped',
    (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await pumpLocalizedWidget(
        tester,
        UncontrolledProviderScope(
          container: container,
          child: const PharmacyPrescriptionUploadScreen(),
        ),
      );
      await tester.pumpAndSettle();

      final clinicCard = find.ancestor(
        of: find.text('pharmacy_booking.upload.clinic_handover_title'.tr()),
        matching: find.byType(InkWell),
      );
      expect(clinicCard, findsOneWidget);
      tester.widget<InkWell>(clinicCard).onTap!();
      await tester.pumpAndSettle();

      expect(
        container.read(selectedDeliveryMethodProvider),
        DeliveryMethod.clinicHandover,
      );
      // Still exactly one check badge — mutually exclusive selection.
      expect(deliveryCardCheckIcon, findsOneWidget);

      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'selecting the home-delivery card after pickup moves the check badge '
    'back to it',
    (tester) async {
      final container = ProviderContainer(
        overrides: overridesWith(deliveryMethod: DeliveryMethod.pickup),
      );
      addTearDown(container.dispose);

      await pumpLocalizedWidget(
        tester,
        UncontrolledProviderScope(
          container: container,
          child: const PharmacyPrescriptionUploadScreen(),
        ),
      );
      await tester.pumpAndSettle();

      final homeCard = find.ancestor(
        of: find.text('pharmacy_booking.upload.delivery_title'.tr()),
        matching: find.byType(InkWell),
      );
      tester.widget<InkWell>(homeCard).onTap!();
      await tester.pumpAndSettle();

      expect(
        container.read(selectedDeliveryMethodProvider),
        DeliveryMethod.homeDelivery,
      );
      expect(deliveryCardCheckIcon, findsOneWidget);

      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'tapping the upload box surfaces an error instead of crashing (no file '
    'picker plugin registered under flutter_test)',
    (tester) async {
      await pumpLocalizedWidget(
        tester,
        const PharmacyPrescriptionUploadScreen(),
      );
      await tester.pumpAndSettle();

      final uploadBox = find.ancestor(
        of: find.byIcon(SolarIconsOutline.cameraAdd),
        matching: find.byType(InkWell),
      );
      expect(uploadBox, findsOneWidget);
      await tester.tap(uploadBox);
      await tester.pumpAndSettle();

      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.byType(PharmacyPrescriptionUploadScreen), findsOneWidget);
    },
  );

  testWidgets('typing a note updates the notes text field', (tester) async {
    await pumpLocalizedWidget(tester, const PharmacyPrescriptionUploadScreen());
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'Please deliver quickly');
    await tester.pumpAndSettle();

    expect(find.text('Please deliver quickly'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

import 'dart:typed_data';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/misc.dart' show Override;
import 'package:med_super/core/widgets/step_progress_header.dart';
import 'package:med_super/features/lab_booking/domain/entities/lab_request_image.dart';
import 'package:med_super/features/lab_booking/domain/entities/lab_service_type.dart';
import 'package:med_super/features/lab_booking/presentation/controllers/lab_upload_providers.dart';
import 'package:med_super/features/lab_booking/presentation/screens/lab_request_upload_screen.dart';

import '../../../../helpers/pump_localized_widget.dart';

/// Seeds [UploadedLabRequestImages] with a fixed list instead of the real
/// empty default, so thumbnail-row/delete-badge tests don't depend on the
/// (unmockable in `flutter_test`) real file picker plugin.
class _SeededImages extends UploadedLabRequestImages {
  _SeededImages(this._seed);

  final List<LabRequestImage> _seed;

  @override
  List<LabRequestImage> build() => _seed;
}

class _SeededServiceType extends SelectedLabServiceType {
  _SeededServiceType(this._seed);

  final LabServiceType? _seed;

  @override
  LabServiceType? build() => _seed;
}

void main() {
  // A real, decodable 1x1 transparent PNG. Bytes (not just a null-able
  // placeholder) are required here: the screen only renders an
  // `Image.memory` thumbnail when `image.bytes != null` — with no bytes it
  // falls back to a bare placeholder icon instead, which the assertions
  // below that count `find.byType(Image)` would otherwise miss entirely.
  // Using bytes that actually decode (rather than garbage bytes routed
  // through `errorBuilder`) avoids any async decode-failure noise landing
  // on `tester.takeException()` in the tests that check it.
  final onePixelPng = Uint8List.fromList([
    137, 80, 78, 71, 13, 10, 26, 10, 0, 0, 0, 13, 73, 72, 68, 82, //
    0, 0, 0, 1, 0, 0, 0, 1, 8, 6, 0, 0, 0, 31, 21, 196, 137, //
    0, 0, 0, 10, 73, 68, 65, 84, 120, 156, 99, 0, 1, 0, 0, 5, 0, 1, //
    13, 10, 45, 180, 0, 0, 0, 0, 73, 69, 78, 68, 174, 66, 96, 130, //
  ]);
  final seededImages = [
    LabRequestImage(id: 'img-1', path: '/tmp/one.png', bytes: onePixelPng),
    LabRequestImage(id: 'img-2', path: '/tmp/two.png', bytes: onePixelPng),
  ];

  List<Override> overridesWith({
    List<LabRequestImage>? images,
    LabServiceType? serviceType,
  }) => [
    if (images != null)
      uploadedLabRequestImagesProvider.overrideWith(
        () => _SeededImages(images),
      ),
    if (serviceType != null)
      selectedLabServiceTypeProvider.overrideWith(
        () => _SeededServiceType(serviceType),
      ),
  ];

  testWidgets(
    'renders the header, a 3-step stepper on step 0, and the upload box, '
    'all with the real translated copy',
    (tester) async {
      await pumpLocalizedWidget(tester, const LabRequestUploadScreen());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.help_outline), findsNothing);
      expect(find.byIcon(Icons.arrow_forward), findsOneWidget);
      expect(find.text('lab_booking.upload.title'.tr()), findsOneWidget);

      final stepper = tester.widget<StepProgressHeader>(
        find.byType(StepProgressHeader),
      );
      expect(stepper.currentStep, 0);
      expect(stepper.stepLabels, [
        'lab_booking.step_upload'.tr(),
        'lab_booking.step_select_lab'.tr(),
        'lab_booking.step_review'.tr(),
      ]);

      expect(find.byIcon(Icons.add_a_photo_outlined), findsOneWidget);
      expect(find.text('lab_booking.upload.upload_cta'.tr()), findsOneWidget);
      expect(find.text('lab_booking.upload.upload_hint'.tr()), findsOneWidget);
      // No images yet, so no thumbnail row (no close/delete badges, no
      // rendered thumbnail images, no small "+" tile).
      expect(find.byIcon(Icons.close), findsNothing);
      expect(find.byType(Image), findsNothing);

      // "نوع الخدمة" section and both cards, with their real copy.
      expect(
        find.text('lab_booking.upload.service_type_title'.tr()),
        findsOneWidget,
      );
      expect(
        find.text('lab_booking.upload.service_branch_title'.tr()),
        findsOneWidget,
      );
      expect(
        find.text('lab_booking.upload.service_branch_subtitle'.tr()),
        findsOneWidget,
      );
      expect(
        find.text('lab_booking.upload.service_home_title'.tr()),
        findsOneWidget,
      );
      expect(
        find.text('lab_booking.upload.service_home_subtitle'.tr()),
        findsOneWidget,
      );

      expect(find.text('lab_booking.upload.continue_cta'.tr()), findsOneWidget);

      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'the continue CTA starts disabled with no image and no service type',
    (tester) async {
      await pumpLocalizedWidget(tester, const LabRequestUploadScreen());
      await tester.pumpAndSettle();

      final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(button.onPressed, isNull);
    },
  );

  testWidgets(
    'stays disabled with only an image attached (no service type yet)',
    (tester) async {
      await pumpLocalizedWidget(
        tester,
        const LabRequestUploadScreen(),
        overrides: overridesWith(images: seededImages),
      );
      await tester.pumpAndSettle();

      final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(button.onPressed, isNull);
    },
  );

  testWidgets('stays disabled with only a service type chosen (no image yet)', (
    tester,
  ) async {
    await pumpLocalizedWidget(
      tester,
      const LabRequestUploadScreen(),
      overrides: overridesWith(serviceType: LabServiceType.branchVisit),
    );
    await tester.pumpAndSettle();

    final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
    expect(button.onPressed, isNull);
  });

  testWidgets(
    'enables the continue CTA once both an image and a service type are set',
    (tester) async {
      await pumpLocalizedWidget(
        tester,
        const LabRequestUploadScreen(),
        overrides: overridesWith(
          images: seededImages,
          serviceType: LabServiceType.homeCollection,
        ),
      );
      await tester.pumpAndSettle();

      final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(button.onPressed, isNotNull);
    },
  );

  testWidgets(
    'renders one thumbnail plus one delete badge per attached image, and a '
    'trailing add tile',
    (tester) async {
      await pumpLocalizedWidget(
        tester,
        const LabRequestUploadScreen(),
        overrides: overridesWith(images: seededImages),
      );
      await tester.pumpAndSettle();

      expect(find.byType(Image), findsNWidgets(seededImages.length));
      expect(find.byIcon(Icons.close), findsNWidgets(seededImages.length));
      // The trailing "+" tile uses Icons.add, distinct from the big upload
      // box's Icons.add_a_photo_outlined.
      expect(find.byIcon(Icons.add), findsOneWidget);

      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'neither service-type card shows the selected check badge before the '
    'patient picks one',
    (tester) async {
      await pumpLocalizedWidget(tester, const LabRequestUploadScreen());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.check), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'delete badge and trailing add tile carry the real tooltip copy',
    (tester) async {
      await pumpLocalizedWidget(
        tester,
        const LabRequestUploadScreen(),
        overrides: overridesWith(images: seededImages),
      );
      await tester.pumpAndSettle();

      final addTooltip = tester.widget<Tooltip>(
        find.ancestor(
          of: find.byIcon(Icons.add),
          matching: find.byType(Tooltip),
        ),
      );
      expect(addTooltip.message, 'lab_booking.upload.add_image_tooltip'.tr());

      final removeTooltips = tester
          .widgetList<Tooltip>(
            find.ancestor(
              of: find.byIcon(Icons.close),
              matching: find.byType(Tooltip),
            ),
          )
          .toList();
      expect(removeTooltips, hasLength(seededImages.length));
      for (final tooltip in removeTooltips) {
        expect(tooltip.message, 'lab_booking.upload.remove_image_tooltip'.tr());
      }

      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'tapping the trailing "+" tile triggers the same picker as the big '
    'upload box',
    (tester) async {
      await pumpLocalizedWidget(
        tester,
        const LabRequestUploadScreen(),
        overrides: overridesWith(images: seededImages),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      // The plugin isn't registered under flutter_test, so the picker call
      // fails the same way it does from the big upload box — surfaced as a
      // snackbar rather than a crash.
      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.byType(LabRequestUploadScreen), findsOneWidget);
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
        child: const LabRequestUploadScreen(),
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

    final remaining = container.read(uploadedLabRequestImagesProvider);
    expect(remaining.map((i) => i.id), ['img-2']);
    expect(find.byType(Image), findsOneWidget);

    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'tapping the home-collection card selects it and shows the check badge',
    (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await pumpLocalizedWidget(
        tester,
        UncontrolledProviderScope(
          container: container,
          child: const LabRequestUploadScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.check), findsNothing);

      final homeCard = find.ancestor(
        of: find.text('lab_booking.upload.service_home_title'.tr()),
        matching: find.byType(InkWell),
      );
      expect(homeCard, findsOneWidget);
      tester.widget<InkWell>(homeCard).onTap!();
      await tester.pumpAndSettle();

      expect(
        container.read(selectedLabServiceTypeProvider),
        LabServiceType.homeCollection,
      );
      expect(find.byIcon(Icons.check), findsOneWidget);

      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'selecting the other service type card moves the check badge to it',
    (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await pumpLocalizedWidget(
        tester,
        UncontrolledProviderScope(
          container: container,
          child: const LabRequestUploadScreen(),
        ),
      );
      await tester.pumpAndSettle();

      final branchCard = find.ancestor(
        of: find.text('lab_booking.upload.service_branch_title'.tr()),
        matching: find.byType(InkWell),
      );
      tester.widget<InkWell>(branchCard).onTap!();
      await tester.pumpAndSettle();
      expect(
        container.read(selectedLabServiceTypeProvider),
        LabServiceType.branchVisit,
      );

      final homeCard = find.ancestor(
        of: find.text('lab_booking.upload.service_home_title'.tr()),
        matching: find.byType(InkWell),
      );
      tester.widget<InkWell>(homeCard).onTap!();
      await tester.pumpAndSettle();

      expect(
        container.read(selectedLabServiceTypeProvider),
        LabServiceType.homeCollection,
      );
      expect(find.byIcon(Icons.check), findsOneWidget);

      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'tapping the upload box surfaces an error instead of crashing (no file '
    'picker plugin registered under flutter_test)',
    (tester) async {
      await pumpLocalizedWidget(tester, const LabRequestUploadScreen());
      await tester.pumpAndSettle();

      final uploadBox = find.ancestor(
        of: find.byIcon(Icons.add_a_photo_outlined),
        matching: find.byType(InkWell),
      );
      expect(uploadBox, findsOneWidget);
      await tester.tap(uploadBox);
      await tester.pumpAndSettle();

      expect(find.byType(SnackBar), findsOneWidget);
      // The screen itself must not crash even though the picker call fails.
      expect(find.byType(LabRequestUploadScreen), findsOneWidget);
    },
  );
}

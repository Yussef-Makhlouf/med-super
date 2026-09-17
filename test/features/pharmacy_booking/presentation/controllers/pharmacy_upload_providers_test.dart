import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:med_super/features/pharmacy_booking/presentation/controllers/pharmacy_upload_providers.dart';

void main() {
  late ProviderContainer container;

  setUp(() {
    container = ProviderContainer();
    addTearDown(container.dispose);
  });

  test('maxPrescriptionImages matches the backend\'s fileUrls cap (5)', () {
    expect(maxPrescriptionImages, 5);
  });

  test('addImages accepts up to maxPrescriptionImages and reports how many were added', () {
    final notifier = container.read(uploadedPrescriptionImagesProvider.notifier);

    final added = notifier.addImages(
      List.generate(maxPrescriptionImages, (i) => (path: 'img$i.png', bytes: null)),
    );

    expect(added, maxPrescriptionImages);
    expect(container.read(uploadedPrescriptionImagesProvider), hasLength(maxPrescriptionImages));
  });

  test('addImages drops extras once the cap is already reached, no backend 400 risk', () {
    final notifier = container.read(uploadedPrescriptionImagesProvider.notifier);
    notifier.addImages(
      List.generate(maxPrescriptionImages, (i) => (path: 'img$i.png', bytes: null)),
    );

    final added = notifier.addImages([(path: 'one-too-many.png', bytes: null)]);

    expect(added, 0);
    expect(container.read(uploadedPrescriptionImagesProvider), hasLength(maxPrescriptionImages));
  });

  test('addImages partially accepts when only some slots remain', () {
    final notifier = container.read(uploadedPrescriptionImagesProvider.notifier);
    notifier.addImages(
      List.generate(maxPrescriptionImages - 1, (i) => (path: 'img$i.png', bytes: null)),
    );

    final added = notifier.addImages([
      (path: 'a.png', bytes: null),
      (path: 'b.png', bytes: null),
    ]);

    expect(added, 1);
    expect(container.read(uploadedPrescriptionImagesProvider), hasLength(maxPrescriptionImages));
  });
}

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:med_super/features/lab_booking/domain/entities/lab_service_type.dart';
import 'package:med_super/features/lab_booking/presentation/controllers/lab_upload_providers.dart';

void main() {
  late ProviderContainer container;

  setUp(() {
    container = ProviderContainer();
    addTearDown(container.dispose);
  });

  group('uploadedLabRequestImagesProvider', () {
    test('starts empty', () {
      expect(container.read(uploadedLabRequestImagesProvider), isEmpty);
    });

    test('addImage appends a single image', () {
      container
          .read(uploadedLabRequestImagesProvider.notifier)
          .addImage('/tmp/a.png');

      final images = container.read(uploadedLabRequestImagesProvider);
      expect(images, hasLength(1));
      expect(images.single.path, '/tmp/a.png');
    });

    test('addImage twice keeps both, each with a distinct id', () {
      final notifier = container.read(
        uploadedLabRequestImagesProvider.notifier,
      );
      notifier.addImage('/tmp/a.png');
      notifier.addImage('/tmp/b.png');

      final images = container.read(uploadedLabRequestImagesProvider);
      expect(images.map((i) => i.path), ['/tmp/a.png', '/tmp/b.png']);
      expect(images[0].id, isNot(images[1].id));
    });

    test('addImages appends every path in order, in one call', () {
      container.read(uploadedLabRequestImagesProvider.notifier).addImages([
        (path: '/tmp/a.png', bytes: null),
        (path: '/tmp/b.png', bytes: null),
        (path: '/tmp/c.png', bytes: null),
      ]);

      final images = container.read(uploadedLabRequestImagesProvider);
      expect(images.map((i) => i.path), [
        '/tmp/a.png',
        '/tmp/b.png',
        '/tmp/c.png',
      ]);
    });

    test('addImages with an empty iterable is a no-op', () {
      final notifier = container.read(
        uploadedLabRequestImagesProvider.notifier,
      );
      notifier.addImage('/tmp/a.png');
      notifier.addImages(const []);

      expect(container.read(uploadedLabRequestImagesProvider), hasLength(1));
    });

    test('removeImage drops only the matching image', () {
      final notifier = container.read(
        uploadedLabRequestImagesProvider.notifier,
      );
      notifier.addImages([
        (path: '/tmp/a.png', bytes: null),
        (path: '/tmp/b.png', bytes: null),
      ]);
      final idToRemove = container
          .read(uploadedLabRequestImagesProvider)
          .first
          .id;

      notifier.removeImage(idToRemove);

      final images = container.read(uploadedLabRequestImagesProvider);
      expect(images, hasLength(1));
      expect(images.single.path, '/tmp/b.png');
    });

    test('removeImage with an unknown id is a no-op', () {
      final notifier = container.read(
        uploadedLabRequestImagesProvider.notifier,
      );
      notifier.addImage('/tmp/a.png');
      notifier.removeImage('does-not-exist');

      expect(container.read(uploadedLabRequestImagesProvider), hasLength(1));
    });
  });

  group('selectedLabServiceTypeProvider', () {
    test('defaults to null (no pre-selection)', () {
      expect(container.read(selectedLabServiceTypeProvider), isNull);
    });

    test('select stores the chosen service type', () {
      container
          .read(selectedLabServiceTypeProvider.notifier)
          .select(LabServiceType.homeCollection);

      expect(
        container.read(selectedLabServiceTypeProvider),
        LabServiceType.homeCollection,
      );
    });
  });

  group('canContinueFromUploadProvider', () {
    test('false when neither an image nor a service type is set', () {
      expect(container.read(canContinueFromUploadProvider), isFalse);
    });

    test('false with only an image attached', () {
      container
          .read(uploadedLabRequestImagesProvider.notifier)
          .addImage('/tmp/a.png');

      expect(container.read(canContinueFromUploadProvider), isFalse);
    });

    test('false with only a service type chosen', () {
      container
          .read(selectedLabServiceTypeProvider.notifier)
          .select(LabServiceType.branchVisit);

      expect(container.read(canContinueFromUploadProvider), isFalse);
    });

    test('true once both an image and a service type are set', () {
      container
          .read(uploadedLabRequestImagesProvider.notifier)
          .addImage('/tmp/a.png');
      container
          .read(selectedLabServiceTypeProvider.notifier)
          .select(LabServiceType.branchVisit);

      expect(container.read(canContinueFromUploadProvider), isTrue);
    });

    test('goes back to false after the only image is removed', () {
      final images = container.read(uploadedLabRequestImagesProvider.notifier);
      images.addImage('/tmp/a.png');
      container
          .read(selectedLabServiceTypeProvider.notifier)
          .select(LabServiceType.branchVisit);
      expect(container.read(canContinueFromUploadProvider), isTrue);

      final id = container.read(uploadedLabRequestImagesProvider).single.id;
      images.removeImage(id);

      expect(container.read(canContinueFromUploadProvider), isFalse);
    });
  });
}

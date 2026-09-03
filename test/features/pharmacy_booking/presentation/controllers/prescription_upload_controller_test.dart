import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:med_super/features/pharmacy_booking/data/datasources/remote/prescription_remote_datasource.dart';
import 'package:med_super/features/pharmacy_booking/domain/entities/prescription_image.dart';
import 'package:med_super/features/pharmacy_booking/domain/entities/prescription_upload_result.dart';
import 'package:med_super/features/pharmacy_booking/presentation/controllers/prescription_upload_controller.dart';

class _MockPrescriptionRemoteDatasource extends Mock
    implements PrescriptionRemoteDatasource {}

void main() {
  late _MockPrescriptionRemoteDatasource datasource;
  late ProviderContainer container;

  const images = [
    PrescriptionImage(id: 'img-1', path: '/tmp/one.png'),
    PrescriptionImage(id: 'img-2', path: '/tmp/two.png'),
  ];

  setUpAll(() {
    registerFallbackValue(<PrescriptionImage>[]);
  });

  setUp(() {
    datasource = _MockPrescriptionRemoteDatasource();
    container = ProviderContainer(
      overrides: [
        prescriptionRemoteDatasourceProvider.overrideWithValue(datasource),
      ],
    );
    addTearDown(container.dispose);
  });

  test('starts as AsyncData(null) — not submitted yet', () {
    expect(
      container.read(prescriptionUploadControllerProvider),
      const AsyncData<PrescriptionUploadResult?>(null),
    );
  });

  test(
    'submit forwards the picked images to the datasource and stores the '
    'result on success',
    () async {
      when(
        () => datasource.upload(
          images: any(named: 'images'),
          notes: any(named: 'notes'),
        ),
      ).thenAnswer(
        (_) async => const PrescriptionUploadResult(
          prescriptionId: 'presc-1',
          status: 'QUALITY_CHECK_PASSED',
        ),
      );

      await container
          .read(prescriptionUploadControllerProvider.notifier)
          .submit(images: images, notes: 'take with food');

      final captured = verify(
        () => datasource.upload(
          images: captureAny(named: 'images'),
          notes: 'take with food',
        ),
      ).captured.single as List<PrescriptionImage>;
      expect(captured, hasLength(2));

      expect(
        container.read(prescriptionUploadControllerProvider),
        const AsyncData<PrescriptionUploadResult?>(
          PrescriptionUploadResult(
            prescriptionId: 'presc-1',
            status: 'QUALITY_CHECK_PASSED',
          ),
        ),
      );
    },
  );

  test('submit surfaces the datasource failure as AsyncError', () async {
    when(
      () => datasource.upload(
        images: any(named: 'images'),
        notes: any(named: 'notes'),
      ),
    ).thenThrow(Exception('network down'));

    await container
        .read(prescriptionUploadControllerProvider.notifier)
        .submit(images: images);

    expect(
      container.read(prescriptionUploadControllerProvider).hasError,
      isTrue,
    );
  });
}

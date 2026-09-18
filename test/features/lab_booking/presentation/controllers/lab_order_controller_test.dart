import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:med_super/features/lab_booking/data/datasources/remote/lab_order_remote_datasource.dart';
import 'package:med_super/features/lab_booking/domain/entities/lab_order_create_result.dart';
import 'package:med_super/features/lab_booking/presentation/controllers/lab_order_controller.dart';
import 'package:med_super/features/lab_booking/presentation/controllers/lab_order_list_providers.dart';

class _MockLabOrderRemoteDatasource extends Mock
    implements LabOrderRemoteDatasource {}

void main() {
  late _MockLabOrderRemoteDatasource datasource;
  late ProviderContainer container;

  setUp(() {
    datasource = _MockLabOrderRemoteDatasource();
    container = ProviderContainer(
      overrides: [labOrderRemoteDatasourceProvider.overrideWithValue(datasource)],
    );
    addTearDown(container.dispose);
  });

  test('starts as AsyncData(null) — not submitted yet', () {
    expect(
      container.read(labOrderControllerProvider),
      const AsyncData<LabOrderCreateResult?>(null),
    );
  });

  test(
    'submit forwards every field to the datasource, storing the result on '
    'success',
    () async {
      when(
        () => datasource.create(
          labBranchId: any(named: 'labBranchId'),
          collectionType: any(named: 'collectionType'),
          prescriptionId: any(named: 'prescriptionId'),
          testCodes: any(named: 'testCodes'),
        ),
      ).thenAnswer(
        (_) async => const LabOrderCreateResult(
          labOrderId: 'order-1',
          status: 'REQUESTED',
        ),
      );

      await container
          .read(labOrderControllerProvider.notifier)
          .submit(
            labBranchId: 'branch-1',
            collectionType: 'VISIT',
            prescriptionId: 'presc-1',
          );

      verify(
        () => datasource.create(
          labBranchId: 'branch-1',
          collectionType: 'VISIT',
          prescriptionId: 'presc-1',
          testCodes: null,
        ),
      ).called(1);
      expect(
        container.read(labOrderControllerProvider),
        const AsyncData<LabOrderCreateResult?>(
          LabOrderCreateResult(labOrderId: 'order-1', status: 'REQUESTED'),
        ),
      );
    },
  );

  test('submit surfaces a datasource failure as AsyncError', () async {
    when(
      () => datasource.create(
        labBranchId: any(named: 'labBranchId'),
        collectionType: any(named: 'collectionType'),
        prescriptionId: any(named: 'prescriptionId'),
        testCodes: any(named: 'testCodes'),
      ),
    ).thenThrow(Exception('network down'));

    await container
        .read(labOrderControllerProvider.notifier)
        .submit(
          labBranchId: 'branch-1',
          collectionType: 'VISIT',
          prescriptionId: 'presc-1',
        );

    expect(container.read(labOrderControllerProvider).hasError, isTrue);
  });
}

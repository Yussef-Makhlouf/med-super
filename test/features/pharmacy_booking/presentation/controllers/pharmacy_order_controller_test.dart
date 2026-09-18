import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:mocktail/mocktail.dart';
import 'package:med_super/features/pharmacy_booking/data/datasources/remote/pharmacy_order_remote_datasource.dart';
import 'package:med_super/features/pharmacy_booking/domain/entities/pharmacy_order_create_result.dart';
import 'package:med_super/features/pharmacy_booking/presentation/controllers/pharmacy_order_controller.dart';
import 'package:med_super/features/pharmacy_booking/presentation/controllers/pharmacy_search_providers.dart';
import 'package:med_super/features/provider_registration/presentation/controllers/clinic_location_provider.dart';

class _MockPharmacyOrderRemoteDatasource extends Mock
    implements PharmacyOrderRemoteDatasource {}

class _MockClinicLocationService extends Mock implements ClinicLocationService {}

void main() {
  late _MockPharmacyOrderRemoteDatasource datasource;
  late _MockClinicLocationService locationService;
  late ProviderContainer container;

  const position = LatLng(30.0444, 31.2357);

  setUp(() {
    datasource = _MockPharmacyOrderRemoteDatasource();
    locationService = _MockClinicLocationService();
    container = ProviderContainer(
      overrides: [
        pharmacyOrderRemoteDatasourceProvider.overrideWithValue(datasource),
        pharmacyLocationServiceProvider.overrideWithValue(locationService),
      ],
    );
    addTearDown(container.dispose);
  });

  test('starts as AsyncData(null) — not submitted yet', () {
    expect(
      container.read(pharmacyOrderControllerProvider),
      const AsyncData<PharmacyOrderCreateResult?>(null),
    );
  });

  test(
    'submit reads the device location and forwards it plus every field to '
    'the datasource, storing the result on success',
    () async {
      when(() => locationService.getCurrentPosition()).thenAnswer((_) async => position);
      when(
        () => datasource.create(
          prescriptionId: any(named: 'prescriptionId'),
          fulfillmentType: any(named: 'fulfillmentType'),
          lat: any(named: 'lat'),
          lng: any(named: 'lng'),
          pharmacyBranchId: any(named: 'pharmacyBranchId'),
        ),
      ).thenAnswer(
        (_) async => const PharmacyOrderCreateResult(
          pharmacyOrderId: 'order-1',
          status: 'RECEIVED',
          broadcastedBranchIds: ['branch-1'],
        ),
      );

      await container
          .read(pharmacyOrderControllerProvider.notifier)
          .submit(
            prescriptionId: 'presc-1',
            fulfillmentType: 'DELIVERY',
            pharmacyBranchId: 'branch-1',
          );

      verify(
        () => datasource.create(
          prescriptionId: 'presc-1',
          fulfillmentType: 'DELIVERY',
          lat: 30.0444,
          lng: 31.2357,
          pharmacyBranchId: 'branch-1',
        ),
      ).called(1);
      expect(
        container.read(pharmacyOrderControllerProvider),
        const AsyncData<PharmacyOrderCreateResult?>(
          PharmacyOrderCreateResult(
            pharmacyOrderId: 'order-1',
            status: 'RECEIVED',
            broadcastedBranchIds: ['branch-1'],
          ),
        ),
      );
    },
  );

  test(
    'submit succeeds without device location when pharmacyBranchId is given '
    '— a chosen branch does not need the caller\'s GPS (File 12 Part 46)',
    () async {
      when(() => locationService.getCurrentPosition()).thenAnswer((_) async => null);
      when(
        () => datasource.create(
          prescriptionId: any(named: 'prescriptionId'),
          fulfillmentType: any(named: 'fulfillmentType'),
          lat: any(named: 'lat'),
          lng: any(named: 'lng'),
          pharmacyBranchId: any(named: 'pharmacyBranchId'),
        ),
      ).thenAnswer(
        (_) async => const PharmacyOrderCreateResult(
          pharmacyOrderId: 'order-1',
          status: 'RECEIVED',
          broadcastedBranchIds: ['branch-1'],
        ),
      );

      await container
          .read(pharmacyOrderControllerProvider.notifier)
          .submit(
            prescriptionId: 'presc-1',
            fulfillmentType: 'PICKUP',
            pharmacyBranchId: 'branch-1',
          );

      verify(
        () => datasource.create(
          prescriptionId: 'presc-1',
          fulfillmentType: 'PICKUP',
          lat: null,
          lng: null,
          pharmacyBranchId: 'branch-1',
        ),
      ).called(1);
      expect(container.read(pharmacyOrderControllerProvider).hasError, isFalse);
    },
  );

  test(
    'submit surfaces PharmacyOrderLocationUnavailableException as AsyncError '
    'when the device location can\'t be read, without calling the datasource',
    () async {
      when(() => locationService.getCurrentPosition()).thenAnswer((_) async => null);

      await container
          .read(pharmacyOrderControllerProvider.notifier)
          .submit(prescriptionId: 'presc-1', fulfillmentType: 'PICKUP');

      final state = container.read(pharmacyOrderControllerProvider);
      expect(state.hasError, isTrue);
      expect(state.error, isA<PharmacyOrderLocationUnavailableException>());
      verifyNever(
        () => datasource.create(
          prescriptionId: any(named: 'prescriptionId'),
          fulfillmentType: any(named: 'fulfillmentType'),
          lat: any(named: 'lat'),
          lng: any(named: 'lng'),
        ),
      );
    },
  );

  test('submit surfaces a datasource failure as AsyncError', () async {
    when(() => locationService.getCurrentPosition()).thenAnswer((_) async => position);
    when(
      () => datasource.create(
        prescriptionId: any(named: 'prescriptionId'),
        fulfillmentType: any(named: 'fulfillmentType'),
        lat: any(named: 'lat'),
        lng: any(named: 'lng'),
        pharmacyBranchId: any(named: 'pharmacyBranchId'),
      ),
    ).thenThrow(Exception('network down'));

    await container
        .read(pharmacyOrderControllerProvider.notifier)
        .submit(prescriptionId: 'presc-1', fulfillmentType: 'PICKUP');

    expect(container.read(pharmacyOrderControllerProvider).hasError, isTrue);
  });
}

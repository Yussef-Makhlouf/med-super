import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:med_super/features/pharmacy_booking/data/datasources/remote/pharmacy_order_remote_datasource.dart';
import 'package:med_super/features/pharmacy_booking/domain/entities/pharmacy_order_detail.dart';
import 'package:med_super/features/pharmacy_booking/presentation/controllers/pharmacy_order_controller.dart';
import 'package:med_super/features/pharmacy_booking/presentation/controllers/pharmacy_order_list_providers.dart';

class _MockPharmacyOrderRemoteDatasource extends Mock
    implements PharmacyOrderRemoteDatasource {}

void main() {
  late _MockPharmacyOrderRemoteDatasource datasource;
  late ProviderContainer container;

  const order = PharmacyOrderDetail(
    id: 'order-1',
    status: 'ACCEPTED',
    fulfillmentType: 'DELIVERY',
    createdAt: '2026-08-31T10:00:00.000Z',
    updatedAt: '2026-08-31T10:05:00.000Z',
    pharmacyName: null,
    doctorName: null,
    quote: PharmacyOrderQuote(
      totalPrice: '225.00',
      currency: 'EGP',
      estimatedReadyMinutes: 45,
      note: null,
      quotedAt: '2026-08-31T10:05:00.000Z',
    ),
    patientNote: null,
    staffNote: null,
    prescriptionImages: [],
    rejection: null,
  );

  setUp(() {
    datasource = _MockPharmacyOrderRemoteDatasource();
    container = ProviderContainer(
      overrides: [
        pharmacyOrderRemoteDatasourceProvider.overrideWithValue(datasource),
      ],
    );
    addTearDown(container.dispose);
  });

  test('pharmacyOrdersProvider resolves to the datasource\'s list', () async {
    when(() => datasource.list()).thenAnswer((_) async => [order]);

    final result = await container.read(pharmacyOrdersProvider.future);

    expect(result, [order]);
  });

  test(
    'pharmacyOrderDetailProvider resolves to the datasource\'s detail for that id',
    () async {
      when(() => datasource.getDetail('order-1')).thenAnswer((_) async => order);

      final result = await container.read(
        pharmacyOrderDetailProvider('order-1').future,
      );

      expect(result, order);
    },
  );
}

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:med_super/core/constants/api_paths.dart';
import 'package:med_super/features/lab_booking/data/datasources/remote/lab_booking_remote_datasource.dart';
import 'package:med_super/features/lab_booking/domain/entities/lab_sort_option.dart';

class _MockDio extends Mock implements Dio {}

RequestOptions _reqOptions(String path) => RequestOptions(path: path);

Response<Map<String, dynamic>> _response(
  String path,
  Map<String, dynamic>? data,
) => Response<Map<String, dynamic>>(requestOptions: _reqOptions(path), data: data);

void main() {
  late _MockDio dio;
  late LabBookingRemoteDatasource datasource;

  setUp(() {
    dio = _MockDio();
    datasource = LabBookingRemoteDatasource(dio);
  });

  group('getLabPartners', () {
    test('maps the lab_partners list from the response', () async {
      when(
        () => dio.get<Map<String, dynamic>>(
          ApiPaths.labPartners,
          queryParameters: any(named: 'queryParameters'),
        ),
      ).thenAnswer(
        (_) async => _response(ApiPaths.labPartners, {
          'lab_partners': [
            {
              'id': 'p1',
              'name': 'Alpha',
              'distance_km': 1.0,
              'rating': 4.5,
              'rating_count': 10,
              'total_price': 300,
              'latitude': 1.0,
              'longitude': 1.0,
            },
          ],
        }),
      );

      final partners = await datasource.getLabPartners(testIds: const ['t1']);

      expect(partners, hasLength(1));
      expect(partners.single.name, 'Alpha');
    });

    test('sends joined testIds and the sort apiValue as query params', () async {
      when(
        () => dio.get<Map<String, dynamic>>(
          ApiPaths.labPartners,
          queryParameters: any(named: 'queryParameters'),
        ),
      ).thenAnswer((_) async => _response(ApiPaths.labPartners, const {}));

      await datasource.getLabPartners(
        testIds: const ['t1', 't2'],
        sort: LabSortOption.priceAsc,
      );

      final captured = verify(
        () => dio.get<Map<String, dynamic>>(
          ApiPaths.labPartners,
          queryParameters: captureAny(named: 'queryParameters'),
        ),
      ).captured.single as Map<String, dynamic>;

      expect(captured['test_ids'], 't1,t2');
      expect(captured['sort'], 'price_asc');
    });

    test('returns an empty list when lab_partners is missing', () async {
      when(
        () => dio.get<Map<String, dynamic>>(
          ApiPaths.labPartners,
          queryParameters: any(named: 'queryParameters'),
        ),
      ).thenAnswer((_) async => _response(ApiPaths.labPartners, null));

      final partners = await datasource.getLabPartners(testIds: const []);

      expect(partners, isEmpty);
    });
  });

  group('confirmBooking', () {
    test('posts labId/testIds and maps the confirmation response', () async {
      when(
        () => dio.post<Map<String, dynamic>>(
          ApiPaths.labBookings,
          data: any(named: 'data'),
        ),
      ).thenAnswer(
        (_) async => _response(ApiPaths.labBookings, {
          'booking_number': 'BK-1',
          'lab_name': 'Alpha',
          'lab_address': 'Addr',
          'date': '2026-01-01',
          'time': '10:00',
        }),
      );

      final confirmation = await datasource.confirmBooking(
        labId: 'lab1',
        testIds: const ['t1', 't2'],
      );

      expect(confirmation.bookingNumber, 'BK-1');
      final captured = verify(
        () => dio.post<Map<String, dynamic>>(
          ApiPaths.labBookings,
          data: captureAny(named: 'data'),
        ),
      ).captured.single as Map<String, dynamic>;
      expect(captured['lab_id'], 'lab1');
      expect(captured['test_ids'], const ['t1', 't2']);
    });

    test('propagates a DioException thrown by the client', () async {
      when(
        () => dio.post<Map<String, dynamic>>(
          ApiPaths.labBookings,
          data: any(named: 'data'),
        ),
      ).thenThrow(DioException(requestOptions: _reqOptions(ApiPaths.labBookings)));

      expect(
        () => datasource.confirmBooking(labId: 'lab1', testIds: const []),
        throwsA(isA<DioException>()),
      );
    });
  });
}

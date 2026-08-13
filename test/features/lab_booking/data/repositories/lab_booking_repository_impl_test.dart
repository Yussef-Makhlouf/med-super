import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:med_super/core/error/failure.dart';
import 'package:med_super/core/error/result.dart';
import 'package:med_super/features/lab_booking/data/datasources/remote/lab_booking_remote_datasource.dart';
import 'package:med_super/features/lab_booking/data/repositories/lab_booking_repository_impl.dart';
import 'package:med_super/features/lab_booking/domain/entities/lab_booking_confirmation.dart';
import 'package:med_super/features/lab_booking/domain/entities/lab_partner.dart';
import 'package:med_super/features/lab_booking/domain/entities/lab_partner_status.dart';
import 'package:med_super/features/lab_booking/domain/entities/lab_payment_method.dart';
import 'package:med_super/features/lab_booking/domain/entities/lab_request_image.dart';
import 'package:med_super/features/lab_booking/domain/entities/lab_service_type.dart';
import 'package:med_super/features/lab_booking/domain/entities/lab_sort_option.dart';

class _MockLabBookingRemoteDatasource extends Mock
    implements LabBookingRemoteDatasource {}

void main() {
  late _MockLabBookingRemoteDatasource remote;
  late LabBookingRepositoryImpl repository;

  setUpAll(() {
    registerFallbackValue(LabSortOption.nearest);
    registerFallbackValue(LabServiceType.branchVisit);
    registerFallbackValue(LabPaymentMethod.onlinePayment);
    registerFallbackValue(<LabRequestImage>[]);
  });

  setUp(() {
    remote = _MockLabBookingRemoteDatasource();
    repository = LabBookingRepositoryImpl(remote: remote);
  });

  const partner = LabPartner(
    id: 'p1',
    name: 'Alpha',
    address: '1 Tahrir St, Cairo',
    distanceKm: 1,
    rating: 4.5,
    ratingCount: 10,
    startingPrice: 300,
    latitude: 1,
    longitude: 1,
    status: LabPartnerStatus.openNow,
  );

  group('getLabPartners', () {
    test('returns Result.ok with the datasource value on success', () async {
      when(
        () => remote.getLabPartners(
          testIds: any(named: 'testIds'),
          sort: any(named: 'sort'),
        ),
      ).thenAnswer((_) async => [partner]);

      final result = await repository.getLabPartners(testIds: const ['t1']);

      expect(result.valueOrNull, [partner]);
    });

    test('maps a thrown exception to a Result.err', () async {
      when(
        () => remote.getLabPartners(
          testIds: any(named: 'testIds'),
          sort: any(named: 'sort'),
        ),
      ).thenThrow(Exception('boom'));

      final result = await repository.getLabPartners(testIds: const ['t1']);

      expect(result, isA<Err<List<LabPartner>>>());
      expect(result.failureOrNull, isA<UnknownFailure>());
    });

    test('forwards the sort option to the datasource', () async {
      when(
        () => remote.getLabPartners(
          testIds: any(named: 'testIds'),
          sort: any(named: 'sort'),
        ),
      ).thenAnswer((_) async => const []);

      await repository.getLabPartners(
        testIds: const ['t1'],
        sort: LabSortOption.ratingDesc,
      );

      verify(
        () => remote.getLabPartners(
          testIds: const ['t1'],
          sort: LabSortOption.ratingDesc,
        ),
      ).called(1);
    });
  });

  group('confirmBooking', () {
    const images = [LabRequestImage(id: 'img1', path: '/tmp/img1.jpg')];

    const confirmation = LabBookingConfirmation(
      bookingNumber: 'BK-1',
      labName: 'Alpha',
      labAddress: 'Addr',
      expectedResponseHours: 2,
    );

    test('returns Result.ok with the datasource value on success', () async {
      when(
        () => remote.confirmBooking(
          labId: any(named: 'labId'),
          images: any(named: 'images'),
          serviceType: any(named: 'serviceType'),
          paymentMethod: any(named: 'paymentMethod'),
        ),
      ).thenAnswer((_) async => confirmation);

      final result = await repository.confirmBooking(
        labId: 'lab1',
        images: images,
        serviceType: LabServiceType.branchVisit,
        paymentMethod: LabPaymentMethod.onlinePayment,
      );

      expect(result.valueOrNull, confirmation);
    });

    test(
      'maps a DioException conflict-shaped ApiException-less error to unknown',
      () async {
        when(
          () => remote.confirmBooking(
            labId: any(named: 'labId'),
            images: any(named: 'images'),
            serviceType: any(named: 'serviceType'),
            paymentMethod: any(named: 'paymentMethod'),
          ),
        ).thenThrow(
          DioException(
            requestOptions: RequestOptions(path: '/v1/lab-bookings'),
            type: DioExceptionType.connectionTimeout,
          ),
        );

        final result = await repository.confirmBooking(
          labId: 'lab1',
          images: images,
          serviceType: LabServiceType.branchVisit,
          paymentMethod: LabPaymentMethod.onlinePayment,
        );

        expect(result.failureOrNull, const Failure.network());
      },
    );
  });
}

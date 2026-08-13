import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:med_super/core/error/failure.dart';
import 'package:med_super/core/error/result.dart';
import 'package:med_super/features/lab_booking/domain/entities/lab_booking_confirmation.dart';
import 'package:med_super/features/lab_booking/domain/entities/lab_payment_method.dart';
import 'package:med_super/features/lab_booking/domain/entities/lab_request_image.dart';
import 'package:med_super/features/lab_booking/domain/entities/lab_service_type.dart';
import 'package:med_super/features/lab_booking/domain/repositories/lab_booking_repository.dart';
import 'package:med_super/features/lab_booking/domain/usecases/confirm_lab_booking_usecase.dart';

class _MockLabBookingRepository extends Mock implements LabBookingRepository {}

void main() {
  late _MockLabBookingRepository repository;
  late ConfirmLabBookingUseCase useCase;

  setUpAll(() {
    registerFallbackValue(LabServiceType.branchVisit);
    registerFallbackValue(LabPaymentMethod.onlinePayment);
  });

  setUp(() {
    repository = _MockLabBookingRepository();
    useCase = ConfirmLabBookingUseCase(repository);
  });

  const images = [LabRequestImage(id: 'img1', path: '/tmp/img1.jpg')];

  const confirmation = LabBookingConfirmation(
    bookingNumber: 'BK-1',
    labName: 'Alpha',
    labAddress: 'Addr',
    expectedResponseHours: 2,
  );

  test('delegates to repository.confirmBooking with given args', () async {
    when(
      () => repository.confirmBooking(
        labId: 'lab1',
        images: images,
        serviceType: LabServiceType.branchVisit,
        paymentMethod: LabPaymentMethod.onlinePayment,
      ),
    ).thenAnswer((_) async => const Result.ok(confirmation));

    final result = await useCase.call(
      labId: 'lab1',
      images: images,
      serviceType: LabServiceType.branchVisit,
      paymentMethod: LabPaymentMethod.onlinePayment,
    );

    expect(result.valueOrNull, confirmation);
    verify(
      () => repository.confirmBooking(
        labId: 'lab1',
        images: images,
        serviceType: LabServiceType.branchVisit,
        paymentMethod: LabPaymentMethod.onlinePayment,
      ),
    ).called(1);
  });

  test('forwards optional schedule/address args for home collection', () async {
    final scheduledDate = DateTime(2026, 8, 20);
    when(
      () => repository.confirmBooking(
        labId: any(named: 'labId'),
        images: any(named: 'images'),
        serviceType: any(named: 'serviceType'),
        paymentMethod: any(named: 'paymentMethod'),
        scheduledDate: any(named: 'scheduledDate'),
        scheduledTime: any(named: 'scheduledTime'),
        address: any(named: 'address'),
      ),
    ).thenAnswer((_) async => const Result.ok(confirmation));

    await useCase.call(
      labId: 'lab1',
      images: images,
      serviceType: LabServiceType.homeCollection,
      paymentMethod: LabPaymentMethod.payAtService,
      scheduledDate: scheduledDate,
      scheduledTime: '09:00',
      address: '123 Main St',
    );

    verify(
      () => repository.confirmBooking(
        labId: 'lab1',
        images: images,
        serviceType: LabServiceType.homeCollection,
        paymentMethod: LabPaymentMethod.payAtService,
        scheduledDate: scheduledDate,
        scheduledTime: '09:00',
        address: '123 Main St',
      ),
    ).called(1);
  });

  test('propagates a failure result unchanged', () async {
    const failure = Failure.conflict('SLOT_TAKEN');
    when(
      () => repository.confirmBooking(
        labId: any(named: 'labId'),
        images: any(named: 'images'),
        serviceType: any(named: 'serviceType'),
        paymentMethod: any(named: 'paymentMethod'),
      ),
    ).thenAnswer((_) async => const Result.err(failure));

    final result = await useCase.call(
      labId: 'lab1',
      images: images,
      serviceType: LabServiceType.branchVisit,
      paymentMethod: LabPaymentMethod.onlinePayment,
    );

    expect(result.failureOrNull, failure);
  });
}

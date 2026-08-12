import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:med_super/core/error/failure.dart';
import 'package:med_super/core/error/result.dart';
import 'package:med_super/features/lab_booking/domain/entities/lab_booking_confirmation.dart';
import 'package:med_super/features/lab_booking/domain/repositories/lab_booking_repository.dart';
import 'package:med_super/features/lab_booking/domain/usecases/confirm_lab_booking_usecase.dart';

class _MockLabBookingRepository extends Mock implements LabBookingRepository {}

void main() {
  late _MockLabBookingRepository repository;
  late ConfirmLabBookingUseCase useCase;

  setUp(() {
    repository = _MockLabBookingRepository();
    useCase = ConfirmLabBookingUseCase(repository);
  });

  final confirmation = LabBookingConfirmation(
    bookingNumber: 'BK-1',
    labName: 'Alpha',
    labAddress: 'Addr',
    date: DateTime(2026, 1, 1),
    time: '10:00',
  );

  test('delegates to repository.confirmBooking with given args', () async {
    when(
      () => repository.confirmBooking(labId: 'lab1', testIds: ['t1']),
    ).thenAnswer((_) async => Result.ok(confirmation));

    final result = await useCase.call(labId: 'lab1', testIds: const ['t1']);

    expect(result.valueOrNull, confirmation);
    verify(
      () => repository.confirmBooking(labId: 'lab1', testIds: ['t1']),
    ).called(1);
  });

  test('propagates a failure result unchanged', () async {
    const failure = Failure.conflict('SLOT_TAKEN');
    when(
      () => repository.confirmBooking(
        labId: any(named: 'labId'),
        testIds: any(named: 'testIds'),
      ),
    ).thenAnswer((_) async => const Result.err(failure));

    final result = await useCase.call(labId: 'lab1', testIds: const ['t1']);

    expect(result.failureOrNull, failure);
  });
}

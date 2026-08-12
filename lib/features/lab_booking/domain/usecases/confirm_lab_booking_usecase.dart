import 'package:med_super/core/error/result.dart';
import 'package:med_super/features/lab_booking/domain/entities/lab_booking_confirmation.dart';
import 'package:med_super/features/lab_booking/domain/repositories/lab_booking_repository.dart';

class ConfirmLabBookingUseCase {
  const ConfirmLabBookingUseCase(this._repository);

  final LabBookingRepository _repository;

  Future<Result<LabBookingConfirmation>> call({
    required String labId,
    required List<String> testIds,
    DateTime? scheduledDate,
    String? scheduledTime,
    String? paymentMethod,
  }) => _repository.confirmBooking(
    labId: labId,
    testIds: testIds,
    scheduledDate: scheduledDate,
    scheduledTime: scheduledTime,
    paymentMethod: paymentMethod,
  );
}

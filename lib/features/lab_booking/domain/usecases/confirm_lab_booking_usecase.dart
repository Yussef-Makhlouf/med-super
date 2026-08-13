import 'package:med_super/core/error/result.dart';
import 'package:med_super/features/lab_booking/domain/entities/lab_booking_confirmation.dart';
import 'package:med_super/features/lab_booking/domain/entities/lab_payment_method.dart';
import 'package:med_super/features/lab_booking/domain/entities/lab_request_image.dart';
import 'package:med_super/features/lab_booking/domain/entities/lab_service_type.dart';
import 'package:med_super/features/lab_booking/domain/repositories/lab_booking_repository.dart';

class ConfirmLabBookingUseCase {
  const ConfirmLabBookingUseCase(this._repository);

  final LabBookingRepository _repository;

  Future<Result<LabBookingConfirmation>> call({
    required String labId,
    required List<LabRequestImage> images,
    required LabServiceType serviceType,
    required LabPaymentMethod paymentMethod,
    DateTime? scheduledDate,
    String? scheduledTime,
    String? address,
  }) => _repository.confirmBooking(
    labId: labId,
    images: images,
    serviceType: serviceType,
    paymentMethod: paymentMethod,
    scheduledDate: scheduledDate,
    scheduledTime: scheduledTime,
    address: address,
  );
}

import 'package:med_super/core/error/result.dart';
import 'package:med_super/features/lab_booking/domain/entities/lab_booking_confirmation.dart';
import 'package:med_super/features/lab_booking/domain/entities/lab_partner.dart';
import 'package:med_super/features/lab_booking/domain/entities/lab_payment_method.dart';
import 'package:med_super/features/lab_booking/domain/entities/lab_request_image.dart';
import 'package:med_super/features/lab_booking/domain/entities/lab_service_type.dart';
import 'package:med_super/features/lab_booking/domain/entities/lab_sort_option.dart';

abstract class LabBookingRepository {
  Future<Result<List<LabPartner>>> getLabPartners({
    required List<String> testIds,
    LabSortOption sort = LabSortOption.nearest,
  });

  Future<Result<LabBookingConfirmation>> confirmBooking({
    required String labId,
    required List<LabRequestImage> images,
    required LabServiceType serviceType,
    required LabPaymentMethod paymentMethod,
    DateTime? scheduledDate,
    String? scheduledTime,
    String? address,
  });
}

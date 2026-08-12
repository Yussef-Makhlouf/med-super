import 'package:med_super/core/error/result.dart';
import 'package:med_super/features/lab_booking/domain/entities/lab_booking_confirmation.dart';
import 'package:med_super/features/lab_booking/domain/entities/lab_partner.dart';
import 'package:med_super/features/lab_booking/domain/entities/lab_sort_option.dart';

abstract class LabBookingRepository {
  Future<Result<List<LabPartner>>> getLabPartners({
    required List<String> testIds,
    LabSortOption sort = LabSortOption.nearest,
  });

  Future<Result<LabBookingConfirmation>> confirmBooking({
    required String labId,
    required List<String> testIds,
    DateTime? scheduledDate,
    String? scheduledTime,
    String? paymentMethod,
  });
}

import 'package:med_super/core/error/dio_failure_mapper.dart';
import 'package:med_super/core/error/result.dart';
import 'package:med_super/features/lab_booking/data/datasources/remote/lab_booking_remote_datasource.dart';
import 'package:med_super/features/lab_booking/domain/entities/lab_booking_confirmation.dart';
import 'package:med_super/features/lab_booking/domain/entities/lab_partner.dart';
import 'package:med_super/features/lab_booking/domain/entities/lab_payment_method.dart';
import 'package:med_super/features/lab_booking/domain/entities/lab_request_image.dart';
import 'package:med_super/features/lab_booking/domain/entities/lab_service_type.dart';
import 'package:med_super/features/lab_booking/domain/entities/lab_sort_option.dart';
import 'package:med_super/features/lab_booking/domain/repositories/lab_booking_repository.dart';

class LabBookingRepositoryImpl implements LabBookingRepository {
  LabBookingRepositoryImpl({required LabBookingRemoteDatasource remote})
    : _remote = remote;

  final LabBookingRemoteDatasource _remote;

  @override
  Future<Result<List<LabPartner>>> getLabPartners({
    required List<String> testIds,
    LabSortOption sort = LabSortOption.nearest,
  }) async {
    try {
      final result = await _remote.getLabPartners(testIds: testIds, sort: sort);
      return Result.ok(result);
    } catch (e, st) {
      return Result.err(mapDioToFailure(e, st));
    }
  }

  @override
  Future<Result<LabBookingConfirmation>> confirmBooking({
    required String labId,
    required List<LabRequestImage> images,
    required LabServiceType serviceType,
    required LabPaymentMethod paymentMethod,
    DateTime? scheduledDate,
    String? scheduledTime,
    String? address,
  }) async {
    try {
      final result = await _remote.confirmBooking(
        labId: labId,
        images: images,
        serviceType: serviceType,
        paymentMethod: paymentMethod,
        scheduledDate: scheduledDate,
        scheduledTime: scheduledTime,
        address: address,
      );
      return Result.ok(result);
    } catch (e, st) {
      return Result.err(mapDioToFailure(e, st));
    }
  }
}

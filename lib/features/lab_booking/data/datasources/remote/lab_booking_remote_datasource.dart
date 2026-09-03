import 'package:dio/dio.dart';
import 'package:med_super/core/constants/api_paths.dart';
import 'package:med_super/features/lab_booking/data/models/lab_booking_confirmation_dto.dart';
import 'package:med_super/features/lab_booking/data/models/lab_partner_dto.dart';
import 'package:med_super/features/lab_booking/domain/entities/lab_booking_confirmation.dart';
import 'package:med_super/features/lab_booking/domain/entities/lab_partner.dart';
import 'package:med_super/features/lab_booking/domain/entities/lab_payment_method.dart';
import 'package:med_super/features/lab_booking/domain/entities/lab_request_image.dart';
import 'package:med_super/features/lab_booking/domain/entities/lab_service_type.dart';
import 'package:med_super/features/lab_booking/domain/entities/lab_sort_option.dart';

class LabBookingRemoteDatasource {
  LabBookingRemoteDatasource(this._dio);

  final Dio _dio;

  Future<List<LabPartner>> getLabPartners({
    required List<String> testIds,
    LabSortOption sort = LabSortOption.nearest,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      ApiPaths.labPartners,
      queryParameters: {'test_ids': testIds.join(','), 'sort': sort.apiValue},
    );
    final list = (response.data?['lab_partners'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(LabPartnerDto.fromJson)
        .map((dto) => dto.toEntity())
        .toList();
    return list;
  }

  Future<LabBookingConfirmation> confirmBooking({
    required String labId,
    required List<LabRequestImage> images,
    required LabServiceType serviceType,
    required LabPaymentMethod paymentMethod,
    DateTime? scheduledDate,
    String? scheduledTime,
    String? address,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      ApiPaths.labBookings,
      data: {
        'lab_id': labId,
        'images': images.map((image) => image.path).toList(),
        'service_type': serviceType.apiValue,
        'payment_method': paymentMethod.apiValue,
        if (scheduledDate != null)
          'scheduled_date': scheduledDate.toIso8601String(),
        if (scheduledTime != null) 'scheduled_time': scheduledTime,
        if (address != null) 'address': address,
      },
    );
    return LabBookingConfirmationDto.fromJson(
      response.data ?? const {},
    ).toEntity();
  }
}

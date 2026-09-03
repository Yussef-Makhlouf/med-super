import 'package:dio/dio.dart';
import 'package:med_super/core/constants/api_paths.dart';
import 'package:med_super/features/appointments/data/models/appointment_hold_dto.dart';
import 'package:med_super/features/appointments/data/models/appointment_summary_dto.dart';
import 'package:med_super/features/appointments/data/models/cancelled_appointment_dto.dart';
import 'package:med_super/features/appointments/data/models/confirmed_appointment_dto.dart';

/// One page of `GET /v1/appointments` — `nextCursor` is null once there's
/// nothing more to load.
class AppointmentSummaryDtoPage {
  const AppointmentSummaryDtoPage({required this.items, required this.nextCursor});

  final List<AppointmentSummaryDto> items;
  final String? nextCursor;
}

/// Real Phase 4 booking-loop contract (File 10 §2.3 / File 12 Part 35).
/// `Idempotency-Key` on the mutating calls is attached automatically by
/// `IdempotencyKeyInterceptor` (every path here contains `/appointments`) —
/// nothing to do at this layer.
class AppointmentsRemoteDatasource {
  AppointmentsRemoteDatasource(this._dio);

  final Dio _dio;

  Future<AppointmentHoldDto> createHold({
    required String doctorClinicAffiliationId,
    required String slotId,
    required String patientId,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      ApiPaths.appointmentHold,
      data: {
        'doctorClinicAffiliationId': doctorClinicAffiliationId,
        'slotId': slotId,
        'patientId': patientId,
      },
    );
    return AppointmentHoldDto.fromJson(response.data!);
  }

  Future<ConfirmedAppointmentDto> confirmHold(String holdId) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '${ApiPaths.appointments}/$holdId/confirm',
      // Pay-at-clinic only — Phase 4 doesn't have a Payments module to call
      // for ONLINE yet (File 12 Part 35.4).
      data: {'paymentMethod': 'PAY_AT_CLINIC'},
    );
    return ConfirmedAppointmentDto.fromJson(response.data!);
  }

  Future<CancelledAppointmentDto> cancel({
    required String appointmentId,
    required String reason,
    String? note,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '${ApiPaths.appointments}/$appointmentId/cancel',
      data: {'reason': reason, if (note != null) 'note': note},
    );
    return CancelledAppointmentDto.fromJson(response.data!);
  }

  Future<AppointmentHoldDto> reschedule({
    required String appointmentId,
    required String newSlotId,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '${ApiPaths.appointments}/$appointmentId/reschedule',
      data: {'newSlotId': newSlotId},
    );
    return AppointmentHoldDto.fromJson(response.data!);
  }

  /// `GET /v1/appointments` (`ListAppointmentsQueryDto`) — cursor-paginated,
  /// `limit` default 20/max 50 on the backend.
  Future<AppointmentSummaryDtoPage> listMine({
    String? status,
    String? cursor,
    int? limit,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      ApiPaths.appointments,
      queryParameters: {
        if (status != null) 'status': status,
        if (cursor != null) 'cursor': cursor,
        if (limit != null) 'limit': limit,
      },
    );
    final data = response.data ?? const <String, dynamic>{};
    final items = (data['items'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(AppointmentSummaryDto.fromJson)
        .toList();
    return AppointmentSummaryDtoPage(
      items: items,
      nextCursor: data['nextCursor'] as String?,
    );
  }

  Future<AppointmentSummaryDto> getById(String appointmentId) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '${ApiPaths.appointments}/$appointmentId',
    );
    return AppointmentSummaryDto.fromJson(response.data!);
  }
}

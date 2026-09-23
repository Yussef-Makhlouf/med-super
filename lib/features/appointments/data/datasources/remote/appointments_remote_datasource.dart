import 'package:dio/dio.dart';
import 'package:med_super/core/constants/api_paths.dart';
import 'package:med_super/core/payments/domain/entities/payment_customer_info.dart';
import 'package:med_super/features/appointments/data/models/appointment_hold_dto.dart';
import 'package:med_super/features/appointments/data/models/appointment_summary_dto.dart';
import 'package:med_super/features/appointments/data/models/cancelled_appointment_dto.dart';
import 'package:med_super/features/appointments/data/models/confirmed_appointment_dto.dart';
import 'package:med_super/features/appointments/data/models/online_payment_initiation_dto.dart';
import 'package:med_super/features/appointments/domain/entities/appointment_payment_method.dart';

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

  /// The synchronous half of paying for a hold: `PAY_AT_CLINIC` and
  /// `INTERNAL_WALLET` both create the `CONFIRMED` appointment in this one
  /// call (File 12 Part 50.4). `ONLINE` is rejected here by the backend on
  /// purpose — the async methods go through [initiateOnlinePayment].
  ///
  /// [paymentAmount] is `INTERNAL_WALLET` only — a decimal string such as
  /// `"50.00"`. Omit it to pay the full fee. Sending it with `PAY_AT_CLINIC`
  /// is `422 PAYMENT_AMOUNT_NOT_SUPPORTED`.
  Future<ConfirmedAppointmentDto> confirmHold(
    String holdId, {
    required AppointmentPaymentMethod paymentMethod,
    String? paymentAmount,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '${ApiPaths.appointments}/$holdId/confirm',
      data: {
        'paymentMethod': paymentMethod.wireValue,
        if (paymentAmount != null) 'paymentAmount': paymentAmount,
      },
    );
    return ConfirmedAppointmentDto.fromJson(response.data!);
  }

  /// `POST /v1/appointments/{holdId}/payments` (File 12 Part 50.1) — starts
  /// an async gateway payment. Returns the Fawry reference the patient pays
  /// against; the appointment itself is confirmed later by the webhook.
  ///
  /// [paymentAmount] is optional (`"50.00"`). Omit it to pay the full fee.
  /// The response does not echo the amount — the caller already knows it.
  Future<OnlinePaymentInitiationDto> initiateOnlinePayment(
    String holdId, {
    required AppointmentPaymentMethod method,
    required PaymentCustomerInfo customer,
    String? paymentAmount,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '${ApiPaths.appointments}/$holdId/payments',
      data: {
        'method': method.wireValue,
        'customer': customer.toJson(),
        if (paymentAmount != null) 'paymentAmount': paymentAmount,
      },
    );
    return OnlinePaymentInitiationDto.fromJson(response.data!);
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

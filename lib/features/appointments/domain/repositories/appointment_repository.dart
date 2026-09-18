import 'package:med_super/core/error/result.dart';
import 'package:med_super/core/payments/domain/entities/payment_customer_info.dart';
import 'package:med_super/features/appointments/domain/entities/appointment_hold.dart';
import 'package:med_super/features/appointments/domain/entities/appointment_payment_method.dart';
import 'package:med_super/features/appointments/domain/entities/appointment_summary.dart';
import 'package:med_super/features/appointments/domain/entities/confirmed_appointment.dart';
import 'package:med_super/features/appointments/domain/entities/online_payment_initiation.dart';

abstract interface class AppointmentRepository {
  Future<Result<AppointmentHold>> createHold({
    required String doctorClinicAffiliationId,
    required String slotId,
    required String patientId,
  });

  Future<Result<ConfirmedAppointment>> confirmHold(
    String holdId, {
    required AppointmentPaymentMethod paymentMethod,
  });

  Future<Result<OnlinePaymentInitiation>> initiateOnlinePayment(
    String holdId, {
    required AppointmentPaymentMethod method,
    required PaymentCustomerInfo customer,
  });

  Future<Result<CancelledAppointment>> cancel({
    required String appointmentId,
    required String reason,
    String? note,
  });

  Future<Result<AppointmentHold>> reschedule({
    required String appointmentId,
    required String newSlotId,
  });

  Future<Result<AppointmentSummaryPage>> listMine({
    String? status,
    String? cursor,
    int? limit,
  });

  Future<Result<AppointmentSummary>> getById(String appointmentId);
}

/// One page of `GET /v1/appointments` — `nextCursor` is null once there's
/// nothing more to load, mirroring `PharmacyBranchSearchPage`'s shape.
class AppointmentSummaryPage {
  const AppointmentSummaryPage({required this.items, required this.nextCursor});

  final List<AppointmentSummary> items;
  final String? nextCursor;
}

/// Result of `POST /v1/appointments/{id}/cancel` (File 12 Part 35.7 —
/// `feeApplied`/`refundAmount` are always `0` in this phase, see that
/// decision for why).
class CancelledAppointment {
  const CancelledAppointment({
    required this.status,
    required this.refundAmount,
    required this.feeApplied,
  });

  final String status;
  final num refundAmount;
  final num feeApplied;
}

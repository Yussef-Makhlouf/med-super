import 'package:med_super/features/appointments/domain/entities/appointment_summary.dart';

/// `{ appointmentId, status, slotId, startAt, endAt,
/// doctorClinicAffiliationId, cancelledReason, rescheduledFromAppointmentId,
/// doctorId, doctorName, clinicBranchId, clinicName, clinicAddressLine1,
/// clinicCity, clinicPhone }` — File 12 Part 35.17's response shape for
/// `GET /v1/appointments` (list, one per item) and
/// `GET /v1/appointments/{id}` (detail, the object itself), extended with
/// the doctor/clinic display fields (backend
/// `feature/appointment-summary-doctor-clinic-details`).
class AppointmentSummaryDto {
  const AppointmentSummaryDto({
    required this.appointmentId,
    required this.status,
    required this.slotId,
    required this.startAt,
    required this.endAt,
    required this.doctorClinicAffiliationId,
    required this.doctorId,
    required this.doctorName,
    required this.clinicBranchId,
    required this.clinicName,
    required this.clinicAddressLine1,
    required this.clinicCity,
    required this.clinicPhone,
    this.cancelledReason,
    this.rescheduledFromAppointmentId,
    this.visitStatus = 'WAITING',
    this.payment,
  });

  final String appointmentId;
  final String status;
  final String slotId;
  final DateTime startAt;
  final DateTime endAt;
  final String doctorClinicAffiliationId;
  final String doctorId;
  final String doctorName;
  final String clinicBranchId;
  final String clinicName;
  final String clinicAddressLine1;
  final String clinicCity;
  final String clinicPhone;
  final String? cancelledReason;
  final String? rescheduledFromAppointmentId;
  final String visitStatus;
  final AppointmentPayment? payment;

  /// `{ method, currency, fullAmount, paidAmount, remainingBalance }` with
  /// decimal-string amounts. Anything malformed is dropped (`null`) rather
  /// than shown as a wrong number.
  static AppointmentPayment? _paymentFromJson(Object? raw) {
    if (raw is! Map<String, dynamic>) return null;
    num? amount(String key) => switch (raw[key]) {
      final String s => num.tryParse(s),
      final num n => n,
      _ => null,
    };
    final full = amount('fullAmount');
    final paid = amount('paidAmount');
    final remaining = amount('remainingBalance');
    final method = raw['method'] as String?;
    if (full == null || paid == null || remaining == null || method == null) {
      return null;
    }
    return AppointmentPayment(
      method: method,
      currency: raw['currency'] as String? ?? 'EGP',
      fullAmount: full,
      paidAmount: paid,
      remainingBalance: remaining,
    );
  }

  factory AppointmentSummaryDto.fromJson(Map<String, dynamic> json) =>
      AppointmentSummaryDto(
        appointmentId: json['appointmentId'] as String,
        status: json['status'] as String,
        slotId: json['slotId'] as String,
        startAt: DateTime.parse(json['startAt'] as String).toUtc(),
        endAt: DateTime.parse(json['endAt'] as String).toUtc(),
        doctorClinicAffiliationId: json['doctorClinicAffiliationId'] as String,
        doctorId: json['doctorId'] as String? ?? '',
        doctorName: json['doctorName'] as String? ?? '',
        clinicBranchId: json['clinicBranchId'] as String? ?? '',
        clinicName: json['clinicName'] as String? ?? '',
        clinicAddressLine1: json['clinicAddressLine1'] as String? ?? '',
        clinicCity: json['clinicCity'] as String? ?? '',
        clinicPhone: json['clinicPhone'] as String? ?? '',
        cancelledReason: json['cancelledReason'] as String?,
        rescheduledFromAppointmentId:
            json['rescheduledFromAppointmentId'] as String?,
        visitStatus: json['visitStatus'] as String? ?? 'WAITING',
        payment: _paymentFromJson(json['payment']),
      );

  AppointmentSummary toEntity() => AppointmentSummary(
    appointmentId: appointmentId,
    status: status,
    slotId: slotId,
    startAt: startAt,
    endAt: endAt,
    doctorClinicAffiliationId: doctorClinicAffiliationId,
    doctorId: doctorId,
    doctorName: doctorName,
    clinicBranchId: clinicBranchId,
    clinicName: clinicName,
    clinicAddressLine1: clinicAddressLine1,
    clinicCity: clinicCity,
    clinicPhone: clinicPhone,
    cancelledReason: cancelledReason,
    rescheduledFromAppointmentId: rescheduledFromAppointmentId,
    visitStatus: visitStatus,
    payment: payment,
  );
}

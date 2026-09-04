import '../../domain/entities/doctor_appointment.dart';

/// Wire model for `GET /v1/doctors/me/appointments[/{id}]`
/// (backend `DoctorAppointmentSummary`, File 12 Part 49.7).
///
/// Fields are **camelCase** — that is the backend's own API-layer convention
/// (File 12 Part 09); the old snake_case mock DTO here matched nothing real.
/// The `{success, data, ...}` envelope is already stripped by
/// `EnvelopeInterceptor`, so `json` is the `data` payload itself.
class DoctorAppointmentDto {
  const DoctorAppointmentDto({
    required this.appointmentId,
    required this.status,
    required this.slotId,
    required this.startAt,
    required this.endAt,
    required this.doctorClinicAffiliationId,
    required this.clinicId,
    required this.clinicName,
    required this.clinicBranchId,
    required this.clinicBranchPhone,
    required this.clinicAddressLine1,
    required this.clinicCity,
    required this.ianaTimezone,
    required this.patientId,
    required this.patientName,
    required this.patientPhone,
    required this.createdAt,
    this.cancelledReason,
    this.rescheduledFromAppointmentId,
  });

  factory DoctorAppointmentDto.fromJson(Map<String, dynamic> json) {
    return DoctorAppointmentDto(
      appointmentId: json['appointmentId'] as String,
      status: json['status'] as String? ?? '',
      slotId: json['slotId'] as String? ?? '',
      startAt: DateTime.parse(json['startAt'] as String),
      endAt: DateTime.parse(json['endAt'] as String),
      doctorClinicAffiliationId:
          json['doctorClinicAffiliationId'] as String? ?? '',
      clinicId: json['clinicId'] as String? ?? '',
      clinicName: json['clinicName'] as String? ?? '',
      clinicBranchId: json['clinicBranchId'] as String? ?? '',
      clinicBranchPhone: json['clinicBranchPhone'] as String? ?? '',
      clinicAddressLine1: json['clinicAddressLine1'] as String? ?? '',
      clinicCity: json['clinicCity'] as String? ?? '',
      ianaTimezone: json['ianaTimezone'] as String? ?? 'UTC',
      patientId: json['patientId'] as String? ?? '',
      patientName: json['patientName'] as String? ?? '',
      patientPhone: json['patientPhone'] as String? ?? '',
      createdAt: DateTime.parse(
        json['createdAt'] as String? ?? DateTime.now().toIso8601String(),
      ),
      cancelledReason: json['cancelledReason'] as String?,
      rescheduledFromAppointmentId:
          json['rescheduledFromAppointmentId'] as String?,
    );
  }

  final String appointmentId;
  final String status;
  final String slotId;
  final DateTime startAt;
  final DateTime endAt;
  final String doctorClinicAffiliationId;
  final String clinicId;
  final String clinicName;
  final String clinicBranchId;
  final String clinicBranchPhone;
  final String clinicAddressLine1;
  final String clinicCity;
  final String ianaTimezone;
  final String patientId;
  final String patientName;
  final String patientPhone;
  final DateTime createdAt;
  final String? cancelledReason;
  final String? rescheduledFromAppointmentId;

  DoctorAppointment toEntity() => DoctorAppointment(
    appointmentId: appointmentId,
    status: DoctorAppointmentStatusX.fromWire(status),
    slotId: slotId,
    startAt: startAt,
    endAt: endAt,
    doctorClinicAffiliationId: doctorClinicAffiliationId,
    clinicId: clinicId,
    clinicName: clinicName,
    clinicBranchId: clinicBranchId,
    clinicBranchPhone: clinicBranchPhone,
    clinicAddressLine1: clinicAddressLine1,
    clinicCity: clinicCity,
    ianaTimezone: ianaTimezone,
    patientId: patientId,
    patientName: patientName,
    patientPhone: patientPhone,
    createdAt: createdAt,
    cancelledReason: cancelledReason,
    rescheduledFromAppointmentId: rescheduledFromAppointmentId,
  );
}

/// `{ items: [...], nextCursor: string | null }` — the cursor-paginated
/// envelope both doctor and patient appointment lists use.
class DoctorAppointmentPageDto {
  const DoctorAppointmentPageDto({required this.items, this.nextCursor});

  factory DoctorAppointmentPageDto.fromJson(Map<String, dynamic> json) {
    final items = (json['items'] as List<dynamic>? ?? const [])
        .map((e) => DoctorAppointmentDto.fromJson(e as Map<String, dynamic>))
        .toList();
    return DoctorAppointmentPageDto(
      items: items,
      nextCursor: json['nextCursor'] as String?,
    );
  }

  final List<DoctorAppointmentDto> items;
  final String? nextCursor;

  DoctorAppointmentPage toEntity() => DoctorAppointmentPage(
    items: items.map((dto) => dto.toEntity()).toList(),
    nextCursor: nextCursor,
  );
}

/// `POST /v1/doctors/me/appointments/{id}/cancel` response.
class CancelAppointmentResultDto {
  const CancelAppointmentResultDto({
    required this.status,
    required this.refundAmount,
    required this.feeApplied,
  });

  factory CancelAppointmentResultDto.fromJson(Map<String, dynamic> json) =>
      CancelAppointmentResultDto(
        status: json['status'] as String? ?? 'CANCELLED',
        refundAmount: (json['refundAmount'] as num?)?.toDouble() ?? 0,
        feeApplied: (json['feeApplied'] as num?)?.toDouble() ?? 0,
      );

  final String status;
  final double refundAmount;

  /// Always `0` for a provider-initiated cancellation — the fee is waived
  /// entirely (File 11 line 475). Surfaced so the UI can say so out loud.
  final double feeApplied;
}

/// `POST /v1/doctors/me/appointments/{id}/reschedule` response.
///
/// A provider reschedule completes in one transaction, so this always comes
/// back `CONFIRMED` with the **new** appointment id — unlike the patient
/// route, which returns an unconfirmed `HELD` hold the patient must confirm
/// (File 12 Part 49.9).
class RescheduleAppointmentResultDto {
  const RescheduleAppointmentResultDto({
    required this.status,
    required this.appointmentId,
    required this.slotId,
    required this.previousAppointmentId,
  });

  factory RescheduleAppointmentResultDto.fromJson(Map<String, dynamic> json) =>
      RescheduleAppointmentResultDto(
        status: json['status'] as String? ?? '',
        appointmentId: json['appointmentId'] as String? ?? '',
        slotId: json['slotId'] as String? ?? '',
        previousAppointmentId: json['previousAppointmentId'] as String? ?? '',
      );

  final String status;
  final String appointmentId;
  final String slotId;
  final String previousAppointmentId;
}

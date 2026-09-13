import 'package:med_super/core/error/result.dart';
import '../entities/doctor_account_profile.dart';
import '../entities/doctor_appointment.dart';
import '../entities/doctor_clinic.dart';
import '../entities/doctor_schedule_template.dart';

/// Result of a provider-initiated cancellation. `feeApplied` is always `0`
/// for this path — the clinic cancelled, so the patient is refunded in full.
class CancelAppointmentOutcome {
  const CancelAppointmentOutcome({
    required this.refundAmount,
    required this.feeApplied,
  });

  final double refundAmount;
  final double feeApplied;
}

/// Result of a provider-initiated reschedule. The move is already complete —
/// [newAppointmentId] is a fresh `CONFIRMED` appointment, and the previous
/// one is now `RESCHEDULED` (File 12 Part 49.9).
class RescheduleAppointmentOutcome {
  const RescheduleAppointmentOutcome({
    required this.newAppointmentId,
    required this.slotId,
    required this.previousAppointmentId,
  });

  final String newAppointmentId;
  final String slotId;
  final String previousAppointmentId;
}

abstract class ProviderDashboardRepository {
  // --- Profile ---

  Future<Result<DoctorAccountProfile>> getDoctorAccount();

  Future<Result<DoctorAccountProfile>> updateDoctorAccount({
    String? bio,
    String? degree,
    int? yearsOfExperience,
    String? photoDataUri,
  });

  // --- Clinics and branches ---

  Future<Result<List<DoctorClinic>>> getMyClinics();

  Future<Result<DoctorClinic>> createMyClinicBranch({
    required String clinicId,
    required String phone,
    required String ianaTimezone,
    required String addressLine1,
    required String addressCity,
    required String regionCode,
    required String countryCode,
    required double consultFee,
  });

  Future<Result<DoctorClinic>> updateMyClinicBranch({
    required String branchId,
    String? phone,
    String? ianaTimezone,
    String? addressLine1,
    String? addressCity,
  });

  Future<Result<DoctorClinic>> setMyAffiliationActive({
    required String affiliationId,
    required bool active,
    double? consultFee,
  });

  Future<Result<void>> deleteMyClinicBranch({required String branchId});

  // --- Availability ---

  Future<Result<List<DoctorScheduleTemplate>>> getMyScheduleTemplates({
    String? affiliationId,
  });

  Future<Result<DoctorScheduleTemplate>> createMyScheduleTemplate(
    NewDoctorScheduleTemplate template,
  );

  Future<Result<DoctorScheduleTemplate>> updateMyScheduleTemplate({
    required String templateId,
    required DoctorScheduleTemplatePatch patch,
  });

  Future<Result<void>> deleteMyScheduleTemplate({
    required String templateId,
    int? version,
  });

  // --- Appointments ---

  Future<Result<DoctorAppointmentPage>> getMyAppointments({
    DateTime? from,
    DateTime? to,
    DoctorAppointmentStatus? status,
    String? clinicBranchId,
    String? cursor,
    int? limit,
  });

  Future<Result<DoctorAppointment>> getMyAppointment(String appointmentId);

  Future<Result<CancelAppointmentOutcome>> cancelMyAppointment({
    required String appointmentId,
    String? note,
  });

  Future<Result<RescheduleAppointmentOutcome>> rescheduleMyAppointment({
    required String appointmentId,
    required String newSlotId,
  });

  /// `POST /v1/doctors/me/appointments/branch/{clinicBranchId}/create` —
  /// walk-in booking by DOCTOR or CLINIC_STAFF. Exactly one of [patientId]
  /// or [patientPhone] must be given (the backend validates this itself);
  /// [patientName] is only used on the find-or-create-by-phone path, and
  /// only to name a brand-new patient — it never renames an existing one.
  Future<Result<DoctorAppointment>> bookWalkInAppointment({
    required String clinicBranchId,
    required String slotId,
    String? patientId,
    String? patientPhone,
    String? patientName,
  });

}

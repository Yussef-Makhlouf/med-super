import 'package:med_super/core/error/result.dart';
import '../entities/doctor_account_profile.dart';
import '../entities/doctor_appointment.dart';
import '../entities/doctor_clinic.dart';
import '../entities/doctor_notification.dart';
import '../entities/doctor_schedule_template.dart';
import '../entities/patient.dart';

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
  });

  // --- Clinics and branches ---

  Future<Result<List<DoctorClinic>>> getMyClinics();

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
  });

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

  // --- Still mock-only (no backend route) ---

  Future<Result<List<Patient>>> getPatients({String? query, String? filter});

  Future<Result<List<DoctorNotification>>> getNotifications();

  Future<Result<void>> markNotificationRead(String id);
}

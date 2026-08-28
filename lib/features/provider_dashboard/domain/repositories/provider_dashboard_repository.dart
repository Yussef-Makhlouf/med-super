import 'package:med_super/core/error/result.dart';
import 'package:med_super/features/provider_registration/domain/entities/clinic_working_day.dart';
import '../entities/appointment.dart';
import '../entities/clinic_settings.dart';
import '../entities/doctor_account_profile.dart';
import '../entities/doctor_notification.dart';
import '../entities/patient.dart';

abstract class ProviderDashboardRepository {
  Future<Result<List<Appointment>>> getAppointments({
    DateTime? date,
    String? status,
  });

  Future<Result<Appointment>> acceptAppointment(String id);

  Future<Result<Appointment>> rejectAppointment(String id);

  Future<Result<Appointment>> createAppointment({
    required String patientName,
    required DateTime scheduledStart,
    required DateTime scheduledEnd,
  });

  Future<Result<List<Patient>>> getPatients({String? query, String? filter});

  Future<Result<List<DoctorNotification>>> getNotifications();

  Future<Result<void>> markNotificationRead(String id);

  Future<Result<DoctorAccountProfile>> getDoctorAccount();

  Future<Result<DoctorAccountProfile>> updateDoctorAccount({
    required String name,
    required String specialty,
    required int yearsOfExperience,
    required String bio,
  });

  Future<Result<ClinicSettings>> getClinicSettings();

  Future<Result<ClinicSettings>> updateClinicSettings(ClinicSettings settings);

  Future<Result<List<ClinicWorkingDay>>> getDoctorSchedule();

  Future<Result<List<ClinicWorkingDay>>> updateDoctorSchedule(
    List<ClinicWorkingDay> workingDays,
  );

  Future<Result<DoctorAccountProfile>> uploadAvatar(String filePath);
}

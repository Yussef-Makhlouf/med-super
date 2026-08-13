import 'package:med_super/core/error/result.dart';
import '../entities/appointment.dart';
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

  Future<Result<List<Patient>>> getPatients({
    String? query,
    String? filter,
  });

  Future<Result<List<DoctorNotification>>> getNotifications();

  Future<Result<void>> markNotificationRead(String id);

  Future<Result<DoctorAccountProfile>> getDoctorAccount();
}

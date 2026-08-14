import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:med_super/core/di/core_providers.dart';
import 'package:med_super/features/provider_registration/domain/entities/clinic_working_day.dart';
import '../../data/datasources/remote/provider_dashboard_remote_datasource.dart';
import '../../data/repositories/provider_dashboard_repository_impl.dart';
import '../../domain/entities/appointment.dart';
import '../../domain/entities/clinic_settings.dart';
import '../../domain/entities/doctor_account_profile.dart';
import '../../domain/entities/doctor_notification.dart';
import '../../domain/entities/patient.dart';
import '../../domain/repositories/provider_dashboard_repository.dart';
import '../../domain/usecases/accept_appointment_usecase.dart';
import '../../domain/usecases/change_password_usecase.dart';
import '../../domain/usecases/clinic_settings_usecases.dart';
import '../../domain/usecases/create_appointment_usecase.dart';
import '../../domain/usecases/doctor_schedule_usecases.dart';
import '../../domain/usecases/get_appointments_usecase.dart';
import '../../domain/usecases/get_doctor_account_usecase.dart';
import '../../domain/usecases/get_notifications_usecase.dart';
import '../../domain/usecases/get_patients_usecase.dart';
import '../../domain/usecases/mark_notification_read_usecase.dart';
import '../../domain/usecases/reject_appointment_usecase.dart';
import '../../domain/usecases/update_doctor_account_usecase.dart';
import '../../domain/usecases/upload_avatar_usecase.dart';

part 'provider_dashboard_providers.g.dart';

@riverpod
ProviderDashboardRemoteDatasource providerDashboardRemoteDatasource(Ref ref) =>
    ProviderDashboardRemoteDatasourceImpl(ref.watch(dioProvider));

@riverpod
ProviderDashboardRepository providerDashboardRepository(Ref ref) =>
    ProviderDashboardRepositoryImpl(
      ref.watch(providerDashboardRemoteDatasourceProvider),
    );

@riverpod
GetAppointmentsUseCase getAppointmentsUseCase(Ref ref) =>
    GetAppointmentsUseCase(ref.watch(providerDashboardRepositoryProvider));

@riverpod
AcceptAppointmentUseCase acceptAppointmentUseCase(Ref ref) =>
    AcceptAppointmentUseCase(ref.watch(providerDashboardRepositoryProvider));

@riverpod
RejectAppointmentUseCase rejectAppointmentUseCase(Ref ref) =>
    RejectAppointmentUseCase(ref.watch(providerDashboardRepositoryProvider));

@riverpod
CreateAppointmentUseCase createAppointmentUseCase(Ref ref) =>
    CreateAppointmentUseCase(ref.watch(providerDashboardRepositoryProvider));

@riverpod
GetPatientsUseCase getPatientsUseCase(Ref ref) =>
    GetPatientsUseCase(ref.watch(providerDashboardRepositoryProvider));

@riverpod
GetNotificationsUseCase getNotificationsUseCase(Ref ref) =>
    GetNotificationsUseCase(ref.watch(providerDashboardRepositoryProvider));

@riverpod
MarkNotificationReadUseCase markNotificationReadUseCase(Ref ref) =>
    MarkNotificationReadUseCase(ref.watch(providerDashboardRepositoryProvider));

@riverpod
GetDoctorAccountUseCase getDoctorAccountUseCase(Ref ref) =>
    GetDoctorAccountUseCase(ref.watch(providerDashboardRepositoryProvider));

@riverpod
UpdateDoctorAccountUseCase updateDoctorAccountUseCase(Ref ref) =>
    UpdateDoctorAccountUseCase(ref.watch(providerDashboardRepositoryProvider));

@riverpod
GetClinicSettingsUseCase getClinicSettingsUseCase(Ref ref) =>
    GetClinicSettingsUseCase(ref.watch(providerDashboardRepositoryProvider));

@riverpod
UpdateClinicSettingsUseCase updateClinicSettingsUseCase(Ref ref) =>
    UpdateClinicSettingsUseCase(ref.watch(providerDashboardRepositoryProvider));

@riverpod
GetDoctorScheduleUseCase getDoctorScheduleUseCase(Ref ref) =>
    GetDoctorScheduleUseCase(ref.watch(providerDashboardRepositoryProvider));

@riverpod
UpdateDoctorScheduleUseCase updateDoctorScheduleUseCase(Ref ref) =>
    UpdateDoctorScheduleUseCase(ref.watch(providerDashboardRepositoryProvider));

@riverpod
ChangePasswordUseCase changePasswordUseCase(Ref ref) =>
    ChangePasswordUseCase(ref.watch(providerDashboardRepositoryProvider));

@riverpod
UploadAvatarUseCase uploadAvatarUseCase(Ref ref) =>
    UploadAvatarUseCase(ref.watch(providerDashboardRepositoryProvider));

// State Providers

@riverpod
Future<List<Appointment>> appointments(
  Ref ref, {
  DateTime? date,
  String? status,
}) async {
  final result = await ref
      .watch(getAppointmentsUseCaseProvider)
      .call(date: date, status: status);
  return result.when(ok: (value) => value, err: (failure) => throw failure);
}

@riverpod
Future<List<Patient>> patients(Ref ref, {String? query, String? filter}) async {
  final result = await ref
      .watch(getPatientsUseCaseProvider)
      .call(query: query, filter: filter);
  return result.when(ok: (value) => value, err: (failure) => throw failure);
}

@riverpod
Future<List<DoctorNotification>> doctorNotifications(Ref ref) async {
  final result = await ref.watch(getNotificationsUseCaseProvider).call();
  return result.when(ok: (value) => value, err: (failure) => throw failure);
}

@riverpod
Future<DoctorAccountProfile> doctorAccount(Ref ref) async {
  final result = await ref.watch(getDoctorAccountUseCaseProvider).call();
  return result.when(ok: (value) => value, err: (failure) => throw failure);
}

@riverpod
Future<ClinicSettings> clinicSettings(Ref ref) async {
  final result = await ref.watch(getClinicSettingsUseCaseProvider).call();
  return result.when(ok: (value) => value, err: (failure) => throw failure);
}

@riverpod
Future<List<ClinicWorkingDay>> doctorSchedule(Ref ref) async {
  final result = await ref.watch(getDoctorScheduleUseCaseProvider).call();
  return result.when(ok: (value) => value, err: (failure) => throw failure);
}

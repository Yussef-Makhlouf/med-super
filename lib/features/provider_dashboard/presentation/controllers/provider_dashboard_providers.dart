import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:med_super/core/di/core_providers.dart';
import 'package:med_super/features/auth/presentation/controllers/session_provider.dart';
import '../../data/datasources/remote/provider_dashboard_remote_datasource.dart';
import '../../data/repositories/provider_dashboard_repository_impl.dart';
import '../../domain/entities/doctor_account_profile.dart';
import '../../domain/entities/doctor_appointment.dart';
import '../../domain/entities/doctor_clinic.dart';
import '../../domain/entities/doctor_schedule_template.dart';
import '../../domain/entities/patient.dart';
import '../../domain/repositories/provider_dashboard_repository.dart';
import '../../domain/usecases/doctor_appointment_usecases.dart';
import '../../domain/usecases/doctor_clinic_usecases.dart';
import '../../domain/usecases/doctor_schedule_template_usecases.dart';
import '../../domain/usecases/get_doctor_account_usecase.dart';
import '../../domain/usecases/get_provider_patients_usecase.dart'
    show GetProviderPatientsUseCase, ProviderPatientsData;
import '../../domain/usecases/update_doctor_account_usecase.dart';

part 'provider_dashboard_providers.g.dart';

@riverpod
ProviderDashboardRemoteDatasource providerDashboardRemoteDatasource(Ref ref) =>
    ProviderDashboardRemoteDatasourceImpl(ref.watch(dioProvider));

@riverpod
ProviderDashboardRepository providerDashboardRepository(Ref ref) =>
    ProviderDashboardRepositoryImpl(
      ref.watch(providerDashboardRemoteDatasourceProvider),
    );

// --- Use cases ---

@riverpod
GetDoctorAccountUseCase getDoctorAccountUseCase(Ref ref) =>
    GetDoctorAccountUseCase(ref.watch(providerDashboardRepositoryProvider));

@riverpod
UpdateDoctorAccountUseCase updateDoctorAccountUseCase(Ref ref) =>
    UpdateDoctorAccountUseCase(ref.watch(providerDashboardRepositoryProvider));

@riverpod
GetMyClinicsUseCase getMyClinicsUseCase(Ref ref) =>
    GetMyClinicsUseCase(ref.watch(providerDashboardRepositoryProvider));

@riverpod
CreateMyClinicBranchUseCase createMyClinicBranchUseCase(Ref ref) =>
    CreateMyClinicBranchUseCase(ref.watch(providerDashboardRepositoryProvider));

@riverpod
UpdateMyClinicBranchUseCase updateMyClinicBranchUseCase(Ref ref) =>
    UpdateMyClinicBranchUseCase(ref.watch(providerDashboardRepositoryProvider));

@riverpod
SetMyAffiliationActiveUseCase setMyAffiliationActiveUseCase(Ref ref) =>
    SetMyAffiliationActiveUseCase(
      ref.watch(providerDashboardRepositoryProvider),
    );

@riverpod
DeleteMyClinicBranchUseCase deleteMyClinicBranchUseCase(Ref ref) =>
    DeleteMyClinicBranchUseCase(ref.watch(providerDashboardRepositoryProvider));

@riverpod
GetMyScheduleTemplatesUseCase getMyScheduleTemplatesUseCase(Ref ref) =>
    GetMyScheduleTemplatesUseCase(
      ref.watch(providerDashboardRepositoryProvider),
    );

@riverpod
CreateMyScheduleTemplateUseCase createMyScheduleTemplateUseCase(Ref ref) =>
    CreateMyScheduleTemplateUseCase(
      ref.watch(providerDashboardRepositoryProvider),
    );

@riverpod
UpdateMyScheduleTemplateUseCase updateMyScheduleTemplateUseCase(Ref ref) =>
    UpdateMyScheduleTemplateUseCase(
      ref.watch(providerDashboardRepositoryProvider),
    );

@riverpod
DeleteMyScheduleTemplateUseCase deleteMyScheduleTemplateUseCase(Ref ref) =>
    DeleteMyScheduleTemplateUseCase(
      ref.watch(providerDashboardRepositoryProvider),
    );

@riverpod
GetDoctorAppointmentsUseCase getDoctorAppointmentsUseCase(Ref ref) =>
    GetDoctorAppointmentsUseCase(ref.watch(providerDashboardRepositoryProvider));

@riverpod
GetDoctorAppointmentUseCase getDoctorAppointmentUseCase(Ref ref) =>
    GetDoctorAppointmentUseCase(ref.watch(providerDashboardRepositoryProvider));

@riverpod
CancelDoctorAppointmentUseCase cancelDoctorAppointmentUseCase(Ref ref) =>
    CancelDoctorAppointmentUseCase(
      ref.watch(providerDashboardRepositoryProvider),
    );

@riverpod
RescheduleDoctorAppointmentUseCase rescheduleDoctorAppointmentUseCase(Ref ref) =>
    RescheduleDoctorAppointmentUseCase(
      ref.watch(providerDashboardRepositoryProvider),
    );

@riverpod
BookWalkInAppointmentUseCase bookWalkInAppointmentUseCase(Ref ref) =>
    BookWalkInAppointmentUseCase(ref.watch(providerDashboardRepositoryProvider));

@riverpod
GetProviderPatientsUseCase getProviderPatientsUseCase(Ref ref) =>
    GetProviderPatientsUseCase(ref.watch(providerDashboardRepositoryProvider));

// --- State providers ---

@riverpod
Future<DoctorAccountProfile> doctorAccount(Ref ref) async {
  final result = await ref.watch(getDoctorAccountUseCaseProvider).call();
  return result.when(ok: (value) => value, err: (failure) => throw failure);
}

/// The header avatar for every provider-dashboard screen — never the
/// doctor's own photo for an assistant session: `doctorAccountProvider`
/// resolves to the doctor the assistant is *provisioned under*, not the
/// assistant's own identity, and `User` (the logged-in account) carries no
/// `photoUrl` of its own. So an assistant always sees the header's generic
/// person icon (`ProviderPageHeader` already falls back to that on `null`),
/// while a doctor sees their real photo. Every screen using
/// `ProviderPageHeader` should watch this instead of reading
/// `doctorAccountProvider.avatarUrl` directly.
@riverpod
String? providerHeaderAvatarUrl(Ref ref) {
  final isAssistant =
      ref.watch(sessionControllerProvider).asData?.value?.user.isAssistant ??
      false;
  if (isAssistant) return null;
  return ref
      .watch(doctorAccountProvider)
      .maybeWhen(data: (acc) => acc.avatarUrl, orElse: () => null);
}

/// The doctor's clinics/branches. Every mutation on this feature invalidates
/// it rather than mutating a local copy, so what the UI shows after a save is
/// always what the server returned.
@riverpod
Future<List<DoctorClinic>> myClinics(Ref ref) async {
  final result = await ref.watch(getMyClinicsUseCaseProvider).call();
  return result.when(ok: (value) => value, err: (failure) => throw failure);
}

/// Weekly availability. `affiliationId` narrows to one branch; omit it for
/// the combined plan across every branch the doctor works at.
@riverpod
Future<List<DoctorScheduleTemplate>> myScheduleTemplates(
  Ref ref, {
  String? affiliationId,
}) async {
  final result = await ref
      .watch(getMyScheduleTemplatesUseCaseProvider)
      .call(affiliationId: affiliationId);
  return result.when(ok: (value) => value, err: (failure) => throw failure);
}

/// One page of the doctor's appointment queue.
///
/// `from`/`to` are a half-open range on the slot start time — the backend
/// applies both bounds, so a single-day view sends midnight-to-midnight.
@riverpod
Future<DoctorAppointmentPage> doctorAppointments(
  Ref ref, {
  DateTime? from,
  DateTime? to,
  DoctorAppointmentStatus? status,
  String? clinicBranchId,
  String? cursor,
  int? limit,
}) async {
  final result = await ref
      .watch(getDoctorAppointmentsUseCaseProvider)
      .call(
        from: from,
        to: to,
        status: status,
        clinicBranchId: clinicBranchId,
        cursor: cursor,
        limit: limit,
      );
  return result.when(ok: (value) => value, err: (failure) => throw failure);
}

@riverpod
Future<DoctorAppointment> doctorAppointmentDetail(
  Ref ref,
  String appointmentId,
) async {
  final result = await ref
      .watch(getDoctorAppointmentUseCaseProvider)
      .call(appointmentId);
  return result.when(ok: (value) => value, err: (failure) => throw failure);
}

/// The doctor's patient list plus, for each `patientId`, every appointment
/// seen for them within the same ±90-day window — both derived from the
/// same single paged walk over `GET /v1/doctors/me/appointments` (see
/// `GetProviderPatientsUseCase`; there is no dedicated patients endpoint).
/// The detail screen reads [ProviderPatientsData.appointmentsByPatientId]
/// instead of running its own separate lookup.
@riverpod
Future<ProviderPatientsData> providerPatientsData(Ref ref) async {
  final result = await ref
      .watch(getProviderPatientsUseCaseProvider)
      .callWithAppointments();
  return result.when(ok: (value) => value, err: (failure) => throw failure);
}

/// The patient list alone, for callers that don't need per-patient
/// appointment histories.
@riverpod
Future<List<Patient>> providerPatients(Ref ref) async {
  final data = await ref.watch(providerPatientsDataProvider.future);
  return data.patients;
}


import 'package:med_super/core/error/dio_failure_mapper.dart';
import 'package:med_super/core/error/result.dart';
import '../datasources/remote/provider_dashboard_remote_datasource.dart';
import '../models/doctor_clinic_dto.dart';
import '../../domain/entities/doctor_account_profile.dart';
import '../../domain/entities/doctor_appointment.dart';
import '../../domain/entities/doctor_clinic.dart';
import '../../domain/entities/doctor_notification.dart';
import '../../domain/entities/doctor_schedule_template.dart';
import '../../domain/entities/patient.dart';
import '../../domain/repositories/provider_dashboard_repository.dart';

class ProviderDashboardRepositoryImpl implements ProviderDashboardRepository {
  ProviderDashboardRepositoryImpl(this._remote);

  final ProviderDashboardRemoteDatasource _remote;

  /// Every method funnels through here so a `DioException` becomes a typed
  /// `Failure` in exactly one place — 401/403/404/409/422 all map to distinct
  /// `Failure` subtypes in `mapDioToFailure`, which is what lets the screens
  /// tell "you can't do that" apart from "someone else changed it first".
  Future<Result<T>> _guard<T>(Future<T> Function() run) async {
    try {
      return Result.ok(await run());
    } catch (e, st) {
      return Result.err(mapDioToFailure(e, st));
    }
  }

  @override
  Future<Result<DoctorAccountProfile>> getDoctorAccount() =>
      _guard(() async => (await _remote.getDoctorAccount()).toEntity());

  @override
  Future<Result<DoctorAccountProfile>> updateDoctorAccount({
    String? bio,
    String? degree,
    int? yearsOfExperience,
  }) => _guard(
    () async => (await _remote.updateDoctorAccount(
      bio: bio,
      degree: degree,
      yearsOfExperience: yearsOfExperience,
    )).toEntity(),
  );

  @override
  Future<Result<List<DoctorClinic>>> getMyClinics() => _guard(() async {
    final dtos = await _remote.getMyClinics();
    return dtos.map((dto) => dto.toEntity()).toList();
  });

  @override
  Future<Result<DoctorClinic>> updateMyClinicBranch({
    required String branchId,
    String? phone,
    String? ianaTimezone,
    String? addressLine1,
    String? addressCity,
  }) => _guard(() async {
    final body = UpdateDoctorBranchRequestDto(
      phone: phone,
      ianaTimezone: ianaTimezone,
      addressLine1: addressLine1,
      addressCity: addressCity,
    );
    final dto = await _remote.updateMyClinicBranch(branchId, body);
    return dto.toEntity();
  });

  @override
  Future<Result<DoctorClinic>> setMyAffiliationActive({
    required String affiliationId,
    required bool active,
  }) => _guard(() async {
    final dto = await _remote.updateMyAffiliationStatus(
      affiliationId,
      active: active,
    );
    return dto.toEntity();
  });

  @override
  Future<Result<List<DoctorScheduleTemplate>>> getMyScheduleTemplates({
    String? affiliationId,
  }) => _guard(() async {
    final dtos = await _remote.getMyScheduleTemplates(
      affiliationId: affiliationId,
    );
    return dtos.map((dto) => dto.toEntity()).toList();
  });

  @override
  Future<Result<DoctorScheduleTemplate>> createMyScheduleTemplate(
    NewDoctorScheduleTemplate template,
  ) => _guard(
    () async => (await _remote.createMyScheduleTemplate(template)).toEntity(),
  );

  @override
  Future<Result<DoctorScheduleTemplate>> updateMyScheduleTemplate({
    required String templateId,
    required DoctorScheduleTemplatePatch patch,
  }) => _guard(
    () async =>
        (await _remote.updateMyScheduleTemplate(templateId, patch)).toEntity(),
  );

  @override
  Future<Result<void>> deleteMyScheduleTemplate({
    required String templateId,
    int? version,
  }) => _guard(
    () => _remote.deleteMyScheduleTemplate(templateId, version: version),
  );

  @override
  Future<Result<DoctorAppointmentPage>> getMyAppointments({
    DateTime? from,
    DateTime? to,
    DoctorAppointmentStatus? status,
    String? clinicBranchId,
    String? cursor,
    int? limit,
  }) => _guard(() async {
    final page = await _remote.getMyAppointments(
      from: from,
      to: to,
      status: status,
      clinicBranchId: clinicBranchId,
      cursor: cursor,
      limit: limit,
    );
    return page.toEntity();
  });

  @override
  Future<Result<DoctorAppointment>> getMyAppointment(String appointmentId) =>
      _guard(
        () async => (await _remote.getMyAppointment(appointmentId)).toEntity(),
      );

  @override
  Future<Result<CancelAppointmentOutcome>> cancelMyAppointment({
    required String appointmentId,
    String? note,
  }) => _guard(() async {
    final dto = await _remote.cancelMyAppointment(appointmentId, note: note);
    return CancelAppointmentOutcome(
      refundAmount: dto.refundAmount,
      feeApplied: dto.feeApplied,
    );
  });

  @override
  Future<Result<RescheduleAppointmentOutcome>> rescheduleMyAppointment({
    required String appointmentId,
    required String newSlotId,
  }) => _guard(() async {
    final dto = await _remote.rescheduleMyAppointment(
      appointmentId,
      newSlotId: newSlotId,
    );
    return RescheduleAppointmentOutcome(
      newAppointmentId: dto.appointmentId,
      slotId: dto.slotId,
      previousAppointmentId: dto.previousAppointmentId,
    );
  });

  @override
  Future<Result<List<Patient>>> getPatients({String? query, String? filter}) =>
      _guard(() async {
        final dtos = await _remote.getPatients(query: query, filter: filter);
        return dtos.map((dto) => dto.toEntity()).toList();
      });

  @override
  Future<Result<List<DoctorNotification>>> getNotifications() =>
      _guard(() async {
        final dtos = await _remote.getNotifications();
        return dtos.map((dto) => dto.toEntity()).toList();
      });

  @override
  Future<Result<void>> markNotificationRead(String id) =>
      _guard(() => _remote.markNotificationRead(id));
}

import 'package:med_super/core/error/dio_failure_mapper.dart';
import 'package:med_super/core/error/result.dart';
import 'package:med_super/features/provider_registration/domain/entities/clinic_working_day.dart';
import '../datasources/remote/provider_dashboard_remote_datasource.dart';
import '../models/clinic_settings_dto.dart';
import '../models/doctor_schedule_dto.dart';
import '../../domain/entities/appointment.dart';
import '../../domain/entities/clinic_settings.dart';
import '../../domain/entities/doctor_account_profile.dart';
import '../../domain/entities/doctor_notification.dart';
import '../../domain/entities/patient.dart';
import '../../domain/repositories/provider_dashboard_repository.dart';

class ProviderDashboardRepositoryImpl implements ProviderDashboardRepository {
  ProviderDashboardRepositoryImpl(this._remote);

  final ProviderDashboardRemoteDatasource _remote;

  @override
  Future<Result<List<Appointment>>> getAppointments({
    DateTime? date,
    String? status,
  }) async {
    try {
      final dtos = await _remote.getAppointments(date: date, status: status);
      return Result.ok(dtos.map((dto) => dto.toEntity()).toList());
    } catch (e, st) {
      return Result.err(mapDioToFailure(e, st));
    }
  }

  @override
  Future<Result<Appointment>> acceptAppointment(String id) async {
    try {
      final dto = await _remote.acceptAppointment(id);
      return Result.ok(dto.toEntity());
    } catch (e, st) {
      return Result.err(mapDioToFailure(e, st));
    }
  }

  @override
  Future<Result<Appointment>> rejectAppointment(String id) async {
    try {
      final dto = await _remote.rejectAppointment(id);
      return Result.ok(dto.toEntity());
    } catch (e, st) {
      return Result.err(mapDioToFailure(e, st));
    }
  }

  @override
  Future<Result<Appointment>> createAppointment({
    required String patientName,
    required DateTime scheduledStart,
    required DateTime scheduledEnd,
  }) async {
    try {
      final dto = await _remote.createAppointment(
        patientName: patientName,
        scheduledStart: scheduledStart,
        scheduledEnd: scheduledEnd,
      );
      return Result.ok(dto.toEntity());
    } catch (e, st) {
      return Result.err(mapDioToFailure(e, st));
    }
  }

  @override
  Future<Result<List<Patient>>> getPatients({
    String? query,
    String? filter,
  }) async {
    try {
      final dtos = await _remote.getPatients(query: query, filter: filter);
      return Result.ok(dtos.map((dto) => dto.toEntity()).toList());
    } catch (e, st) {
      return Result.err(mapDioToFailure(e, st));
    }
  }

  @override
  Future<Result<List<DoctorNotification>>> getNotifications() async {
    try {
      final dtos = await _remote.getNotifications();
      return Result.ok(dtos.map((dto) => dto.toEntity()).toList());
    } catch (e, st) {
      return Result.err(mapDioToFailure(e, st));
    }
  }

  @override
  Future<Result<void>> markNotificationRead(String id) async {
    try {
      await _remote.markNotificationRead(id);
      return const Result.ok(null);
    } catch (e, st) {
      return Result.err(mapDioToFailure(e, st));
    }
  }

  @override
  Future<Result<DoctorAccountProfile>> getDoctorAccount() async {
    try {
      final dto = await _remote.getDoctorAccount();
      return Result.ok(dto.toEntity());
    } catch (e, st) {
      return Result.err(mapDioToFailure(e, st));
    }
  }

  @override
  Future<Result<DoctorAccountProfile>> updateDoctorAccount({
    required String name,
    required String specialty,
    required int yearsOfExperience,
    required String bio,
  }) async {
    try {
      final dto = await _remote.updateDoctorAccount(
        name: name,
        specialty: specialty,
        yearsOfExperience: yearsOfExperience,
        bio: bio,
      );
      return Result.ok(dto.toEntity());
    } catch (e, st) {
      return Result.err(mapDioToFailure(e, st));
    }
  }

  @override
  Future<Result<ClinicSettings>> getClinicSettings() async {
    try {
      final dto = await _remote.getClinicSettings();
      return Result.ok(dto.toEntity());
    } catch (e, st) {
      return Result.err(mapDioToFailure(e, st));
    }
  }

  @override
  Future<Result<ClinicSettings>> updateClinicSettings(
    ClinicSettings settings,
  ) async {
    try {
      final dto = await _remote.updateClinicSettings(
        ClinicSettingsDto(
          clinicName: settings.clinicName,
          address: settings.address,
          phone: settings.phone,
          email: settings.email,
          city: settings.city,
        ),
      );
      return Result.ok(dto.toEntity());
    } catch (e, st) {
      return Result.err(mapDioToFailure(e, st));
    }
  }

  @override
  Future<Result<List<ClinicWorkingDay>>> getDoctorSchedule() async {
    try {
      final dto = await _remote.getDoctorSchedule();
      return Result.ok(dto.workingDays);
    } catch (e, st) {
      return Result.err(mapDioToFailure(e, st));
    }
  }

  @override
  Future<Result<List<ClinicWorkingDay>>> updateDoctorSchedule(
    List<ClinicWorkingDay> workingDays,
  ) async {
    try {
      final dto = await _remote.updateDoctorSchedule(
        DoctorScheduleDto(workingDays: workingDays),
      );
      return Result.ok(dto.workingDays);
    } catch (e, st) {
      return Result.err(mapDioToFailure(e, st));
    }
  }

  @override
  Future<Result<DoctorAccountProfile>> uploadAvatar(String filePath) async {
    try {
      final dto = await _remote.uploadAvatar(filePath);
      return Result.ok(dto.toEntity());
    } catch (e, st) {
      return Result.err(mapDioToFailure(e, st));
    }
  }
}

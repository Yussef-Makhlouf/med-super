import 'package:med_super/core/error/dio_failure_mapper.dart';
import 'package:med_super/core/error/result.dart';
import '../../domain/entities/appointment.dart';
import '../../domain/entities/doctor_account_profile.dart';
import '../../domain/entities/doctor_notification.dart';
import '../../domain/entities/patient.dart';
import '../../domain/repositories/provider_dashboard_repository.dart';
import '../datasources/remote/provider_dashboard_remote_datasource.dart';

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
}

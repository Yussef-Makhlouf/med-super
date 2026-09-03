import 'package:med_super/core/error/dio_failure_mapper.dart';
import 'package:med_super/core/error/result.dart';
import 'package:med_super/features/appointments/data/datasources/remote/appointments_remote_datasource.dart';
import 'package:med_super/features/appointments/domain/entities/appointment_hold.dart';
import 'package:med_super/features/appointments/domain/entities/appointment_summary.dart';
import 'package:med_super/features/appointments/domain/entities/confirmed_appointment.dart';
import 'package:med_super/features/appointments/domain/repositories/appointment_repository.dart';

class AppointmentRepositoryImpl implements AppointmentRepository {
  AppointmentRepositoryImpl({required AppointmentsRemoteDatasource remote})
    : _remote = remote;

  final AppointmentsRemoteDatasource _remote;

  @override
  Future<Result<AppointmentHold>> createHold({
    required String doctorClinicAffiliationId,
    required String slotId,
    required String patientId,
  }) async {
    try {
      final dto = await _remote.createHold(
        doctorClinicAffiliationId: doctorClinicAffiliationId,
        slotId: slotId,
        patientId: patientId,
      );
      return Result.ok(dto.toEntity());
    } catch (e, st) {
      return Result.err(mapDioToFailure(e, st));
    }
  }

  @override
  Future<Result<ConfirmedAppointment>> confirmHold(String holdId) async {
    try {
      final dto = await _remote.confirmHold(holdId);
      return Result.ok(dto.toEntity());
    } catch (e, st) {
      return Result.err(mapDioToFailure(e, st));
    }
  }

  @override
  Future<Result<CancelledAppointment>> cancel({
    required String appointmentId,
    required String reason,
    String? note,
  }) async {
    try {
      final dto = await _remote.cancel(
        appointmentId: appointmentId,
        reason: reason,
        note: note,
      );
      return Result.ok(dto.toEntity());
    } catch (e, st) {
      return Result.err(mapDioToFailure(e, st));
    }
  }

  @override
  Future<Result<AppointmentHold>> reschedule({
    required String appointmentId,
    required String newSlotId,
  }) async {
    try {
      final dto = await _remote.reschedule(
        appointmentId: appointmentId,
        newSlotId: newSlotId,
      );
      return Result.ok(dto.toEntity());
    } catch (e, st) {
      return Result.err(mapDioToFailure(e, st));
    }
  }

  @override
  Future<Result<AppointmentSummaryPage>> listMine({
    String? status,
    String? cursor,
    int? limit,
  }) async {
    try {
      final page = await _remote.listMine(
        status: status,
        cursor: cursor,
        limit: limit,
      );
      return Result.ok(
        AppointmentSummaryPage(
          items: page.items.map((d) => d.toEntity()).toList(),
          nextCursor: page.nextCursor,
        ),
      );
    } catch (e, st) {
      return Result.err(mapDioToFailure(e, st));
    }
  }

  @override
  Future<Result<AppointmentSummary>> getById(String appointmentId) async {
    try {
      final dto = await _remote.getById(appointmentId);
      return Result.ok(dto.toEntity());
    } catch (e, st) {
      return Result.err(mapDioToFailure(e, st));
    }
  }
}

import 'package:med_super/core/error/dio_failure_mapper.dart';
import 'package:med_super/core/error/result.dart';
import 'package:med_super/features/provider_profile/data/datasources/remote/doctor_slots_remote_datasource.dart';
import 'package:med_super/features/provider_profile/domain/entities/doctor_slot.dart';
import 'package:med_super/features/provider_profile/domain/repositories/doctor_slots_repository.dart';

class DoctorSlotsRepositoryImpl implements DoctorSlotsRepository {
  DoctorSlotsRepositoryImpl({required DoctorSlotsRemoteDatasource remote})
    : _remote = remote;

  final DoctorSlotsRemoteDatasource _remote;

  @override
  Future<Result<List<DoctorSlot>>> getDoctorSlots({
    required String doctorId,
    required String clinicBranchId,
    DateTime? from,
    DateTime? to,
  }) async {
    try {
      final slots = await _remote.getDoctorSlots(
        doctorId: doctorId,
        clinicBranchId: clinicBranchId,
        from: from,
        to: to,
      );
      return Result.ok(slots);
    } catch (e, st) {
      return Result.err(mapDioToFailure(e, st));
    }
  }
}

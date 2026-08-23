import 'package:med_super/core/error/result.dart';
import 'package:med_super/features/provider_profile/domain/entities/available_day.dart';
import 'package:med_super/features/provider_profile/domain/repositories/doctor_slots_repository.dart';
import 'package:med_super/features/provider_profile/domain/utils/slot_grouping.dart';

/// Phase 3 (Availability): real slots only — no hold/booking. Groups the
/// backend's flat slot list into the UI's existing day/slot shape.
class GetDoctorAvailabilityUseCase {
  const GetDoctorAvailabilityUseCase(this._repository);

  final DoctorSlotsRepository _repository;

  Future<Result<List<AvailableDay>>> call({
    required String doctorId,
    required String clinicBranchId,
    String? ianaTimezone,
  }) async {
    final result = await _repository.getDoctorSlots(
      doctorId: doctorId,
      clinicBranchId: clinicBranchId,
    );
    return result.map(
      (slots) => groupSlotsIntoAvailableDays(slots, ianaTimezone: ianaTimezone),
    );
  }
}

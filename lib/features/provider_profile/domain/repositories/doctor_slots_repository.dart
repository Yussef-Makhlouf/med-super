import 'package:med_super/core/error/result.dart';
import 'package:med_super/features/provider_profile/domain/entities/doctor_slot.dart';

abstract class DoctorSlotsRepository {
  Future<Result<List<DoctorSlot>>> getDoctorSlots({
    required String doctorId,
    required String clinicBranchId,
    DateTime? from,
    DateTime? to,
  });
}

import 'package:med_super/core/error/result.dart';
import 'package:med_super/features/appointments/domain/entities/appointment_hold.dart';
import 'package:med_super/features/appointments/domain/repositories/appointment_repository.dart';

class CreateHoldUseCase {
  const CreateHoldUseCase(this._repository);

  final AppointmentRepository _repository;

  Future<Result<AppointmentHold>> call({
    required String doctorClinicAffiliationId,
    required String slotId,
    required String patientId,
  }) => _repository.createHold(
    doctorClinicAffiliationId: doctorClinicAffiliationId,
    slotId: slotId,
    patientId: patientId,
  );
}

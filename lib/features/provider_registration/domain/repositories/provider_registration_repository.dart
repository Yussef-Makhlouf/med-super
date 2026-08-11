import 'package:med_super/core/error/result.dart';
import 'package:med_super/features/provider_registration/domain/entities/doctor_registration_draft.dart';

abstract class ProviderRegistrationRepository {
  Future<Result<void>> submit(DoctorRegistrationDraft draft);
}

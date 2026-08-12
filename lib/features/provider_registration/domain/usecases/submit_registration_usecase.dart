import 'package:med_super/core/error/result.dart';
import 'package:med_super/features/provider_registration/domain/entities/doctor_registration_draft.dart';
import 'package:med_super/features/provider_registration/domain/repositories/provider_registration_repository.dart';

class SubmitRegistrationUseCase {
  const SubmitRegistrationUseCase(this._repository);

  final ProviderRegistrationRepository _repository;

  Future<Result<void>> call(DoctorRegistrationDraft draft) =>
      _repository.submit(draft);
}

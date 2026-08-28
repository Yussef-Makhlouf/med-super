import 'package:med_super/core/error/result.dart';
import 'package:med_super/features/provider_dashboard/domain/entities/provisioned_assistant.dart';
import 'package:med_super/features/provider_dashboard/domain/repositories/assistant_repository.dart';

class CreateAssistantUseCase {
  const CreateAssistantUseCase(this._repository);
  final AssistantRepository _repository;

  Future<Result<ProvisionedAssistant>> call({
    required String phone,
    required String displayName,
  }) => _repository.createAssistant(phone: phone, displayName: displayName);
}

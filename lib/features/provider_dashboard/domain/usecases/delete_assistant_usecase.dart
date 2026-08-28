import 'package:med_super/core/error/result.dart';
import 'package:med_super/features/provider_dashboard/domain/repositories/assistant_repository.dart';

class DeleteAssistantUseCase {
  const DeleteAssistantUseCase(this._repository);
  final AssistantRepository _repository;

  Future<Result<void>> call(String id) => _repository.deleteAssistant(id);
}

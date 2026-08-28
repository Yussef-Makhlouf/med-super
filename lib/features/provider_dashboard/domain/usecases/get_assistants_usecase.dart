import 'package:med_super/core/error/result.dart';
import 'package:med_super/features/provider_dashboard/domain/entities/assistant.dart';
import 'package:med_super/features/provider_dashboard/domain/repositories/assistant_repository.dart';

class GetAssistantsUseCase {
  const GetAssistantsUseCase(this._repository);
  final AssistantRepository _repository;

  Future<Result<List<Assistant>>> call() => _repository.getAssistants();
}

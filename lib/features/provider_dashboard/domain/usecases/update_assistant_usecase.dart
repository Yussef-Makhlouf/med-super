import 'package:med_super/core/error/result.dart';
import 'package:med_super/features/provider_dashboard/domain/entities/assistant.dart';
import 'package:med_super/features/provider_dashboard/domain/repositories/assistant_repository.dart';

class UpdateAssistantUseCase {
  const UpdateAssistantUseCase(this._repository);
  final AssistantRepository _repository;

  Future<Result<Assistant>> call({
    required String id,
    String? displayName,
    String? status,
    String? password,
    String? title,
    String? subtitle,
    List<String>? clinicBranchIds,
  }) => _repository.updateAssistant(
    id: id,
    displayName: displayName,
    status: status,
    password: password,
    title: title,
    subtitle: subtitle,
    clinicBranchIds: clinicBranchIds,
  );
}

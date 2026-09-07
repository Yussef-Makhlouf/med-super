import 'package:med_super/core/error/result.dart';
import 'package:med_super/features/provider_dashboard/domain/entities/assistant.dart';
import 'package:med_super/features/provider_dashboard/domain/entities/provisioned_assistant.dart';

abstract class AssistantRepository {
  Future<Result<List<Assistant>>> getAssistants();

  Future<Result<ProvisionedAssistant>> createAssistant({
    required String phone,
    required String displayName,
    String? title,
    String? subtitle,
    required List<String> clinicBranchIds,
  });

  Future<Result<Assistant>> updateAssistant({
    required String id,
    String? displayName,
    String? status,
    String? password,
    String? title,
    String? subtitle,
    List<String>? clinicBranchIds,
  });

  Future<Result<void>> deleteAssistant(String id);
}

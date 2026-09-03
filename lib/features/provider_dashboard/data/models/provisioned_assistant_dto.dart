import 'package:med_super/features/provider_dashboard/domain/entities/assistant_status.dart';
import 'package:med_super/features/provider_dashboard/domain/entities/provisioned_assistant.dart';

/// DTO for the one-time provisioning response — same fields as
/// [AssistantDto] plus `generated_password`.
class ProvisionedAssistantDto {
  const ProvisionedAssistantDto({
    required this.id,
    required this.phone,
    required this.displayName,
    required this.status,
    required this.createdAt,
    required this.generatedPassword,
  });

  final String id;
  final String phone;
  final String displayName;
  final String status;
  final String createdAt;
  final String generatedPassword;

  factory ProvisionedAssistantDto.fromJson(Map<String, dynamic> json) =>
      ProvisionedAssistantDto(
        id: json['id'] as String,
        phone: json['phone'] as String,
        displayName:
            (json['displayName'] ?? json['display_name'] ?? '') as String,
        status: (json['status'] ?? 'ACTIVE') as String,
        createdAt: (json['createdAt'] ?? json['created_at'] ?? '') as String,
        generatedPassword:
            (json['generatedPassword'] ?? json['generated_password'] ?? '')
                as String,
      );

  ProvisionedAssistant toEntity() => ProvisionedAssistant(
    id: id,
    phone: phone,
    displayName: displayName,
    status: AssistantStatus.fromApi(status),
    createdAt: DateTime.tryParse(createdAt) ?? DateTime.now(),
    generatedPassword: generatedPassword,
  );
}

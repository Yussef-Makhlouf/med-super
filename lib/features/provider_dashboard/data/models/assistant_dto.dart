import 'package:med_super/features/provider_dashboard/domain/entities/assistant.dart';
import 'package:med_super/features/provider_dashboard/domain/entities/assistant_status.dart';

class AssistantDto {
  const AssistantDto({
    required this.id,
    required this.phone,
    required this.displayName,
    required this.status,
    required this.createdAt,
    this.generatedPassword,
  });

  final String id;
  final String phone;
  final String displayName;
  final String status;
  final String createdAt;
  final String? generatedPassword;

  factory AssistantDto.fromJson(Map<String, dynamic> json) => AssistantDto(
    id: json['id'] as String,
    phone: json['phone'] as String,
    displayName: (json['displayName'] ?? json['display_name'] ?? '') as String,
    status: (json['status'] ?? 'ACTIVE') as String,
    createdAt: (json['createdAt'] ?? json['created_at'] ?? '') as String,
    generatedPassword:
        (json['generatedPassword'] ?? json['generated_password']) as String?,
  );

  Assistant toEntity() => Assistant(
    id: id,
    phone: phone,
    displayName: displayName,
    status: AssistantStatus.fromApi(status),
    createdAt: DateTime.tryParse(createdAt) ?? DateTime.now(),
    generatedPassword: generatedPassword,
  );
}

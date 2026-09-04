import 'assistant_status.dart';

/// A clinic assistant provisioned by a Doctor.
/// Pure domain — no Flutter/Dio imports.
class Assistant {
  const Assistant({
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
  final AssistantStatus status;
  final DateTime createdAt;
  final String? generatedPassword;

  bool get isActive => status == AssistantStatus.active;

  Assistant copyWith({
    String? id,
    String? phone,
    String? displayName,
    AssistantStatus? status,
    DateTime? createdAt,
    String? generatedPassword,
  }) => Assistant(
    id: id ?? this.id,
    phone: phone ?? this.phone,
    displayName: displayName ?? this.displayName,
    status: status ?? this.status,
    createdAt: createdAt ?? this.createdAt,
    generatedPassword: generatedPassword ?? this.generatedPassword,
  );
}

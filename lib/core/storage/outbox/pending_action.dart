import 'dart:convert';

/// A write action queued while offline. Persisted to Hive as JSON.
class PendingAction {
  const PendingAction({
    required this.id,
    required this.type,
    required this.payload,
    required this.idempotencyKey,
    required this.createdAt,
    this.attemptCount = 0,
  });

  final String id;
  final String type;
  final Map<String, dynamic> payload;
  final String idempotencyKey;
  final DateTime createdAt;
  final int attemptCount;

  PendingAction copyWith({
    String? id,
    String? type,
    Map<String, dynamic>? payload,
    String? idempotencyKey,
    DateTime? createdAt,
    int? attemptCount,
  }) => PendingAction(
    id: id ?? this.id,
    type: type ?? this.type,
    payload: payload ?? this.payload,
    idempotencyKey: idempotencyKey ?? this.idempotencyKey,
    createdAt: createdAt ?? this.createdAt,
    attemptCount: attemptCount ?? this.attemptCount,
  );

  factory PendingAction.fromJson(Map<String, dynamic> json) => PendingAction(
    id: json['id'] as String,
    type: json['type'] as String,
    payload: (json['payload'] as Map<String, dynamic>?) ?? {},
    idempotencyKey: json['idempotencyKey'] as String,
    createdAt: DateTime.parse(json['createdAt'] as String),
    attemptCount: (json['attemptCount'] as num?)?.toInt() ?? 0,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type,
    'payload': payload,
    'idempotencyKey': idempotencyKey,
    'createdAt': createdAt.toIso8601String(),
    'attemptCount': attemptCount,
  };

  String toJsonString() => jsonEncode(toJson());

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PendingAction &&
          id == other.id &&
          type == other.type &&
          idempotencyKey == other.idempotencyKey;

  @override
  int get hashCode => Object.hash(id, type, idempotencyKey);

  @override
  String toString() =>
      'PendingAction(id: $id, type: $type, createdAt: $createdAt, attempt: $attemptCount)';
}

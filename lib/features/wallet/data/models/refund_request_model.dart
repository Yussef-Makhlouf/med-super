import 'package:med_super/features/wallet/domain/entities/refund_request.dart';

class RefundRequestModel extends RefundRequest {
  const RefundRequestModel({
    required super.id,
    required super.transactionId,
    required super.reason,
    required super.description,
    required super.createdAt,
    required super.currentStatus,
    super.amount = 0.0,
    required super.timeline,
  });

  factory RefundRequestModel.fromJson(Map<String, dynamic> json) {
    final rawTimeline = json['timeline'] as List<dynamic>? ?? [];
    final parsedTimeline = rawTimeline.map((item) {
      final map = item as Map<String, dynamic>;
      final statusStr = map['status'] as String? ?? 'pending';
      RefundStepStatus stepStatus = RefundStepStatus.pending;
      if (statusStr == 'completed') stepStatus = RefundStepStatus.completed;
      if (statusStr == 'active') stepStatus = RefundStepStatus.active;
      return RefundStatusTimelineStep(
        title: map['title'] as String? ?? '',
        timestamp: map['timestamp'] as String?,
        status: stepStatus,
      );
    }).toList();

    // Support both 'current_status' and 'status' keys from the API
    final statusValue = (json['current_status'] ?? json['status']) as String? ?? 'submitted';

    return RefundRequestModel(
      id: json['id'] as String? ?? '',
      transactionId: json['transaction_id'] as String? ?? '',
      reason: json['reason'] as String? ?? '',
      description: (json['description'] ?? json['details']) as String? ?? '',
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ?? DateTime.now(),
      currentStatus: statusValue,
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      timeline: parsedTimeline,
    );
  }
}

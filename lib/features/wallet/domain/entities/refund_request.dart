enum RefundStepStatus { completed, active, pending }
enum RefundStatus { submitted, underReview, approved, transferred, rejected }

class RefundStatusTimelineStep {
  final String title;
  final String? timestamp;
  final RefundStepStatus status;

  const RefundStatusTimelineStep({
    required this.title,
    this.timestamp,
    required this.status,
  });
}

class RefundRequest {
  final String id;
  final String transactionId;
  final String reason;
  final String description;
  final DateTime createdAt;
  final String currentStatus;
  final double amount;
  final List<RefundStatusTimelineStep> timeline;

  const RefundRequest({
    required this.id,
    required this.transactionId,
    required this.reason,
    required this.description,
    required this.createdAt,
    required this.currentStatus,
    this.amount = 450.0,
    required this.timeline,
  });

  RefundStatus get status {
    switch (currentStatus.toLowerCase()) {
      case 'under_review':
      case 'underreview':
        return RefundStatus.underReview;
      case 'approved':
        return RefundStatus.approved;
      case 'transferred':
        return RefundStatus.transferred;
      case 'rejected':
        return RefundStatus.rejected;
      case 'submitted':
      default:
        return RefundStatus.submitted;
    }
  }
}

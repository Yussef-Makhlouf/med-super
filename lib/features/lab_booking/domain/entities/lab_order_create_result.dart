/// Result of `POST /v1/lab-orders` — mirrors the backend's
/// `CreateLabOrderResult` (`clinic-reservations` `CreateLabOrderUseCase`).
/// `status` is always `'REQUESTED'` at creation time — there is no
/// broadcast-branch-ids concept here the way pharmacy orders have, since a
/// lab order is always assigned to exactly one, caller-chosen branch.
class LabOrderCreateResult {
  const LabOrderCreateResult({required this.labOrderId, required this.status});

  final String labOrderId;
  final String status;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LabOrderCreateResult &&
          other.labOrderId == labOrderId &&
          other.status == status);

  @override
  int get hashCode => Object.hash(labOrderId, status);
}

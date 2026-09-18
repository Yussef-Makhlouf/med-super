import 'package:flutter/foundation.dart' show listEquals;

/// Result of `POST /v1/pharmacy-orders` — mirrors the backend's
/// `CreatePharmacyOrderResult` (File 12 Part 39/44).
class PharmacyOrderCreateResult {
  const PharmacyOrderCreateResult({
    required this.pharmacyOrderId,
    required this.status,
    required this.broadcastedBranchIds,
  });

  final String pharmacyOrderId;
  final String status;
  final List<String> broadcastedBranchIds;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PharmacyOrderCreateResult &&
          other.pharmacyOrderId == pharmacyOrderId &&
          other.status == status &&
          listEquals(other.broadcastedBranchIds, broadcastedBranchIds));

  @override
  int get hashCode => Object.hash(
    pharmacyOrderId,
    status,
    Object.hashAll(broadcastedBranchIds),
  );
}

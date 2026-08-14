/// One real, bookable-in-a-later-phase appointment slot from the backend's
/// `GET /v1/doctors/{doctorId}/slots` (Phase 3 — Availability). Always
/// `OPEN` — the backend never returns held/booked slots from this endpoint.
/// Deliberately has no booking/hold affordance: Phase 4 (Appointments) does
/// not exist yet (docs/decisions — do not build ahead of backend phase).
class DoctorSlot {
  const DoctorSlot({
    required this.slotId,
    required this.startAtUtc,
    required this.endAtUtc,
  });

  final String slotId;
  final DateTime startAtUtc;
  final DateTime endAtUtc;
}

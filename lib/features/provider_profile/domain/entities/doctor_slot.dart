/// One real, bookable appointment slot from the backend's
/// `GET /v1/doctors/{doctorId}/slots` (Phase 3 — Availability). Always
/// `OPEN` — the backend never returns held/booked slots from this endpoint.
/// `slotId` is what `lib/features/appointments` sends to
/// `POST /v1/appointments/hold` (Phase 4, real now) once selected —
/// `slot_grouping.dart` carries it through unchanged as `TimeSlot.id`.
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

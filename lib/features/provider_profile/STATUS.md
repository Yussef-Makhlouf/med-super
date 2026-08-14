# Feature status: provider_profile

**Label:** `PARTIAL` (doctor detail: `BACKEND_READY`-shaped but unverified
wire format; availability: `BACKEND_READY`)

- Doctor detail (`GET /v1/doctors/{id}`) — calls the real Phase 2 contract,
  but the frontend's `DoctorProfileDto` assumes a flat, snake_case JSON
  shape that hasn't been verified against the real backend's actual
  response, which returns raw Prisma model shapes for `affiliations` (not a
  dedicated response DTO) — see
  `med-super/docs/backend_frontend_parity_matrix.md`. Verify before
  pointing at a real backend.
- Availability (`GET /v1/doctors/{doctorId}/slots`) — added 2026-08-14,
  matches the real, tested backend Phase 3 contract exactly (verified
  against `GetDoctorSlotsUseCase`'s response shape). No hold/booking
  affordance (Phase 4 doesn't exist). Timezone conversion is a fixed
  `Africa/Cairo` (+2:00) offset, not a general IANA converter — no
  timezone/tzdata package exists in `pubspec.yaml`; any other
  `ianaTimezone` value falls back to a UTC-labeled display rather than
  silently mislabeling it. See
  `lib/features/provider_profile/domain/utils/slot_grouping.dart`.
- `clinicBranchId`/`ianaTimezone` on `DoctorProfile` are currently
  mock-only fields (`branch-{doctorId}` / `'Africa/Cairo'`) standing in for
  what the real doctor-detail response should expose once its wire format
  is confirmed.

**Do not build:** appointment hold/confirm/cancel on top of these slots —
Phase 4 doesn't exist yet.

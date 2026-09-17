# Feature status: appointments

**Label:** `PARTIAL` — data layer is `BACKEND_READY` for all six Phase 4
operations; UI covers all six: hold → confirm, list → cancel, list →
reschedule → confirm, and list/card tap → detail. Reschedule's slot-picker
only works when the appointment's `doctorClinicAffiliationId` happens to
follow the mock naming convention — see "Known gaps" below.

## What's real

Matches `clinic-reservations` Phase 4 (File 10 §2.3 / File 12 Part 35)
exactly — built against the actual backend contracts, verified server-side
by that phase's own test suite (97/97 tests, incl. concurrency), not
guessed shapes:

- `POST /v1/appointments/hold` — `CreateHoldUseCase`, wired to
  `BookingConfirmScreen` (auto-holds on screen entry, 5-minute countdown).
- `POST /v1/appointments/{holdId}/confirm` — `ConfirmAppointmentUseCase`,
  now sends the method the patient picked rather than a hardcoded
  `PAY_AT_CLINIC`. Both synchronous methods are wired:
  `PAY_AT_CLINIC` and `INTERNAL_WALLET` (File 12 Part 50.4 — debits the
  wallet inside the same transaction that confirms the appointment).
- `POST /v1/appointments/{holdId}/payments` — `InitiateOnlinePaymentUseCase`,
  wired for **`FAWRY` only**. Returns a reference code the patient pays at
  an outlet; the hold is extended to 15 minutes and the appointment is
  confirmed later by the gateway webhook, never by the client
  (`FawryPaymentScreen` is therefore terminal and has no "I've paid"
  button).
- `POST /v1/appointments/{id}/cancel` — `CancelAppointmentUseCase`, wired
  to `PatientAppointmentsScreen`'s cancel button. `feeApplied`/
  `refundAmount` are always `0` server-side (Part 35.7) — nothing to
  display beyond the cancellation succeeding.
- `POST /v1/appointments/{id}/reschedule` — `RescheduleAppointmentUseCase`,
  wired to `RescheduleScreen` (a day/slot picker, entered from
  `PatientAppointmentsScreen`'s "Reschedule" button on confirmed
  appointments). Returns a fresh hold the caller must still confirm (Part
  35.10) — handled by reusing `BookingConfirmScreen` with its new
  `initialHold` param, which skips the auto-hold step and goes straight to
  the countdown/confirm UI.
- `GET /v1/appointments` — `ListMyAppointmentsUseCase`, wired to
  `PatientAppointmentsScreen`. **Cursor pagination not surfaced** — only
  the first page renders; `nextCursor` is silently dropped. Fine for the
  seed data volume, not for a patient with many appointments.
- `GET /v1/appointments/{id}` — `GetAppointmentUseCase`, wired to
  `AppointmentDetailScreen` (tap a card in `PatientAppointmentsScreen`).
  Shows exactly what the response has — status, times, cancelled reason,
  rescheduled-from link — plus the same reschedule/cancel actions as the
  list card, since the detail response carries no doctor name/specialty
  either.

## Mock coverage

`registerAppointmentMocks` (`mock_responses.dart`) implements all six
operations in-memory so the whole loop is testable in the default
mock-mode dev flow, not only against a live backend. One deliberate
simplification: mock holds never expire (no background sweep to fake) — do
not use the mock to test hold-expiry UX; that's exercised server-side.

The mock also covers both new payment paths. `INTERNAL_WALLET` debits the
shared `_MockWalletStore` (a flat `_kMockConsultFee`, since the confirm
request carries no fee) and refuses on an insufficient balance without
consuming the hold, mirroring the real rollback. The Fawry mock returns a
reference code but never books the slot — nothing simulates the webhook —
so a mock Fawry booking correctly never appears in "My Appointments".
`_MockHold` now carries `doctorClinicAffiliationId` through hold → confirm
(previously hardcoded to `'mock-affiliation'` regardless of which doctor
was actually booked) — needed so a mock appointment's affiliationId still
resolves to the right doctorId for the reschedule slot-picker above.

## Payment methods

`BookingConfirmScreen` shows a three-way picker. The wallet tile reads the
real balance (`GET /v1/wallet`) and locks itself when it can't cover the
fee — the backend would otherwise reject the confirm with
`INSUFFICIENT_WALLET_BALANCE` *after* the hold was already spent.

**`CARD` and `MOBILE_WALLET` are deliberately absent** even though the
backend supports both. Each returns a Paymob checkout URL that needs an
in-app browser, and the app has no `webview_flutter`/`url_launcher`
dependency (see `wallet/STATUS.md`). Fawry is the one online method that
needs none, which is why it's the only one here. Adding the browser is
what unblocks the other two; `AppointmentPaymentMethod` is where they'd be
added.

Note the gateway itself is not provisioned yet — `PAYMOB_*` env vars are
optional backend-side and every gateway call throws
`PAYMENT_GATEWAY_NOT_CONFIGURED` until credentials exist (`DEC-001`). So
Fawry is contract-complete but will not produce a real code against
today's backend; pay-at-clinic and wallet are unaffected.

## Known gaps

- **Booking is gated on `DoctorProfile.affiliationId`**, which is
  currently only populated by mocks (`affiliation-{doctorId}`) or a
  best-effort parse of the real `{doctor, affiliations}` shape that has
  never been verified against a live backend (see
  `provider_profile/STATUS.md`). Against an unreconciled real backend,
  "Book Now" stays disabled rather than sending a request that 404s.
- **Reschedule's slot-picker has the same class of gap, one level worse.**
  `AppointmentSummary` (`GET /v1/appointments`, Part 35.17) only carries
  `doctorClinicAffiliationId` — no doctorId, no doctor name. But the real
  Phase 3 slots endpoint is doctorId-keyed
  (`GET /v1/doctors/{doctorId}/slots`, see
  `get-doctor-slots.use-case.ts`'s `resolveAffiliation`) — there is no
  affiliationId-keyed equivalent on the backend today. `RescheduleScreen`
  recovers a doctorId by parsing the mock catalog's `affiliation-{doctorId}`
  naming convention (`_mockOnlyDoctorIdFromAffiliation`, clearly commented
  as mock-only); against a real backend's opaque UUID affiliation ids this
  always fails and the screen shows a "can't reschedule from here yet"
  message instead of guessing. Fixing this for real needs either a new
  backend endpoint (slots-by-affiliation) or the appointment response
  gaining a doctorId field — a backend contract change, out of frontend
  scope.
- **No branch/doctor-staff surfaces** — everything here is patient-only,
  matching the backend's own Phase 4 scope (File 12 Part 35.8/35.14).
- **`EnvelopeInterceptor`** (`core/network/interceptors/`) was added
  alongside this feature — it wasn't specific to appointments, but nothing
  calling a real backend endpoint worked before it existed (the backend's
  global `{success,data,...}` envelope was never stripped anywhere). Any
  future real-backend integration work should assume this is now handled,
  not re-add per-datasource unwrapping.

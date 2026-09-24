# Feature status: provider_dashboard

**Label:** `PARTIAL` — profile, clinics, availability, appointments, the
patient list (derived from real appointment data), and the in-app
notifications inbox (`lib/features/notifications/`) are backed by real
endpoints.

Was `MOCKED` until 2026-09-04. See `clinic-reservations` File 12 **Part 49**
and `clinic-reservations/docs/DOCTOR_DASHBOARD_ARCHITECTURE.md`.

## Architecture: approved (2026-08-14)

`ADR-006-PROVIDER-SURFACE-SPLIT.md` resolves `ADR-003` (previously
OPEN/unresolved): the doctor-facing dashboard stays in Flutter, scoped to
appointments, profile, schedule, and related doctor/provider transactions.

**Do not expand this feature into pharmacy or laboratory dashboard scope**
— those are a separate Next.js web application per `ADR-006`, not Flutter,
regardless of how similar the UI pattern might look.

## Backend: real as of 2026-09-04

Every route below exists in `clinic-reservations` and is exercised by
`test/doctor-dashboard.e2e-spec.ts` (47 tests against a real Postgres).

| Area | Endpoint | Notes |
|---|---|---|
| Profile | `GET`/`PATCH /v1/doctors/me` | `bio`/`degree`/`experienceYears` only (Part 45) |
| Account | `GET`/`PATCH /v1/auth/me` | name/email live on `User`, not `Doctor` |
| Clinics | `GET /v1/doctors/me/clinics` | list of affiliations, not one clinic |
| Branch | `PATCH /v1/doctors/me/clinics/branches/{id}` | phone, timezone, street, city |
| Affiliation | `PATCH /v1/doctors/me/clinics/affiliations/{id}` | `ACTIVE`/`PAUSED` |
| Availability | `GET/POST/PATCH/DELETE /v1/doctors/me/schedule-templates` | optimistic-locked |
| Appointments | `GET /v1/doctors/me/appointments[/{id}]` | filters + cursor paging |
| Visit status | `PATCH /v1/doctors/me/appointments/{id}/visit-status` | `DOCTOR`/`CLINIC_STAFF`; requires the last-read `version`; only `WAITING → IN_DOCTOR_ROOM → LEFT` |
| Cancel | `POST /v1/doctors/me/appointments/{id}/cancel` | `PROVIDER_REQUEST`, full refund |
| Reschedule | `POST /v1/doctors/me/appointments/{id}/reschedule` | completes in one transaction |
| Walk-in booking | `POST /v1/doctors/me/appointments/branch/{clinicBranchId}/create` | DOCTOR or CLINIC_STAFF; `{patientId}` or `{patientPhone, patientName?}` + `slotId` |

## Provider prescription and lab images — 2026-09-23

Provider-created clinical documents use the same multipart image-upload
pipeline as patient uploads, replacing the former structured medication/test
entry form. The UI sends patient/appointment scope and document purpose to
`POST /v1/prescriptions/provider/upload`. Assistant prescriptions remain
drafts for physician approval; only signed prescriptions can be submitted to
the existing `POST /v1/pharmacy-orders/provider` queue. Lab referrals link the
uploaded document to `POST /v1/lab-orders/provider`, feeding the existing
branch queue. Provider history displays persisted private image URLs.
Multi-patient mode requires a separate image set and independent request per
patient; it does not create one shared clinical record.

Focused DTO/widget tests and static analysis passed on 2026-09-23. Live
backend/device verification remains pending.

## Pharmacy submission and quote visibility — 2026-09-24

For doctors, the prescription form now gathers the pharmacy branch and
fulfillment method together with the document. A pending assistant
prescription uses the same sheet when the doctor approves it, so sign-off and
queue submission are one user action while remaining two existing server
writes. If queue submission fails after sign-off, the signed prescription is
retained and can be sent again; the UI does not imply an atomic backend
transaction that does not exist.

The provider history now shows the pharmacy's server-returned fulfillment
status, quoted total, pharmacist note, and a collection reminder. Pharmacy
staff remain the only actor that can price or progress the pharmacy order;
the provider view is intentionally read-only for those fields.

The provider lab-request sheet now groups collection method, eligible lab
branch, attachments, and notes in that order. Selecting home collection
filters to branches that advertise that capability; it does not infer an
address, price, or test catalogue that the backend does not provide.

## Clinic delivery and OCR placeholder cleanup — 2026-09-24

Legacy `[DEV PLACEHOLDER]` item names are hidden in provider prescription
cards; when the no-op OCR service has no vendor configured, new uploads retain
the prescription image without fabricating medication rows. Clinic fulfillment
is labeled as delivery to the clinic and, like home delivery, requires a
delivery-capable pharmacy branch and follows the delivery-in-progress status.
The backend still has no courier integration or persisted clinic destination,
so it cannot route a courier to a specific clinic address yet.

## Doctor and assistant surface polish — 2026-09-24

The shared provider dashboard now distinguishes the assistant's clinic
schedule from the doctor's schedule and uses the active locale for calendar
weekday/month labels. Calendar navigation has localized accessible labels and
48px interaction targets. Provider navigation, notification, profile, and
calendar controls expose clearer semantics and touch feedback.

The profile is localized and role-aware: assistants see their own session
identity and assigned-branch workspace links, and the screen no longer reads
the supervising doctor's account as the assistant's profile. Clinical request
history displays the scoped patient context; assistant prescription drafts
explain that physician approval is required, while sign-off remains doctor-only.

Focused widget tests passed **12/12** across provider home, profile, and
clinical requests. Changed-file analysis completed with **8 info-level lint
notices** (primarily radio-control deprecations and style hints); no errors
were reported for the selected files. Arabic/English localization key sets
are symmetric. Live backend and device verification remain pending.

## Visit-status verification: 2026-09-18

### Scheduling guard update: 2026-09-18

The provider UI and backend now share a named 30-minute early-arrival policy:
the next visit action is available only from 30 minutes before the current
appointment slot's UTC `startAt` through its `endAt`. The Flutter action policy
compares instants in UTC and hides the next-action control with localized
guidance when too early or outside the window; the backend independently
returns `VISIT_STATUS_TOO_EARLY` or `VISIT_STATUS_OUTSIDE_APPOINTMENT_WINDOW`.
After a reschedule, the new appointment row and its new slot are the only
schedule used by either layer. `IN_DOCTOR_ROOM` and `LEFT` still hide cancel
and reschedule, while the server rejects stale attempts with
`APPOINTMENT_VISIT_IN_PROGRESS` and the client maps it to provider-facing
Arabic/English copy.

Focused domain, failure-mapping, and detail-widget tests cover timing, the
forward state machine, booking lock, current-slot reschedule behavior, and
localized server feedback. Device/browser manual verification remains pending.

The Flutter queue/detail DTO, repository, use case, generated Riverpod
provider, localized badge, and single-step action call the route above with
`{status, version}`. A successful response replaces the displayed
appointment, so the next action uses the server-returned version.

- **Verified backend contract:** local Docker PostgreSQL and Redis were up;
  Prisma reported no pending migrations; `npm run build` completed; and the
  focused `UpdateAppointmentVisitStatusUseCase` suite passed 5/5, covering
  forward transitions, invalid transitions, non-confirmed appointments,
  assistant branch scope, and stale versions.
- **Focused HTTP coverage added:** `test/provider-assistants.e2e-spec.ts`
  now asserts the successful two-step progression, a `409
  OPTIMISTIC_LOCK_CONFLICT` after a valid stale version, and a `404
  RESOURCE_NOT_FOUND` for another doctor's appointment. The first live run
  exposed that `version: 0` is validation-invalid (`400`), not stale; the
  test now uses version `1` after the first update, which is the real stale
  client case. The corrected suite passed **32/32** against real PostgreSQL.
- **Still unverified in this environment:** Flutter `build_runner` and the
  focused widget suite stalled without diagnostic output, and Flutter device
  discovery did not return a runnable target. The generated provider is
  present in source, but a browser/emulator run with
  `--dart-define=BASE_URL=http://localhost:3000` remains required before
  claiming live-dashboard verification.

### What changed, and why the old shapes were wrong

* **`Appointment` → `DoctorAppointment`.** The old entity carried `medId` and
  `locationStatus`, neither of which exists in any table, and a `pending`
  status that the backend has no concept of. An appointment row is only
  created at *confirm* time, already `CONFIRMED` — so the accept/reject queue
  was modelling a state that never occurs. The doctor's real actions are
  **cancel** and **reschedule**.
* **`ClinicSettings` → `DoctorClinic[]`.** The old shape was one hardcoded
  clinic with an `email` field no clinic or branch table has. A doctor can
  practise at several branches, so this is a list.
* **`{working_days: [...]}` → `DoctorScheduleTemplate[]`.** The old blob could
  not express which branch a plan belongs to, the slot length, the buffer, or
  the timezone the times are in — all of which the real contract requires.
* **`createAppointment` removed.** A doctor cannot create an appointment;
  only a patient can, via hold → confirm. The FAB that pretended otherwise is
  gone rather than left to 404.
* **`UploadAvatarUseCase` removed.** Dead code pointing at
  `/v1/provider/avatar`, which no screen called and no backend serves.

* **`Patient` redefined, `/v1/provider/patients` removed.** There is no
  "patients" module or endpoint at all — the old mock entity's `medId` and
  free-text `status` never existed anywhere real. `Patient` is now derived
  purely from `GET /v1/doctors/me/appointments`
  (`GetProviderPatientsUseCase`, `providerPatientsProvider`): it pages
  through the doctor's own appointments over a ±90-day window (mirroring
  `ProviderPatientDetailScreen`'s existing fallback bound), dedupes by
  `patientId`, and keeps only `patientId`/`patientName`/`patientPhone` plus
  computed `lastAppointmentAt`/`nextAppointmentAt`.

Avatar upload stays unavailable (`DEC-009`, no object-storage decision); the
UI shows a "coming soon" message rather than faking an upload. Password
change should go through `POST /v1/auth/password/set`, not the invented
`/v1/provider/change-password` — that screen has not been rewired yet.

## Known gaps in this feature

1. **Times render in the device zone, not the branch zone.** Every response
   carries `ianaTimezone` and the UI always displays it next to the time, so
   a reading is never ambiguous — but the app bundles no tz database, so a
   doctor whose phone is in a different zone from the clinic sees their own
   local time. Fixing this properly needs a `timezone` package dependency.
2. **The reschedule picker depends on `GET /v1/doctors/{doctorId}/slots`,**
   which applies the Part 32 visibility chain for non-Admin callers. A doctor
   whose own branch is not `VERIFIED` therefore sees an empty slot list —
   correct in effect (no slots are generated for such a branch anyway), but
   it reads as "no availability" rather than "branch not verified".
3. **`provider_home_screen`'s calendar is still generated mock data**
   (`provider_calendar_providers.dart`). It was left alone this pass: it is a
   day-grid over slots, and the real slot source is the patient-facing
   `/slots` endpoint rather than anything in this feature's contract.
4. **Localization.** New strings all go through `provider_dashboard.*` in
   `en.json`/`ar.json`. The feature's pre-existing ~25 hardcoded Arabic
   strings are still there — known debt, not a pattern to extend.

## Separately unresolved: role gating

The two-flavor (patient/provider) build separation was deleted in the same
branch that built this feature. Role gating is a single client-trusted
boolean with no build-time isolation. `ADR-006` does not address this — it is
a separate, still-open concern, and the backend is what actually enforces
access. Don't treat "the surface is approved" as "the security model is
settled."

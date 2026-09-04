# Feature status: provider_dashboard

**Label:** `PARTIAL` — profile, clinics, availability, appointments and the
patient list (derived from real appointment data) are backed by real
endpoints; only notifications is still mock-only.

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
| Cancel | `POST /v1/doctors/me/appointments/{id}/cancel` | `PROVIDER_REQUEST`, full refund |
| Reschedule | `POST /v1/doctors/me/appointments/{id}/reschedule` | completes in one transaction |
| Walk-in booking | `POST /v1/doctors/me/appointments/branch/{clinicBranchId}/create` | DOCTOR or CLINIC_STAFF; `{patientId}` or `{patientPhone, patientName?}` + `slotId` |

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

### Still mock-only (no backend route exists)

`/v1/provider/notifications`. Notifications is Phase 8 and unbuilt.
`provider_notifications_screen` is honest about being a demo surface — do
not present it as backend-ready.

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

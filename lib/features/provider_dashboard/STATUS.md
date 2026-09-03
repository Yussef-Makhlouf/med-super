# Feature status: provider_dashboard

**Label:** `MOCKED` — architecture approved, backend not ready

## Architecture: approved (2026-08-14)

`ADR-006-PROVIDER-SURFACE-SPLIT.md` resolves `ADR-003` (previously
OPEN/unresolved): the doctor-facing dashboard stays in Flutter, scoped to
appointments, profile, schedule, and related doctor/provider transactions.
This feature's existing scope (appointments queue, patient list/detail,
notifications, profile, clinic settings, schedule editor, security/privacy)
fits entirely within that approval. **It is no longer `BLOCKED` on
architecture grounds.**

**Do not expand this feature into pharmacy or laboratory dashboard scope**
— those are a separate Next.js web application per `ADR-006`, not Flutter,
regardless of how similar the UI pattern might look.

## Backend: still not ready, with one exception (2026-08-31)

Architecture approval does not mean the data layer is production-ready.
Every endpoint this feature calls (`/v1/provider/appointments`, `/patients`,
`/notifications`, `/clinic-settings`, `/schedule`, `/change-password`,
`/avatar`) is **mock-only and frontend-invented** — none exist on the real
backend, even though the *patient-facing* Phase 4 (Appointments) module
itself is now complete (see `lib/features/appointments/`); there is still
no backend module for a "provider dashboard" at all
(`09_DASHBOARDS.md`: dashboards are clients over domain modules, not a
module of their own). Treat every one of these as subject to change once
whatever backend work a real provider-dashboard data layer needs actually
exists. Do not present any of this as backend-complete.

**Exception: `getDoctorAccount`/`updateDoctorAccount` (`ProviderProfileScreen`/
`ProviderEditProfileScreen`) now call the real `GET`/`PATCH /v1/doctors/me`**
(`clinic-reservations` File 12 Part 45), replacing the invented
`/v1/provider/me`. Audited against `Prisma.Doctor`'s real columns:
`bio`/`degree`/`experienceYears` are genuinely editable; `phone` is shown
read-only (no endpoint changes it post-signup, same as the patient side);
`email` lives on `User` not `Doctor`, so it's editable through the shared
`PATCH /v1/auth/me` instead (sent alongside the doctor-specific update, not
part of it) — already collected for real at doctor registration time
(`doctor_registration_basic_info_screen.dart`), this closes the loop so it
can be seen/changed afterward too. `name` also lives on `User`, but stays
read-only here (unlike email) since editing it wasn't asked for; an
assistant's own name still goes through that same shared call, since an
assistant is a `CLINIC_STAFF` `User` with no `Doctor` row at all.
`specialty`/`licenseNumber` are Admin-only (shown read-only). `hospitalName`
was dropped from `DoctorAccountProfile` — no clinic-affiliation join exists
in the real endpoint's response, so it had nothing to be backed by. Avatar
upload (`/v1/provider/avatar`) stays exactly as unreal as the rest of this
list — no object-storage decision exists yet (`DEC-009`) — but the UI no
longer pretends otherwise: tapping the avatar now shows a plain "coming
soon" message instead of running a fake upload round trip.

## Separately unresolved: role gating

The two-flavor (patient/provider) build separation was deleted in the same
branch that built this feature (`lib/app/flavor.dart`,
`lib/app/router/route_guards.dart`, `lib/main_provider.dart` — see
`med-super/docs/backend_frontend_parity_matrix.md`, finding D7). Role
gating is currently a single client-trusted boolean with no build-time
isolation. `ADR-006` does not address this — it's a separate, still-open
concern. Don't treat "the surface is approved" as "the security model is
settled."

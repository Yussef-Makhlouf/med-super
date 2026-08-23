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

## Backend: still not ready

Architecture approval does not mean the data layer is production-ready.
Every endpoint this feature calls (`/v1/provider/appointments`, `/patients`,
`/notifications`, `/me`, `/clinic-settings`, `/schedule`,
`/change-password`, `/avatar`) is **mock-only and frontend-invented** — none
exist on the real backend. Backend Phase 4 (Appointments) has not started;
there is no backend module for a "provider dashboard" at all yet
(`09_DASHBOARDS.md`: dashboards are clients over domain modules, not a
module of their own). Treat every one of these 13 endpoints as subject to
change once Phase 4 — and whatever backend work a real provider-dashboard
data layer needs — actually exists. Do not present any of this as
backend-complete.

## Separately unresolved: role gating

The two-flavor (patient/provider) build separation was deleted in the same
branch that built this feature (`lib/app/flavor.dart`,
`lib/app/router/route_guards.dart`, `lib/main_provider.dart` — see
`med-super/docs/backend_frontend_parity_matrix.md`, finding D7). Role
gating is currently a single client-trusted boolean with no build-time
isolation. `ADR-006` does not address this — it's a separate, still-open
concern. Don't treat "the surface is approved" as "the security model is
settled."

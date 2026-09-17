# Backend ↔ Frontend Parity Matrix

**Repos audited:**
- Backend — `E:\health-care\clinic-reservations` (NestJS + Prisma + TypeScript modular monolith)
- Frontend — `E:\health-care\med-super` (Flutter, Clean Architecture + Riverpod 3)

**Authoritative sources used:**
- `MedSuper_Docs_Reorganization/docs/` (`00_START_HERE.md`, `02_CURRENT_STATE.md`, `03_ROADMAP.md`, `05_API_RULES.md`, `06_DATA_MODEL.md`, `07_AUTH_RBAC.md`, `08_WORKFLOWS.md`, `09_DASHBOARDS.md`, `phases/PHASE_03_AVAILABILITY.md`)
- `MedSuper_Flutter_Documentation_Pack/` (`02_CURRENT_STATE.md`, `03_ROADMAP.md`, `04_API_CONTRACT.md`, `06_RBAC_AND_ROLE_CONTEXT.md`, `07_NAVIGATION.md`, `11_FEATURE_MAP.md`, `13_STATE_AND_FAILURES.md`, `adr/ADR-001..004`, `phases/PHASE_03_AVAILABILITY.md`)
- `clinic-reservations/docs/FILE_10/11/12` (implementation-grade backend authority)
- Direct code inspection: `src/app.module.ts`, all `*.controller.ts`, `prisma/schema/*.prisma`, `lib/features/**`, `lib/app/router/**`, `lib/core/network/**`, git history/branches on both repos
- **Explicitly rejected as authoritative:** `E:\health-care\analysis_results.md` (repo-root, undated-authority doc) — it contradicts the phase-3 scope docs and contains a wrong hold-TTL value; see Gaps §D10.

**Method:** docs read first to establish the authority baseline, then every claim was checked against running code (controllers, modules, git log, route tables, interceptors) rather than trusted at face value. Where docs and code disagreed, code + git history won as ground truth for "what exists," while docs remained authoritative for "what is *allowed* to exist."

---

## Session Update — 2026-09-04 (Doctor Self-Service: Documents + Working Hours)

This document predates Phases 4–7 (see `docs/backend_api_reference_2026-08-25.html` for the current endpoint catalog and wiring badges) and is kept here only for its still-relevant provider-registration/contracts history — treat everything below this entry and above 2026-08-14 as a dated snapshot, not current state.

- ✅ **FIXED (backend, `clinic-reservations` branch `feature/doctor-self-service-registration`)** — `POST /v1/provider-verification-documents` was Admin-only end to end; a `DOCTOR` caller can now upload a verification document for their own doctor record (ownership enforced in `UploadVerificationDocumentUseCase`, not just the route guard). List/approve/reject remain Admin-only, unchanged.
- ✅ **FIXED (backend, same branch)** — `working_days` submitted during `POST /v1/provider/registration` was accepted and silently discarded (`SELF_REGISTRATION_NOT_PERSISTED_FIELDS`). It now persists as real `ScheduleTemplate` rows tied to the new `DoctorClinicAffiliation`, using the same `{weekday, startTime, endTime, slotDurationMinutes, bufferMinutes}` shape `POST /v1/schedule-templates` already validates against.
- ✅ **FIXED (backend, same branch)** — `tsconfig.json`'s `ignoreDeprecations: "6.0"` was invalid for the installed TypeScript 5.9.3, failing `npm run build` outright (pre-existing, introduced in the earlier "ImageKit Integration" commit). Corrected to `"5.0"`.
- ✅ **FIXED (frontend, `med-super` branch `feature/doctor-self-service-registration`)** — `provider_registration`'s document pickers previously discarded file bytes (`withData: false`, mock-only app) and its `working_days` payload used an invented `{day, is_enabled, from, to}` shape the backend never validated against. Now: file bytes are kept (`UploadedDocument.bytes`), `POST /v1/provider/registration`'s response `doctorId` is read back, and each picked document uploads for real via the new `ProviderRegistrationRemoteDatasource.uploadVerificationDocument` right after submission succeeds; `working_days` now sends the ISO-weekday/`HH:mm` shape the backend expects. No slot-duration/buffer picker UI exists yet — every submitted day defaults to a 30-minute slot, 0 buffer.
- ✅ **FIXED (backend, same branch)** — Express's JSON body-parser limit defaulted to 100kb, far too small for `photo_data_uri` (a base64-encoded photo, up to `MEDIA_CONSTANTS.MAX_IMAGE_SIZE_BYTES` before encoding). Any real photo triggered a `PayloadTooLargeError` before ever reaching Nest's routing, surfaced to the client as an opaque `500` instead of a real `413`. Reproduced live and fixed in `src/main.ts` by raising the limit past the max encoded size.
- ✅ **FIXED (frontend, same branch)** — the working-hours "From"/"To" time pickers saved whatever was picked with no validation; a reversed window (From after To) reached the backend untouched and failed with `422 INVALID_SCHEDULE_WINDOW` only after the entire multi-step form was filled and submitted. Now validated immediately at pick time with a clear inline message, before it's ever saved to the draft.
- ✅ **FIXED (frontend, same branch)** — a real cross-account data leak: the in-progress registration draft (`RegistrationFormController`, Hive-persisted) was cleared on explicit `logout()`, but a session that ended without calling `logout()` (app killed/closed mid-registration, a crash) left it on disk with no owner recorded. The next login on the same device — even a completely different phone number — inherited that half-filled draft (name, email, license number, documents) untouched, since neither `verifyOtp` nor `loginWithPassword` ever touched it. Reported live and reproduced. The draft is now tagged with an `owner_user_id` and discarded on login if it belongs to a different account (`SessionController._claimRegistrationDraft`).
- ✅ **FIXED (frontend, same branch)** — `ProviderPageHeader` (the shared app-bar used by all 5 `provider_dashboard` screens) has always accepted an `avatarUrl` param and shown the real photo when set, but no call site ever passed one — including `provider_profile_screen.dart`, which already computed `avatarUrl` for its own large avatar but never forwarded it to the header. The doctor's photo now reaches every dashboard header. The header avatar's fallback style (radius/colors/icon) was also changed to visually match the patient home header's avatar exactly, per an explicit design request — no functional change to the image-vs-icon logic.
- ✅ **FIXED (frontend, same branch)** — 3 pre-existing, unrelated test failures (`lab_schedule_edit_modal_test.dart`, `clinic_branch_details_screen_test.dart`, `pharmacy_branch_details_screen_test.dart`) were asserting raw strings that never matched what the widgets actually render — one used the wrong locale (`'en'` vs the test shell's actual `'ar'` default) for a formatted time label, two didn't account for `AppFormatters.ltrIsolate`'s bidi-isolate marks around a phone number. Full suite is now 502/502 passing.
- **NOT DONE** — no UI exists yet to let the doctor choose `slotDurationMinutes`/`bufferMinutes` per working day; a fixed default is used until that's designed. Document upload failures after a successful registration are swallowed (best-effort) rather than surfaced to the user — see `ProviderRegistrationRepositoryImpl.submit`'s doc comment for the reasoning.

---

## Session Update — 2026-08-14 (Alignment Pass)

An alignment pass fixed the items marked ✅ **FIXED** below, within the "align now" scope (auth, search, availability, docs). Items marked **BLOCKED (unchanged)** were deliberately left frozen — fixing them requires a product/architecture decision this pass didn't have standing to make, not more engineering.

- ✅ **FIXED** — Search path mismatch (D1): `ApiPaths.searchDoctors` now `/v1/doctors/search`; mock registration order fixed to match (was a real, undiscovered bug the path fix would have exposed — see `mock_responses.dart`'s ordering comment).
- ✅ **FIXED** — Search contract completeness (D2): `cursor`/`limit`/`date`/`latitude`/`longitude`/`radiusKm` now plumbed through datasource/repository/use-case; mock honors `cursor`/`limit` and returns `next_cursor`. No "load more" UI added — out of scope for a contract fix.
- ✅ **FIXED** — Interceptor order + mock-mode gap (D3/D4): `dio_client.dart` now runs Correlation-ID → Auth → Idempotency → (Mock) → Logging → Error → Retry, matching `04_API_CONTRACT.md`, and Correlation-ID/Idempotency/Retry are no longer skipped in default dev mode.
- ✅ **NEW** — Availability/slots (previously frontend gap, no ID): real `GET /v1/doctors/{doctorId}/slots` now consumed in `provider_profile`'s doctor-detail screen, replacing the old fully-fake `available_days`. Timezone handling is a flagged, fixed `Africa/Cairo` offset (no tzdata package exists) — see `lib/features/provider_profile/domain/utils/slot_grouping.dart`.
- ✅ **NEW** — Provider self-registration backend (see below, unchanged from prior session): real endpoint now exists per `ADR-005`; frontend still needs `license_number`/`region_code` fields added.
- ✅ **FIXED** — `med-super/CLAUDE.md` (D9): rewritten to reflect the single-entry-point architecture, real test directory, per-feature `STATUS.md` convention, and the ADR-003/flavor-deletion gap.
- ✅ **FIXED** — Dead code: `profile_placeholder_screen.dart`/`search_placeholder_screen.dart` deleted (confirmed zero references). `appointmentRoutes`, `OutboxBox`, `CachePolicy`, `IdempotencyKeyInterceptor`'s path list now carry explicit "why this is currently inert" doc comments instead of being unexplained.
- ✅ **NEW** — Every `lib/features/*/STATUS.md` now exists, applying the Flutter roadmap's own `DESIGN_ONLY`/`MOCKED`/`PARTIAL`/`BACKEND_READY`/`BLOCKED` labels (D8) — `lab_booking` and `provider_dashboard` are explicitly marked `BLOCKED` with the governing doc quoted.
- **BLOCKED (unchanged)** — `lab_booking` (D5): still requires a product/architecture decision (Laboratory backend un-deferral), not code.
- **✅ RESOLVED 2026-08-14** — `provider_dashboard` (D6): the product/engineering owner issued `ADR-006-PROVIDER-SURFACE-SPLIT.md`, superseding `ADR-003`. Doctor dashboard is now an **approved surface in Flutter** (scoped to appointments/profile/schedule/provider transactions); pharmacy and laboratory *staff* dashboards are routed to a separate Next.js app instead. `provider_dashboard`'s architecture is unblocked, but its 13 endpoints remain entirely mock-only (backend Phase 4 doesn't exist) — relabeled `MOCKED`, not `BACKEND_READY`. See `lib/features/provider_dashboard/STATUS.md`.
- **STILL OPEN, unaffected by ADR-006** — two-flavor deletion (D7): role gating is a presentation-layer *authorization* question, distinct from *which surface hosts the dashboard*. `ADR-006` is silent on it.
- **BLOCKER (unchanged, backend repo)** — D13 (backend build break) was reported as failing in the prior pass; re-verified during this pass and **the build currently passes** (`npm run build` exit 0, 54/54 unit tests green). Likely already fixed between passes, or the prior failure was transient — flagging the discrepancy rather than silently updating the historical finding. D12 (identity-auth has zero unit tests) is unchanged — out of frontend-alignment scope for this pass.
- **NOT DONE** — D10/D11/D14/D15, and backend D12/D13 follow-up: no code risk/benefit to touching them in this pass; left as reported.

---

## Executive Summary

- **Backend is legitimately mid-Phase-3** (Availability). `scheduling-appointments` is a real, tested, 26-file module — not the scaffold the stale root analysis claims. It correctly does **not** contain any Phase-4 (hold/confirm/cancel) logic. However, **the backend does not currently compile** (`npm run build` fails) — nothing backend-side should be treated as "done" until that's fixed.
- **Frontend phase is far more advanced in UI surface area than the docs know about.** Four large feature branches merged in the last four days: doctor registration, full lab-booking, full pharmacy-booking, and a 12-screen provider dashboard "complete to 100% (mock-only)". The Flutter docs' own `02_CURRENT_STATE.md` still says frontend status is "UNKNOWN" — it is not; this document replaces that gap.
- **Two of those four branches are explicit doc violations, not just drift:** Laboratory is marked "Deferred — do not implement" in the Flutter feature map, and the provider dashboard was built out from under an `ADR-003` decision that is still explicitly OPEN/unresolved and says not to expand provider Flutter scope.
- ~~**A live contract break already exists:** the frontend calls `GET /v1/search/doctors`; the real backend route is `GET /v1/doctors/search`.~~ **Fixed in the 2026-08-14 alignment pass** — see Session Update above.
- **The two-flavor (patient/provider) build was deleted** in the same branch that expanded provider scope — `flavor.dart`, `route_guards.dart`, and `main_provider.dart` are gone; there is one entry point now, gated only by a client-trusted role string. `CLAUDE.md` still documents the deleted architecture.
- **Test investment is inverted relative to production risk**: the four newest, most speculative, mock-only features have full test coverage; `auth`, `search_discovery`, `home`, and `profile_settings` — the features nearest to touching a real backend — have none.

---

## Current Truth

### Backend — `clinic-reservations`

| Phase | Doc status | Verified code reality |
|---|---|---|
| 0 — Foundation | COMPLETE | Confirmed. Guards, correlation ID, Pino logging, response envelopes, Redis idempotency, transactional outbox, Prisma/Redis kernels all wired in `src/app.module.ts:19-28`. |
| 1 — Identity & Auth | COMPLETE | Endpoints real: `POST /auth/otp/request`, `/otp/verify`, `/token/refresh`, `/logout` (`src/modules/identity-auth/api/identity-auth.controller.ts:20,30,36,42,48`). **Zero `*.spec.ts` files exist for this module** — "complete" is currently unverified by any automated test. |
| 2 — Provider Directory | COMPLETE | Confirmed real: Clinics, Doctors, Pharmacies, Branches, Affiliations, Verification Documents, Specialties — full CRUD + verify/suspend workflow + visibility rules + spatial search. Unit, integration, and e2e tests present. |
| 3 — Availability | **IN PROGRESS — further along than any doc states** | `src/modules/scheduling-appointments/` is a real 26-file, 4-layer module (api/application/domain/infrastructure), registered in `app.module.ts:27`. `GET /v1/doctors/:doctorId/slots` implemented (`doctor-slots.controller.ts:15,20`) with real luxon timezone math incl. an explicit Africa/Cairo unit test, idempotent slot generation (`skipDuplicates`), and a worker-only `@Cron(EVERY_DAY_AT_1AM)` job. 8 spec files + a 12-case e2e spec (`test/scheduling-availability.e2e-spec.ts`). **Phase 3 boundary is respected**: grep for hold/book/confirm/cancel/reschedule across the module returns only doc-comments about future Phase 4 work, zero implemented logic. `AppointmentHold`/`Appointment` exist in `prisma/schema/scheduling.prisma` as schema-only, as intended. |
| 4 — Appointments | NOT STARTED | Confirmed: schema models exist, zero repository/use-case/controller code. |
| 5 Payments / 6 Prescriptions / 7 Pharmacy Fulfillment / 8 Notifications / 9 Delivery | NOT STARTED | Confirmed: each is a single `README.md` under `src/modules/`, no `.ts` files. |
| Laboratory / Reviews / Fraud / Analytics / Family Accounts / EMR | POSTPONED | Confirmed: schema-only in `prisma/schema/postponed.prisma`, one `README.md` each, no module code anywhere. |

**Hold TTL:** correctly `5` minutes — `src/shared/config/constants.ts:19` (`HOLD_TTL_MINUTES: 5`), currently unreferenced anywhere in code (expected, since Phase 4 doesn't exist yet). The `15`-minute figure that appears in `analysis_results.md`'s Phase-3 blueprint does not exist in code and is confirmed wrong.

**Blocking defect:** `npm run build` (`tsc`) **fails today**:
```
src/modules/provider-directory/application/list-schedulable-affiliations.use-case.spec.ts(39,69):
error TS2345: Argument of type '...[]' is not assignable to parameter of type 'never'.
```
This is in the same file the latest commit (`a4ff3e4`, "fix: add missing import statement...") touched — the import was fixed, the type error was not. `tsconfig.json` includes `.spec.ts` files in the build, so this is a genuine, currently-unresolved build break, not a config artifact.

**Full backend endpoint inventory** (method + path, grouped by module):

| Module | Routes |
|---|---|
| `health` | `GET /health/live`, `GET /health/ready` |
| `identity-auth` | `POST /auth/otp/request`, `POST /auth/otp/verify`, `POST /auth/token/refresh`, `POST /auth/logout` |
| `scheduling-appointments` | `POST /schedule-templates`, `GET /schedule-templates`, `PATCH /schedule-templates/:id`, `DELETE /schedule-templates/:id`, `GET /doctors/:doctorId/slots` |
| `provider-directory` | `GET/POST/PATCH /clinics`, `POST /clinics/:id/verify`, `POST /clinics/:id/suspend`, `POST /clinics/:id/branches`; same shape for `pharmacies`; `GET/PATCH /clinic-branches/:id` (+verify/suspend); `GET/PATCH /pharmacy-branches/:id` (+verify/suspend); `GET /doctors/search`, `GET/POST/PATCH /doctors/:id` (+verify/suspend/affiliations); `PATCH /affiliations/:id`; `GET /specialties`; `GET/POST /provider-verification-documents` (+approve/reject) |

Note: `provider-directory`'s `doctors.controller.ts` and `scheduling-appointments`'s `doctor-slots.controller.ts` both declare `@Controller('doctors')` — Nest merges this without conflict since sub-paths differ, but it means scheduling-appointments routes are piggybacking on provider-directory's namespace rather than a clean separate prefix. Not a bug; a maintainability note.

### Frontend — `med-super`

Flutter's own `02_CURRENT_STATE.md` states frontend status is "UNKNOWN — treat as unreported until the Flutter team records it." **It has not been recorded.** This section is that record.

Git history (`dev` branch, all merged): sprint 1 (auth/OTP), sprint 2 (search, doctor detail, patient profile), then four large feature branches, most recent first:

| Branch (merge date) | What it built | Backing |
|---|---|---|
| `feature/doctor-dashboard` (2026-08-14) | 12-screen provider dashboard: home/appointments queue, patient list + detail, notifications, profile, edit-profile, clinic settings, schedule editor, security/privacy. Commit message: "complete the doctor dashboard to 100% (mock-only)". | Real Dio calls to 13 **invented** `/v1/provider/*` endpoints, all `MockInterceptor`-only, persisted to a Hive-backed mock store that survives app restarts. |
| `feature/pharmacy-booking-flow` (2026-08-13) | 4-screen pharmacy order flow: upload prescription → choose pharmacy → review → confirm. | **No network layer of any kind** — hardcoded in-memory pharmacy list behind a fake `Future.delayed`; not even registered with `MockInterceptor`. |
| `feature/lab-booking-flow` (2026-08-13) | Full lab test booking: upload, lab selection, review, confirmation. 34 test files. | Real Dio calls to `/v1/lab-partners`, `/v1/lab-bookings` — `MockInterceptor`-only. |
| `feature/doctor-registration-flow` (2026-08-12) | 4-screen provider self-onboarding: basic info, verification, clinic schedule, review. | Real Dio calls to invented `/v1/provider/registration*` endpoints — `MockInterceptor`-only. |

**Architecturally significant fact buried in the newest branch:** `feature/doctor-dashboard` deleted `lib/app/flavor.dart`, `lib/app/router/route_guards.dart`, and `lib/main_provider.dart`, and renamed `lib/main_patient.dart` → `lib/main.dart`. **The two-flavor (separate patient/provider binary) architecture no longer exists.** There is one entry point today. Patient-vs-provider routing is now gated solely by `session.user.isPatient`/`isProvider` (`lib/app/router/app_router.dart:64-98`), a boolean read from a mock `/v1/auth/me` payload that itself just echoes back whatever `role` string the client declared at OTP-request time (`mock_responses.dart:88`). `android/app/build.gradle.kts` has zero flavor blocks; there is one iOS scheme. `CLAUDE.md`, the architecture doc, and the pubspec description still describe the deleted two-flavor model.

**Test coverage reality:** 71 files under `test/` — 100% concentrated in the four newest branches (`lab_booking`: 34, `pharmacy_booking`: 9, `provider_dashboard`: 7, `provider_registration`: 16, `core` widgets: 3, helpers: 3). **`auth`, `search_discovery`, `home`, `profile_settings`, `provider_profile` have zero tests.**

**`med-super/CLAUDE.md` is untracked and stale**: it documents `main_patient.dart`/`main_provider.dart` flavor entry points (deleted), describes the provider dashboard as "presentation only so far" (it now has a full persisted data layer), and states "there is no `test/` directory yet" (71 files exist). This is the first file any coding session reads for this repo and it is wrong on all three of its most load-bearing claims.

### Contracts audit — routes the frontend actually calls

| Frontend call | Path used | Real backend route | Match? |
|---|---|---|---|
| OTP request | `POST /v1/auth/otp/request` | `POST /auth/otp/request` (+`/v1` global prefix) | ✅ |
| OTP verify | `POST /v1/auth/otp/verify` | `POST /auth/otp/verify` | ✅ |
| Token refresh | `POST /v1/auth/token/refresh` | `POST /auth/token/refresh` | ✅ |
| Logout | `POST /v1/auth/logout` | `POST /auth/logout` | ✅ |
| Current user | `GET/PATCH /v1/auth/me` | Not in the documented/verified backend endpoint list | ⚠️ unverified — not confirmed to exist on backend |
| Doctor search | `GET /v1/search/doctors` (`lib/core/constants/api_paths.dart:14`) | `GET /doctors/search` | ❌ **path mismatch** |
| Doctor detail | `GET /v1/doctors/:id` | `GET /doctors/:id` | ✅ |
| Provider registration | `GET/POST /v1/provider/registration*` | **Now implemented** (`ADR-005`, 2026-08-14) — same paths/body shape | ~~⚠️ path/shape match; form is missing 2 required fields (`license_number`, `region_code`)~~ ✅ **Fixed** — both fields are collected (verification step / clinic-schedule step) and sent. As of 2026-09-04 (`feature/doctor-self-service-registration`) `working_days` and `documents` are also real, persisted, uploaded data, not placeholders — see the 2026-09-04 Session Update above. |
| Lab partners/bookings | `GET /v1/lab-partners`, `POST /v1/lab-bookings` | Does not exist on backend (Laboratory is postponed) | ❌ **frontend-invented** |
| Pharmacy | *(no calls exist)* | Does not exist on backend (Phase 7 not started) | — no contract to break |
| Provider dashboard (appointments/patients/notifications/profile/clinic-settings/schedule/password/avatar) | 13 routes under `/v1/provider/*` | Does not exist on backend | ❌ **frontend-invented, 13 endpoints** |

Search also drops parameters the backend supports and the docs require: no `location`/radius, `date`, `cursor`, or `limit` are sent (`doctor_search_repository_impl.dart:15-30`); no pagination handling exists anywhere in the app. The mock catalog only has 4 doctors, so this has never been exercised.

### Roles / Scopes

- Backend (`07_AUTH_RBAC.md`): fail-closed by default (`@Public()`/`@OptionalAuth()` opt out), `@Roles()`/`@Permissions()`/`@CurrentUser()` primitives, provider scope intended to be constrained to provider/org/branch context, target role categories PATIENT/DOCTOR/CLINIC/PHARMACY/LAB/ADMIN. Explicitly: **"Provider Directory Phase 2 intentionally did not grant role memberships merely because a Provider entity was created. Login-as-provider behavior requires an approved role membership path later"** — i.e. there is currently **no real backend mechanism** for a user to become a "provider" at all.
- Frontend (`06_RBAC_AND_ROLE_CONTEXT.md`): explicitly states **"Flutter is not the authorization authority. Backend authorization is final,"** and "do not hardcode role names across many widgets — centralize role/context interpretation in one auth/session layer."
- Reality: role is a single client-read boolean (`isPatient`/`isProvider`) sourced from a mock `/v1/auth/me` response that itself trusts whatever role string the client declared at OTP time (`mock_responses.dart:88,104,113-114`). There is no real backend role-membership flow to compare it to (none exists yet per the doc quote above), and the frontend has already fully built a 12-screen surface (`provider_dashboard`) plus a 4-screen onboarding flow (`provider_registration`) on top of this self-declared role, in a single binary, with the flavor-level separation removed.

### State Machines

- Backend: `SlotStatus` (`AppointmentSlot`) and `HoldStatus` (`AppointmentHold`) exist as Prisma enums in `prisma/schema/scheduling.prisma`; only `SlotStatus` is currently used (repository reads `status: 'OPEN'` slots only — `infrastructure/appointment-slot.repository.ts:30`). `HoldStatus` and the full appointment lifecycle (`08_WORKFLOWS.md`: HOLD → CONFIRM → CHECK-IN → COMPLETED, with EXPIRED/CANCELLED/NO_SHOW exits) are schema-only, no code implements any transition.
- Frontend: no real appointment state machine exists. The patient-facing "appointments" screen is a static placeholder with a local hardcoded data class (`appointments_placeholder_screen.dart:11`). The **provider dashboard invents its own parallel mini state machine** — accept/reject an already-existing mock appointment (`mock_responses.dart:999-1058`) — that has no relationship to the real `Appointment`/`AppointmentHold` schema or lifecycle at all. This is a second, disconnected notion of "appointment" that will need to be discarded, not adapted, once Phase 4 ships.

### Offline Behavior

- Governing decision: `ADR-002` (Status: HOLD) — **"Do not queue a NEW appointment booking while offline in MVP"** because a hold expires in 5 minutes, which cannot be honored offline. Read-only cache and non-booking offline actions are the only allowed exception.
- Reality: `lib/core/storage/outbox/` (`OutboxBox`, `SyncService`, `PendingAction`) is fully implemented — FIFO Hive-backed queue, reconnect-triggered replay — and registered as Riverpod providers (`core_providers.dart:40,72`), but **zero feature code anywhere calls `enqueue()` or `registerHandler()`**. It is complete, tested-adjacent infrastructure with no caller. This happens to comply with `ADR-002` (nothing queues a booking offline, because nothing queues anything), but that compliance is accidental — the code isn't labeled as intentionally inert, it just isn't wired up yet.
- `CachePolicy` enum (`cacheFirst`/`networkFirst`/`networkOnly`/`cacheOnly`) is declared (`cache_policy.dart:2-14`) but never branched on by any repository examined — another declared-but-unused abstraction in the same area.

### Dashboards / Surfaces

- Backend docs (`09_DASHBOARDS.md`) are explicit: **"Do not create a separate backend business module solely because a dashboard exists. Dashboards are clients/surfaces over domain modules... a complete frontend/Web Dashboard engineering architecture ... should be formalized before production dashboard implementation."** This formalization has now happened for the *surface split* (which framework hosts which dashboard) via `ADR-006`; it has not happened for the *backend data layer* a real provider dashboard needs (still Phase-4-dependent, not started).
- `ADR-003` (Status: **SUPERSEDED by `ADR-006-PROVIDER-SURFACE-SPLIT.md`**, 2026-08-14): the doctor-facing dashboard is confirmed to live in Flutter, scoped to appointments/profile/schedule/provider transactions. Pharmacy and laboratory *staff* dashboards are routed to a separate Next.js web application — explicitly not Flutter, and not yet started anywhere (no Next.js project exists in this workspace, and their owning backend phases — 7, and the Laboratory deferral — remain inactive, so building either now would repeat the same phase-drift problem in a different framework).
- Reality: `provider_dashboard`'s 12 screens now have an approved home. Its persisted mock backend (Hive store surviving restarts) simulating a real API across 13 invented endpoints remains exactly that — a mock standing in for a backend phase that doesn't exist yet. Architecture risk is resolved; backend-readiness risk is unchanged.

### API Errors

- Documented envelope: `{success:false, error:{code, message, correlation_id, details}}`; `401` = unauthenticated, `403` = authenticated-but-forbidden, `429` = rate-limited (respect `Retry-After`).
- Frontend `ErrorInterceptor` (`lib/core/network/interceptors/error_interceptor.dart:17-24`) correctly parses `error.code`/`error.message`/`error.correlation_id` — matches the documented shape (it ignores `success`/`requestId`, which is fine, they're not needed client-side).
- `AuthInterceptor` correctly implements a mutex-guarded single-flight silent refresh on 401 (`auth_interceptor.dart:13,50-85`), matching `13_STATE_AND_FAILURES.md`'s documented UX rule.
- ~~**Gap:** ... never registered ... order also doesn't match.~~ **Fixed 2026-08-14** — see Session Update above and `dio_client.dart`'s current header comment.

---

## Parity Matrix

Status legend: **ALIGNED** (contract verified matching) · **PARTIAL** (backend real, frontend incomplete/not consuming it, or vice versa — no conflict, just gap) · **DIVERGED** (both sides have something, but they disagree/won't work together) · **BLOCKED** (frontend work exists or is proposed against a domain docs explicitly forbid or leave unresolved)

| Capability | Backend reality | Frontend reality | Status | Notes |
|---|---|---|---|---|
| Auth (OTP/JWT/refresh/logout) | Phase 1 complete, real endpoints | Real Dio calls, correct paths | **ALIGNED** | Safe to point at real backend once backend build is fixed |
| Provider search/discovery | Phase 2 complete, `GET /doctors/search` | ✅ Fixed 2026-08-14: correct path, cursor/limit/date/lat/lng params plumbed through | **ALIGNED** | No "load more" UI yet, but the contract itself is correct end to end |
| Provider detail | Phase 2 complete, `GET /doctors/:id` | Real Dio call, correct path | **ALIGNED** | Wire-format assumptions still unverified against real backend (snake_case leak) |
| Availability / slots | Phase 3 in progress, real & tested `GET /doctors/:id/slots` | ✅ Now consumed (2026-08-14) in doctor-detail screen | **ALIGNED** | Fixed `Africa/Cairo` offset, not general IANA — flagged in code; needs `clinicBranchId` which real doctor-detail endpoint doesn't cleanly expose yet (mock stands it in) |
| Appointments (hold/confirm/cancel) | Not started, schema-only | No real patient flow; provider dashboard invents its own disconnected mini-appointment CRUD | **BLOCKED** | Frontend has already built and shipped UI for a lifecycle that doesn't exist server-side |
| Payments | ~~Not started~~ **Stale — Phase 5 + Phase 9 (Part 50, Paymob) are complete**: pay-at-clinic ledger, internal wallet, and `CARD`/`FAWRY`/`MOBILE_WALLET` gateway payments | Wallet read + top-up initiation, appointment pay-at-clinic / `INTERNAL_WALLET` / `FAWRY` | **PARTIAL** | `CARD`/`MOBILE_WALLET` and top-up completion all hinge on one missing piece: an in-app browser for the Paymob `redirectUrl` (no `webview_flutter`/`url_launcher` dependency). Gateway credentials also aren't provisioned yet (`DEC-001`), so every gateway call throws `PAYMENT_GATEWAY_NOT_CONFIGURED` server-side regardless. See `wallet/STATUS.md` and `appointments/STATUS.md`. |
| Prescriptions (standalone) | Not started | Not built as a standalone feature | **PARTIAL** (aligned-by-absence) | |
| Pharmacy fulfillment | Phase 7, not started | Fully built UI, zero network layer, hardcoded fake data | **PARTIAL** | "Design ahead" is permitted by the feature map; execution is sloppy/unlabeled but not a forbidden domain |
| **Laboratory** | **Postponed — not even scheduled** | Fully built: domain + data + presentation + 34 tests + translations, mock endpoints | **BLOCKED** | Direct violation of `11_FEATURE_MAP.md`: "Laboratory — Deferred — **Do not implement**" |
| **Provider dashboard** | No backend capability yet (Phase 4 not started) | 12 screens, "100% (mock-only)", 13 invented endpoints, persisted mock store | **PARTIAL** | ✅ Architecture approved 2026-08-14 (`ADR-006`, supersedes `ADR-003`) — scoped to doctor/clinic workflows, matches this feature's existing content exactly. No longer blocked on architecture; still blocked on backend readiness (Phase 4). |
| Provider self-registration | **Implemented 2026-08-14** per `ADR-005` (`MedSuper_Docs_Reorganization/docs/decisions/ADR-005-PROVIDER-SELF-REGISTRATION.md`, `FILE_12` Part 34): `POST /v1/provider/registration` + `GET /v1/provider/registration/lookups`, authenticated (any role), creates PENDING `Clinic`/`Address`/`ClinicBranch`/`Doctor`/`DoctorClinicAffiliation`, no role-grant, no verification bypass | Fully built 4-screen flow already calling these exact paths/body shape | **PARTIAL — endpoint now real, frontend form is missing two required fields** | Backend now matches the frontend's existing contract. **Frontend must add two required fields** (`license_number`, `region_code` — both non-nullable DB columns with no existing form field) before submission will succeed. `full_name`, `email`, `degree`, `bio`, `experience_years`, `photo_data_uri`, `documents`, `working_days` are accepted by the endpoint but **not persisted anywhere** (echoed back in the response's `not_persisted` array) — frontend must not present these as saved. See ADR-005 for full field-by-field mapping and the `phone`→branch-phone assumption that needs product confirmation. |
| Notifications | Not started | Placeholder screens only | **PARTIAL** (aligned-by-absence) | |
| Delivery | Not started | Not built | **PARTIAL** (aligned-by-absence) | |
| Two-flavor patient/provider build | N/A (frontend-only concern) | Deleted in the latest merge; single binary now | **DIVERGED** | Diverges from `CLAUDE.md`, the architecture doc, and the still-unresolved `ADR-003` premise that provider scope needs careful, bounded expansion |

---

## Gaps / Drift Risks

| ID | Severity | Category | Finding |
|---|---|---|---|
| D1 | ~~HIGH~~ ✅ FIXED | SHARED CONTRACT | ~~Frontend calls `GET /v1/search/doctors`; backend is `GET /v1/doctors/search`.~~ Fixed 2026-08-14 in `api_paths.dart`; mock registration order also fixed (was a latent bug the path fix would have exposed). |
| D2 | ~~MEDIUM~~ ✅ FIXED | SHARED CONTRACT | ~~Search sends no `location`/`date`/`cursor`/`limit`.~~ Fixed 2026-08-14 — plumbed through `doctor_search_repository.dart`/`doctor_search_remote_datasource.dart`; mock honors `cursor`/`limit`, returns `next_cursor`. No "load more" UI (out of scope for a contract fix). |
| D3 | ~~HIGH~~ ✅ FIXED | ARCHITECTURE / FRONTEND | ~~Correlation-ID, Idempotency-Key, and Retry interceptors are never registered in default (mock) dev mode.~~ Fixed 2026-08-14 in `dio_client.dart` — now unconditional. |
| D4 | ~~MEDIUM~~ ✅ FIXED | ARCHITECTURE / FRONTEND | ~~Interceptor registration order doesn't match documented order.~~ Fixed 2026-08-14: Correlation → Auth → Idempotency → Mock → Logging → Error → Retry, matching `04_API_CONTRACT.md`. |
| D5 | BLOCKER | FRONTEND / DOCUMENTATION | `lab_booking` fully implemented against a domain the docs say "Do not implement." |
| D6 | ~~BLOCKER~~ ✅ RESOLVED | FRONTEND / ARCHITECTURE | ~~`provider_dashboard` fully built against an explicitly OPEN, unresolved ADR (`ADR-003`)~~ — resolved 2026-08-14 by `ADR-006-PROVIDER-SURFACE-SPLIT.md` (doctor dashboard approved for Flutter). The 13 speculative endpoint contracts remain mock-only pending backend Phase 4 — that part is unchanged, tracked separately, not a blocker on architecture grounds anymore. |
| D7 | HIGH | ARCHITECTURE / FRONTEND | Two-flavor build deleted in the same branch that expanded provider scope; role gating is now a single client-trusted boolean in one binary, undocumented as an intentional trade-off. |
| D8 | MEDIUM | DOCUMENTATION / PROCESS | The Flutter roadmap's own `DESIGN_ONLY`/`MOCKED`/`BACKEND_READY`/`E2E_READY` labeling rule is applied nowhere in the codebase — "mock-only" only exists in a git commit message. |
| D9 | ~~HIGH~~ ✅ FIXED | DOCUMENTATION | ~~`med-super/CLAUDE.md` is wrong on entry points, flavor scheme, and test-directory existence.~~ Rewritten 2026-08-14. |
| D10 | HIGH | DOCUMENTATION | `analysis_results.md` (repo root) contradicts the authoritative Phase 3 scope doc (recommends building hold/booking/cancellation as "Phase 3 next steps") and states a wrong 15-minute hold TTL against File 12's decided 5 minutes. Non-authoritative but dangerous if mistaken for authoritative. |
| D11 | MEDIUM | TESTING | Test investment inverted: `auth`/`search_discovery`/`home`/`profile_settings`/`provider_profile` (closest to real backend) have zero tests; the four newest, most speculative, mock-only features have full coverage. |
| D12 | HIGH | BACKEND / TESTING | `identity-auth` (Phase 1, "complete") has zero unit tests — the security-critical module is currently the least-verified "complete" code in the backend. |
| D13 | ~~BLOCKER~~ RE-VERIFIED PASSING | BACKEND | Reported failing in the prior pass; re-run 2026-08-14 with `npm run build` (exit 0) and the unit suite (54/54 passing) — currently green. Not personally fixed in this pass; flagging the discrepancy rather than silently editing the historical finding. |
| D14 | MEDIUM | FRONTEND | Provider dashboard hardcodes 4 endpoint path strings inline instead of using the shared `ApiPaths` constants class used everywhere else — inconsistent convention, increases future contract-drift risk. |
| D15 | LOW | FRONTEND | Mock doctor catalog mixes Riyadh (Saudi) location labels with `currency: 'EGP'` — internally inconsistent fixture data for a product docs describe as "Egypt-first." |

---

## What Can Proceed in Parallel Safely

- **Backend Phase 3 completion** — real, disciplined, boundary-respecting work; conditional only on fixing the build break (D13).
- **Frontend `auth`** — contract-correct today; safe against the real backend once it builds.
- **Frontend `home` shell, `profile_settings`** — no meaningful backend dependency.
- **Frontend `search_discovery`** — only *after* D1/D2 are fixed; not parallel-safe as currently written.
- **Retroactive documentation/labeling work** (CLAUDE.md rewrite, per-feature status labels) — zero technical risk, should start immediately.

## What Must Wait

- **Any further `provider_dashboard` work** — until `ADR-003` is explicitly resolved by whoever owns the decision register. Every additional screen deepens rework cost against an unapproved architecture.
- **Any further `lab_booking` work** — until the "do not implement" instruction in `11_FEATURE_MAP.md` is either reversed in writing or the feature is explicitly pulled from the current integration path.
- **Real (non-mock) integration of `pharmacy_booking`** — target backend capability (Phase 7) doesn't exist yet.
- ~~**`provider_registration` going live against the real backend** — the endpoint now exists (`ADR-005`), but the frontend form must add `license_number` and `region_code` (both required, non-nullable columns) before flipping off `MockInterceptor` for this feature; several other collected fields (photo, documents, bio, experience, degree, proposed schedule) still have no persisted backend destination and must not be presented as saved — see the endpoint's `not_persisted` response field.~~ ✅ **Resolved** — `license_number`/`region_code` are collected; `photo_data_uri`/`documents`/`bio`/`experience_years`/`degree`/`working_days` all persist for real as of the 2026-09-04 Session Update above. Only `specialty_label`/`city_label` (display-only duplicates, never meant to persist) remain in the response's `notPersisted` array.
- **Any frontend appointment-hold/booking implementation** — backend Phase 4 doesn't exist; anything built now is speculation against an undesigned API.
- **Anything backend-CI-dependent** — until `npm run build` is green again.

---

## Dead Code / Hardcoded / Useless Code Findings

**Frontend:**
- ✅ **REMOVED 2026-08-14** — `lib/features/home/presentation/screens/profile_placeholder_screen.dart`, `search_placeholder_screen.dart` (confirmed zero references before deletion).
- ✅ **LABELED 2026-08-14** (not dead, now explained) — `lib/app/router/routes/appointment_routes.dart:4` (`appointmentRoutes = []`), `lib/core/storage/outbox/*`, `CachePolicy` enum, `IdempotencyKeyInterceptor`'s `_idempotentPaths` list — each now carries a doc comment explaining it's intentionally inert pending a specific later phase/decision, not unexplained dead weight.
- 25 hardcoded Arabic UI strings across 8 `provider_dashboard` files bypass `easy_localization` (e.g. `add_appointment_bottom_sheet.dart:107`, `provider_home_screen.dart:72,94,133`) — invisible to the translation system, not just missing a locale.
- 2 hardcoded English error strings in `lab_booking`/`pharmacy_booking` upload screens.
- 4 hardcoded literal API path strings in `provider_dashboard`'s datasource instead of using `ApiPaths` constants.
- Mock OTP `'123456'` and a stand-in Unsplash avatar URL — expected for mock mode, noted for completeness.
- Mock data inconsistency: Riyadh location labels + `EGP` currency in the same doctor record.

**Backend:**
- None found. No orphaned files, no manual DI bypass outside test files, no hardcoded secrets/URLs in production code, no duplicated business logic (the provider-visibility rule chain is correctly reused by `scheduling-appointments`, not reimplemented), no controller/repository boundary violations.

---

## Docs / CLAUDE / ADR Updates Needed

| Doc | Problem | Action |
|---|---|---|
| `med-super/CLAUDE.md` | Untracked; wrong on entry points, flavor scheme, test-directory existence | ✅ **Done 2026-08-14** — rewritten |
| `E:\health-care\analysis_results.md` | Contradicts authoritative Phase 3 scope; wrong hold TTL | **Still open** — delete or clearly mark "SUPERSEDED" (not touched this pass; not part of either repo, a root-level scratch file) |
| `MedSuper_Docs_Reorganization/docs/02_CURRENT_STATE.md` | Dated 2026-08-13, predates real scheduling-appointments work | **Still open** — update to reflect Phase 3 in-progress state (out of frontend-alignment scope this pass) |
| `MedSuper_Flutter_Documentation_Pack/02_CURRENT_STATE.md` | Said frontend status is "UNKNOWN" | ✅ **Done 2026-08-14** — replaced with real current state, cross-linking this document |
| `ADR-003` | Status OPEN, but code has already moved past it | ✅ **Resolved 2026-08-14** — superseded by `ADR-006-PROVIDER-SURFACE-SPLIT.md`; `provider_dashboard` relabeled `MOCKED` (architecture approved, backend not ready) |
| `11_FEATURE_MAP.md` | Says "Laboratory — do not implement"; code did | **Still open** — same reasoning; `lab_booking` frozen and labeled `BLOCKED` |
| Per-feature docs | No feature records a `DESIGN_ONLY`/`MOCKED`/`BACKEND_READY`/`E2E_READY` label anywhere durable | ✅ **Done 2026-08-14** — `lib/features/*/STATUS.md` added for all 9 features |
| `FILE_12` | Mixes decision-record content with retrospective implementation notes | Low priority; consider separating decisions from implementation commentary (still open) |

---

## Fix Priority Order

1. ~~**Backend:** fix the `tsc` build break.~~ ✅ Re-verified passing 2026-08-14.
2. ~~**Frontend:** fix the search path mismatch and add missing query params.~~ ✅ Done 2026-08-14.
3. ~~**Frontend:** rewrite and commit `CLAUDE.md`.~~ ✅ Done 2026-08-14.
4. **Decision owners:** resolve `ADR-003` (provider dashboard scope) and the Laboratory "do not implement" conflict. **Still open — requires a human decision, not more code.**
5. **Backend:** add unit tests for `identity-auth`. Still open.
6. **Frontend:** backfill tests for `auth`, `search_discovery`, `home`. Still open.
7. ~~**Frontend:** wire Correlation-ID/Idempotency/Retry interceptors into mock mode too.~~ ✅ Done 2026-08-14.
8. **Cleanup pass:** hardcoded i18n strings in `provider_dashboard`, `ApiPaths` inconsistencies there, mock data fixture inconsistency (Riyadh labels + EGP currency) — still open; deliberately left untouched since `provider_dashboard` is frozen (`BLOCKED`) and editing frozen code for cosmetic consistency isn't worth the unverifiable risk (see `STATUS.md`).
9. **New — frontend:** add real backend verification for `GET/PATCH /v1/auth/me`, used by `auth`/`profile_settings` but not in the backend's confirmed endpoint list.
10. **New — frontend:** confirm the `phone` → clinic-branch-phone interpretation in `ADR-005` with product; add `license_number`/`region_code` fields to the provider-registration form.

---

## Final Verdict

**As of this alignment pass (2026-08-14), the currently-approved surface (auth, search/discovery, provider detail, availability/slots, provider self-registration intake) is now genuinely aligned and safe to build on** — contract paths, params, pagination, and the interceptor chain all match documented/real backend behavior, and every feature carries an explicit status label.

- **Backend** may continue Phase 3 to completion — real, disciplined, boundary-respecting work; build/tests currently green.
- **Frontend** may continue on `auth`, `home`, `profile_settings`, `search_discovery`, `provider_profile` (detail + availability) without qualification.
- **`provider_registration`** may continue toward going live once the two required fields (`license_number`, `region_code`) are added to the form and the `phone` interpretation is confirmed with product.
- **`provider_dashboard` is unblocked on architecture (2026-08-14, `ADR-006`)** — doctor dashboard confirmed to live in Flutter, scoped to doctor/clinic workflows. It remains `MOCKED`: none of its 13 endpoints are real, and none should be presented as such until backend Phase 4 exists. **`lab_booking` remains frozen (`BLOCKED`)** — unaffected by `ADR-006` (that ADR is about presentation surface, not backend domain activation); resuming it requires an explicit reversal of the Laboratory "do not implement" instruction, not more engineering. **Pharmacy/laboratory staff dashboards (Next.js) are approved in principle but must not be started** while their backend phases (7, and the Laboratory deferral) remain inactive. Continuing to build on an open ADR and an explicit "do not implement" instruction remains the highest-risk activity available in this repository — speculative contract lock-in against domains with no approved architecture.
- `pharmacy_booking` may continue as UI/mock-only work under the feature map's "design ahead" allowance but should be wired through `MockInterceptor` like every other feature for consistency, and stays labeled `DESIGN_ONLY`.
- `analysis_results.md` remains dead and should still be deleted or marked superseded — not touched this pass (it's a root-level file outside both repos, not part of this alignment scope).
- **Two items intentionally left alone despite being fixable:** `identity-auth`'s missing unit tests (backend) and the inverted test-coverage priority (frontend) — both are testing-investment gaps, not contract/architecture drift, and are lower priority than the alignment work this pass targeted.

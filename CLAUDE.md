# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

MedSuper is a healthcare super-app Flutter client. Backend is a mock API by default (no server needed for development). Backend truth is `../clinic-reservations` (NestJS), currently capped at **Phase 3 (Availability)** — see `docs/backend_frontend_parity_matrix.md` for the authoritative, code-verified state of both sides. Read that file before assuming any feature is more "done" than it is.

A separate, self-contained snapshot audit — `docs/backend_connectivity_audit_2026-08-21.html` (open in a browser) — goes screen-by-screen through the Flutter app and states, per screen, whether it's actually wired to the real `clinic-reservations` backend or only to the mock, with exact endpoints/fields/files. It was produced by reading both repos' code directly on 2026-08-21 and explicitly flags that the Phase-3 cap stated above was stale at that time (it found Phase 4/Appointments already complete in the backend). Treat it as a dated point-in-time snapshot, not a live source of truth — cross-check against current code and `docs/backend_frontend_parity_matrix.md` before relying on any specific claim in it.

**The two-flavor (patient/provider) architecture described in older docs no longer exists in code.** `lib/main_provider.dart`, `lib/app/flavor.dart`, and `lib/app/router/route_guards.dart` were deleted in the `feature/doctor-dashboard` branch (merged 2026-08-14). There is one entry point (`lib/main.dart`) and one binary; patient-vs-provider routing is gated purely by a client-read boolean (`session.user.isPatient`/`isProvider`, sourced from the auth response) in `lib/app/router/app_router.dart` — there is no build-time separation anymore. `ADR-006-PROVIDER-SURFACE-SPLIT.md` (2026-08-14, supersedes `ADR-003`) confirms the doctor dashboard *belongs* in Flutter — but it says nothing about *how role gating should work*, which remains a single client-trusted boolean with no build-time isolation. Do not treat the client-side role check as an authorization boundary, and do not "fix" this by reintroducing flavors without an explicit decision on the role-gating question specifically (see `lib/features/provider_dashboard/STATUS.md`).

## Commands

Run the app:
```bash
flutter run -t lib/main.dart
```
(Or use the VS Code launch configs in `.vscode/launch.json`.)

Code generation — required after any change to `@freezed`, `@riverpod`, `@JsonSerializable`, or `@RestApi` annotated files:
```bash
dart run build_runner build
dart run build_runner watch   # watch mode
```
Not every Riverpod provider in this codebase uses codegen — some (e.g. `lib/features/provider_profile/presentation/controllers/doctor_availability_providers.dart`) are written as plain `Provider`/`FutureProvider.family` on purpose, specifically to avoid needing a `build_runner` pass. Prefer that style for small additions if you can't run `build_runner` in your environment.

Lint:
```bash
flutter analyze
```

Android release/debug build (see Android SDK note below if it fails):
```bash
flutter build apk -t lib/main.dart --debug
```

Tests:
```bash
flutter test
```
`test/core`, `test/features`, `test/helpers` exist (71 files) — but coverage is entirely concentrated in the four newest features (`lab_booking`, `pharmacy_booking`, `provider_dashboard`, `provider_registration`). `auth`, `search_discovery`, `home`, `profile_settings`, `provider_profile` currently have **zero** tests, despite being the features closest to real backend integration.

## Architecture

Clean Architecture, Riverpod 3 for DI. Full spec in [`MedSuper_Flutter_Architecture.md`](MedSuper_Flutter_Architecture.md); product spec in [`MedSuper-SRS-Enterprise-Blueprint.md`](MedSuper-SRS-Enterprise-Blueprint.md) — both describe a broader/older architecture than what's currently built; treat them as design intent, not current-state truth (`docs/backend_frontend_parity_matrix.md` is current-state truth).

- `lib/main.dart` — single entry point, calls shared `bootstrap.dart`.
- `lib/bootstrap.dart` — shared startup: Hive, Firebase, l10n, `runApp`.
- `lib/app/` — `app.dart` (MaterialApp.router + theme + locale + responsive), `router/` (GoRouter, auth+role guard inline in `app_router.dart`).
- `lib/core/` — cross-cutting concerns shared by all features: config, constants (api paths, Hive box names, storage keys), error types (`Failure` sealed class, `Result<T>`, `ApiException`), `network/` (DioClient + interceptors + mock seam), `storage/` (HiveService, SecureStorageService, CachePolicy, Outbox — the last two are declared but not yet consumed by any feature, see their doc comments), `notifications/` (FCM, priority router, local notifications), `crash/` (CrashlyticsService), `di/core_providers.dart` (app-wide Riverpod providers), `theme/`, shared `widgets/`, `utils/`.
- `lib/features/` — one directory per feature: `auth`, `home`, `search_discovery`, `provider_profile`, `provider_registration`, `lab_booking`, `pharmacy_booking`, `provider_dashboard`, `profile_settings`. Each has `domain/`, `data/`, `presentation/`, **and a `STATUS.md`** stating its current `DESIGN_ONLY`/`MOCKED`/`PARTIAL`/`BACKEND_READY`/`BLOCKED` label — read it before touching a feature. `appointments`/`payments`/`notifications_center` **do not exist as directories** — don't assume the older Sprint plan still matches the repo.
- `lab_booking` is `BLOCKED` — do not add screens, endpoints, or logic without an explicit product/engineering decision (see `STATUS.md`).
- `provider_dashboard` is `MOCKED` — its architecture is now approved (`ADR-006-PROVIDER-SURFACE-SPLIT.md`, 2026-08-14: doctor dashboard stays in Flutter, scoped to appointments/profile/schedule/provider transactions; pharmacy/lab *staff* dashboards go to a separate Next.js app, not here), but its 13 backend endpoints are still entirely mock-only/invented — don't present it as backend-ready, and don't expand it into pharmacy/lab dashboard scope. See `STATUS.md`.

### Mock API

All API calls are intercepted by `MockInterceptor` when `BASE_URL` is unset (default dev mode). Add mock responses in `lib/core/network/mock/mock_responses.dart`. **Registration order matters**: `MockInterceptor` matches by first-registered-wins substring containment on the request path, so a more specific pattern (e.g. `/v1/doctors/{id}/slots`) must be registered *before* a broader one that would otherwise swallow it (e.g. `/v1/doctors/`) — see the ordering comments in `registerAvailabilityMocks`/`registerSearchMocks`.

Mock OTP code is `123456`.

The Dio interceptor chain (`lib/core/network/dio_client.dart`) now runs Correlation-ID/Idempotency-Key/Retry unconditionally, including in mock mode — they used to be skipped entirely in the default dev mode, meaning this logic was never actually exercised until fixed 2026-08-14.

### Dev auth bypass

Set `kDevBypassAuth = true` in `lib/features/auth/presentation/controllers/session_provider.dart` to skip login/OTP during UI work; keep `false` (current default) to exercise the real auth loop.

### Localization

Default locale `en`, also supports `ar` with full RTL. Translation files at `assets/translations/en.json` and `ar.json` — add new keys to **both** files (they must stay symmetric). Access via `'auth.sign_in'.tr()` (easy_localization). Don't hardcode user-facing strings directly in widgets — `provider_dashboard` has ~25 that bypass this and aren't localizable; don't add more anywhere.

## Platform notes

- **Android**: Flutter 3.44 and `flutter_secure_storage 11` require Android SDK 37. If build fails with `Failed to find target with hash string 'android-37'`, install Android 15 (API 37) via Android Studio SDK Manager. No product flavors are configured (`android/app/build.gradle.kts`) — matches the single-binary architecture above.
- **iOS**: single `Runner` scheme, no flavor variants.

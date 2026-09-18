# Feature status: auth

**Label:** `BACKEND_READY`

Real Dio calls to the exact documented/verified backend contract (backend
Phase 1, COMPLETE), each verified wired correctly end to end:
- ✅ `POST /v1/auth/otp/request`
- ✅ `POST /v1/auth/otp/verify`
- ✅ `POST /v1/auth/token/refresh`
- ✅ `POST /v1/auth/logout`
- ✅ `GET /v1/auth/me`
- ✅ `PATCH /v1/auth/me` — **added 2026-08-25**: backend previously had no
  route at all for this (only `GET`), despite this feature already calling
  it. Added `UpdateCurrentUserUseCase` + controller route on
  `clinic-reservations` (`feature/patch-auth-me`), backed by the existing
  (already cross-module-exported) `UpdateUserProfileUseCase`. Onboarding now
  collects `display_name` **and `email`** (both required, no skip) and
  sends both in one call; verified end to end against the real local
  backend.

Runs against `MockInterceptor` by default in dev (`BASE_URL` unset) — flip
`BASE_URL` to point at a real backend and this feature should work
unmodified.

**Password auth — `BACKEND_READY`, added 2026-08-23:** 5 real endpoints on
`identity-auth`, each verified wired correctly end to end:
- ✅ `POST /v1/auth/password/set` — JWT-required, post-OTP
- ✅ `POST /v1/auth/password/login` — public, phone+password
- ✅ `POST /v1/auth/password/forgot` — public, sends reset OTP
- ✅ `POST /v1/auth/password/reset/verify-code` — public, checks-only
- ✅ `POST /v1/auth/password/reset` — public, sets new password, no auto-login

Flow: `AccountLoginScreen` → "Forgot password?" → `ForgotPasswordScreen` →
`VerifyResetCodeScreen` → `ResetPasswordScreen` → back to login. All mocked
in dev.

**Do not build:** role-membership switching / multi-role context UI — the
backend RBAC doc (`07_AUTH_RBAC.md`) explicitly leaves this unresolved.

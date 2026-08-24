# Feature status: auth

**Label:** `BACKEND_READY`

Real Dio calls to the exact documented/verified backend contract (backend
Phase 1, COMPLETE), each verified wired correctly end to end:
- ✅ `POST /v1/auth/otp/request`
- ✅ `POST /v1/auth/otp/verify`
- ✅ `POST /v1/auth/token/refresh`
- ✅ `POST /v1/auth/logout`
- ✅ `GET/PATCH /v1/auth/me`

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

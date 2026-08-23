# Feature status: auth

**Label:** `BACKEND_READY`

Real Dio calls to the exact documented/verified backend contract:
`POST /v1/auth/otp/request`, `/otp/verify`, `POST /v1/auth/token/refresh`,
`POST /v1/auth/logout` (backend Phase 1, COMPLETE). Runs against
`MockInterceptor` by default in dev (`BASE_URL` unset) — flip `BASE_URL` to
point at a real backend and this feature should work unmodified.

**Caveat:** `GET/PATCH /v1/auth/me` (used for profile fetch/update) is used
by this feature and by `profile_settings`, but is **not** in the backend's
confirmed/documented Phase 1 endpoint list
(`clinic-reservations/src/modules/identity-auth/api/identity-auth.controller.ts`
only exposes `otp/request`, `otp/verify`, `token/refresh`, `logout`). Verify
this endpoint exists on the real backend before relying on it outside mock
mode — see `med-super/docs/backend_frontend_parity_matrix.md`.

**Do not build:** role-membership switching / multi-role context UI — the
backend RBAC doc (`07_AUTH_RBAC.md`) explicitly leaves this unresolved.

# Feature status: notifications

**Label:** `BACKEND_READY` (in-app inbox + device token registration)

Wired to `clinic-reservations` Phase 8 (Notifications):

- ✅ `GET /v1/notifications` — cursor-paginated inbox, self-scoped
- ✅ `PATCH /v1/notifications/{id}/read` — mark one notification read
- ✅ `POST /v1/auth/devices` — register/refreshes FCM token after login

**Not wired yet:**

- `GET` / `PUT /v1/notifications/preferences` — notification preference toggles
  (no settings UI exists in the app yet)
- Foreground push → inbox refresh (FCM init exists; no listener invalidates the
  list provider on message receipt)

**Shared by both surfaces:** patient tab (`/patient/notifications`) and provider
screen (`/provider/notifications`) use the same datasource — the backend always
scopes rows to the authenticated user.

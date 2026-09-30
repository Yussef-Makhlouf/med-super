# Feature status: notifications

**Label:** `BACKEND_READY` (in-app inbox + device token registration)

Wired to `clinic-reservations` Phase 8 (Notifications):

- ✅ `GET /v1/notifications` — cursor-paginated inbox, self-scoped
- ✅ `PATCH /v1/notifications/{id}/read` — mark one notification read
- ✅ `POST /v1/auth/devices` — register/refreshes FCM token after login
- ✅ `DELETE /v1/auth/devices/current` — unregisters the current FCM token before logout; logout also sends `fcmToken` with the refresh token as a fallback
- ✅ Foreground push and foreground resume refresh the inbox; token refresh and failed registration are retried while the session is active
- ✅ `GET` / `PUT /v1/notifications/preferences` — localized settings screen at `/notifications/preferences`, with server-backed PUSH/SMS preferences and non-disableable safety-critical alerts

Device delivery still needs Android/iOS/web testing with a real Firebase
project, valid APNs configuration on iOS, and live backend credentials. FCM
acceptance is not proof that a device displayed the notification.

**Shared by both surfaces:** patient tab (`/patient/notifications`) and provider
screen (`/provider/notifications`) use the same datasource — the backend always
scopes rows to the authenticated user.

**Inbox resilience polish (2026-09-24):** cursor-page failures retain the
visible notifications and cursor and expose a localized retry action; repeated
notification IDs are deduplicated, and a repeated cursor ends pagination.
"Mark all as read" updates each row only after that row's PATCH succeeds, so a
partial backend failure no longer makes unread items appear read locally.

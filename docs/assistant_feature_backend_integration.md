# Clinic Assistant Feature — Backend Integration Notes

**Date:** 2026-08-28  
**Status:** Frontend complete with mock data. Backend not yet implemented.

---

## What is implemented (frontend, mock mode only)

A Doctor can manage clinic assistants from the Profile tab → المساعدون tile.
A clinic assistant can log in and access a restricted provider dashboard.

---

## Mock credentials (dev / mock mode only)

| Role | Phone | Password |
|------|-------|----------|
| Doctor | `01000000000` | `Test1234` |
| Assistant (pre-seeded) | `01100000001` | `Assist1234` |
| Newly created assistants | whatever phone Doctor entered | `MedS@2026!` (fixed mock password) |

---

## Backend API contract assumed

All endpoints live under the authenticated provider scope.
The caller must carry a `DOCTOR` JWT (`contextType = DOCTOR`).

### GET /v1/provider/assistants
Returns all assistants provisioned by the calling Doctor.

**Response:**
```json
{
  "items": [
    {
      "id": "uuid",
      "phone": "+201XXXXXXXXX",
      "display_name": "string",
      "status": "ACTIVE | SUSPENDED",
      "created_at": "ISO8601"
    }
  ]
}
```

### POST /v1/provider/assistants
Provision a new assistant account.

**Request body:**
```json
{ "phone": "+201XXXXXXXXX", "display_name": "string" }
```

**Response** (one-time only — `generated_password` never returned again):
```json
{
  "id": "uuid",
  "phone": "+201XXXXXXXXX",
  "display_name": "string",
  "status": "ACTIVE",
  "created_at": "ISO8601",
  "generated_password": "plaintext-one-time-password"
}
```

### PATCH /v1/provider/assistants/:id
Update display name and/or status.

**Request body** (all fields optional):
```json
{ "display_name": "string", "status": "ACTIVE | SUSPENDED" }
```

**Response:** same shape as list item (without `generated_password`).

### DELETE /v1/provider/assistants/:id
Soft-deactivate an assistant (revoke role membership, prevent login).

**Response:** `200 {}` or `204`.

---

## Backend implementation assumptions

### Authentication & authorization
- Endpoint guard: `@Roles(RoleContextType.DOCTOR)`
- The calling Doctor is identified via `request.user.sub` (JWT `sub` claim = `users.id`)
- The Doctor's record is resolved via `doctors.user_id = sub`

### RoleMembership convention
When a new assistant is provisioned, the backend must:
1. Create or upsert a `User` row for the assistant's phone
2. Create a `RoleMembership` row: `role_code = 'CLINIC_STAFF'`, `context_type = CLINIC_STAFF`, `context_id = doctor.id` (UUID of the Doctor record, not the user)
3. Generate a random secure password and store its argon2 hash on `users.password_hash`
4. Return the plain-text password **once** in the response
5. Emit an outbox event (`AssistantProvisioned`) for downstream notifications

### context_id usage
`RoleMembership.context_id` must be set to the **Doctor's `doctors.id`** (UUID), not `users.id`.
This is how the backend knows which Doctor "owns" each assistant, and how it scopes
`GET /v1/provider/assistants` to return only assistants belonging to the caller's Doctor record.

### ClinicAssistant table (optional)
The backend may choose to:
- Use `RoleMembership` alone as the source of truth (context_id = doctor.id)
- Or add a dedicated `clinic_assistants` table for richer metadata (e.g., custom display name separate from `users.first_name`/`last_name`)

The frontend sends and expects `display_name` (not `first_name + last_name`), so the backend must
decide where to persist this — either as `users.first_name` or in a dedicated column.

### Login flow (no change needed to existing auth)
The existing `POST /v1/auth/password/login` endpoint works as-is for assistants.
`LoginWithPasswordUseCase` resolves the first active `RoleMembership` for the user —
as long as the assistant has a `CLINIC_STAFF` membership, the JWT will carry `contextType = CLINIC_STAFF`.
`GET /v1/auth/me` returns `active_role = 'CLINIC_STAFF'` which the frontend maps to `UserRole.clinicStaff`.

---

## Frontend integration readiness

When the backend is ready, the only change needed on the frontend is:

1. **Remove mock registration** — delete `registerAssistantMocks(mock)` call in `dio_client.dart`
   and the corresponding `registerAssistantMocks` function in `mock_responses.dart`.

2. **No other changes** — all domain entities, DTOs, use cases, repository, providers, and UI
   screens are already wired to real API paths (`/v1/provider/assistants`). The mock data flows
   through the exact same code path as the real backend will.

3. **Phone normalization** — `AddAssistantBottomSheet` calls `normalizeEgyptPhone()` before
   sending to the API, so the backend will always receive E.164 format (`+201XXXXXXXXX`).

---

## Known limitations of the mock

- **Fixed generated password** — all newly created assistants in mock mode get `MedS@2026!`.
  The real backend should generate a cryptographically random password per provisioning.
- **No persistence across sessions** — `_mockAssistants` is in-memory; a hot restart resets it
  to the 2 seeded records.
- **No ownership check** — the mock does not validate that the calling Doctor owns the assistant
  being edited/deleted. The real backend must enforce this via `doctor.id` lookup.
- **SUSPENDED assistants can still log in** in mock mode — the mock `passwordLogin` handler does
  not check `status`. The real backend should reject login for `SUSPENDED` users.

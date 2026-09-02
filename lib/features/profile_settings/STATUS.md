# Feature status: profile_settings

**Label:** `BACKEND_READY`

`GET`/`PATCH /v1/auth/me` are real, confirmed endpoints
(`clinic-reservations` `identity-auth` module) — the "not in the confirmed
Phase 1 list" caution this file used to carry was stale.

**Audited 2026-08-31** against `Prisma.User`'s real columns: only
`displayName`/`email` are backed by an actual column and editable; `phone`
is read-only (no endpoint changes it post-signup); date of birth, gender,
and address were removed from `EditProfileScreen` entirely — none of them
has a backing column, so they were pure UI with nothing to ever persist to.
`email` was write-only until this pass (`GetCurrentUserResult` never
returned it, `clinic-reservations` File 12 Part 45 added it) — it now
round-trips and is prefilled on this screen like every other real field.
Photo upload stays a placeholder ("قريبًا") on both this screen and
onboarding — no object-storage decision exists yet (`DEC-009`).

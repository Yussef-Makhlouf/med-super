# Feature status: provider_registration

**Label:** `PARTIAL` (backend endpoint now real; form is incomplete)

`POST /v1/provider/registration` + `GET /v1/provider/registration/lookups`
were implemented on the backend 2026-08-14 (`ADR-005-PROVIDER-SELF-REGISTRATION.md`)
at the exact paths/body shape this feature already calls.

**Before this can go live against a real backend:**
1. Add two required form fields that don't exist yet: `license_number` and
   `region_code` (both non-nullable backend columns — submission will fail
   validation without them).
2. Treat `full_name`, `email`, `degree`, `bio`, `experience_years`,
   `photo_data_uri`, `documents`, `working_days` as **not persisted** — the
   backend accepts them but drops them (echoed back in the response's
   `not_persisted` array). Don't present these as saved until the backend
   follow-ups in ADR-005 (object storage, schema additions, Admin document
   upload path) are resolved.
3. Confirm the `phone` field's meaning — the backend currently interprets
   it as the clinic branch's contact phone, not the doctor's personal
   phone (already known from the authenticated session).

Submission creates `PENDING` records requiring Admin verification — same
as if an Admin had created them directly. **No role membership is granted**
by submitting this form.

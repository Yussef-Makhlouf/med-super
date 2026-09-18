# Feature status: provider_registration

**Label:** `PARTIAL` (backend endpoint now real; form is incomplete)

`POST /v1/provider/registration` + `GET /v1/provider/registration/lookups`
were implemented on the backend 2026-08-14 (`ADR-005-PROVIDER-SELF-REGISTRATION.md`)
at the exact paths/body shape this feature already calls.

**Before this can go live against a real backend:**
1. ~~Add two required form fields that don't exist yet: `license_number` and
   `region_code`~~ — done: `license_number` is collected on the verification
   step (next to the license upload) and `region_code` on the clinic
   schedule step (a hardcoded governorate dropdown — the backend has no
   region lookup endpoint, see `domain/entities/region_codes.dart`).
2. `full_name`, `email`, `degree`, `bio`, `experience_years`,
   `photo_data_uri` persist on `User`/`Doctor` (Part 34.2). `working_days`
   now persists as real `ScheduleTemplate` rows tied to the new
   `DoctorClinicAffiliation` (File 12 Part 48) — the frontend now sends
   `{weekday, startTime, endTime, slotDurationMinutes, bufferMinutes}` per
   enabled day (ISO weekday 1=Monday…7=Sunday) instead of the old
   `{day, is_enabled, from, to}` shape. `documents` now uploads for real,
   one file per document, to `POST /v1/provider-verification-documents`
   right after submission succeeds (doctor self-service, Part 48) — no
   `slotDurationMinutes`/`bufferMinutes` picker UI exists yet, so these
   default to 30/0 for every submitted working day.
3. Confirm the `phone` field's meaning — the backend currently interprets
   it as the clinic branch's contact phone, not the doctor's personal
   phone (already known from the authenticated session).

**Fixed 2026-09-04 (`feature/doctor-self-service-registration`):**
- The working-hours "From"/"To" pickers now validate the window
  immediately when a time is picked (`doctor_registration_clinic_schedule_screen.dart`'s
  `_isValidWindow`) instead of only failing at submit time with a generic
  `422 INVALID_SCHEDULE_WINDOW` after the whole form was filled out.
- A real cross-account bug: the in-progress draft is Hive-persisted and
  was only cleared by an explicit `logout()` call. A session that ended
  without one (app closed/killed mid-registration) left the draft on disk
  with no owner recorded, so the next login on the same device — even a
  different phone number — inherited the previous applicant's half-filled
  data untouched. Fixed by tagging the draft with an `owner_user_id` and
  discarding it on login if it belongs to someone else
  (`RegistrationFormController.discardIfOwnedByDifferentUser`,
  called from `SessionController._claimRegistrationDraft`).

Submission creates `PENDING` records requiring Admin verification — same
as if an Admin had created them directly. **No role membership is granted**
by submitting this form.

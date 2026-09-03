# Feature status: provider_profile

**Label:** `PARTIAL` (doctor detail: `BACKEND_READY`, wire format
reconciled and live-verified 2026-08-15; availability: `BACKEND_READY`;
booking hand-off to `lib/features/appointments`: `BACKEND_READY`, gated on
`affiliationId` below)

- Doctor detail (`GET /v1/doctors/{id}`) — calls the real Phase 2 contract.
  `DoctorProfileDto.fromJson` now dispatches on shape: the real response
  nests everything under `{doctor: {...raw Prisma fields, user,
  specialty}, affiliations: [...raw DoctorClinicAffiliation rows with
  clinic_branch.{address, clinic}]}` (no dedicated response DTO on the
  backend — `GetDoctorUseCase` returns raw repository rows), handled by
  `DoctorProfileDto._fromRealJson`; the mock's flat convenience shape
  (`_fromMockJson`) is unchanged. Verified live 2026-08-15 against a real
  running backend (Docker Postgres/Redis, `npm run start:dev`) — the exact
  JSON this parser was written against was fetched via curl from
  `GET /v1/doctors/{id}` on a real seeded+verified doctor, not guessed.
  Several UI fields (experience years, bio, qualifications, fellowships,
  languages, "online now") have **no backing column anywhere in the Phase
  2 schema** — they parse to empty/zero/false against a real backend by
  design, not a bug to chase; see `_fromRealJson`'s doc comment.
- Availability (`GET /v1/doctors/{doctorId}/slots`) — added 2026-08-14,
  matches the real, tested backend Phase 3 contract exactly (verified
  against `GetDoctorSlotsUseCase`'s response shape). Hold/booking now goes
  through `lib/features/appointments` (see the `affiliationId` note below).
  Timezone conversion is a fixed
  `Africa/Cairo` (+2:00) offset, not a general IANA converter — no
  timezone/tzdata package exists in `pubspec.yaml`; any other
  `ianaTimezone` value falls back to a UTC-labeled display rather than
  silently mislabeling it. See
  `lib/features/provider_profile/domain/utils/slot_grouping.dart`.
- `clinicBranchId`/`ianaTimezone`/`affiliationId` on `DoctorProfile` are
  currently mock-only fields (`branch-{doctorId}` / `'Africa/Cairo'` /
  `affiliation-{doctorId}`) standing in for what the real doctor-detail
  response should expose once its wire format is confirmed — see
  `DoctorProfileDto._firstAffiliationId` for the forward-compatible parse
  attempt against the real `{doctor, affiliations}` shape, which is
  untested against a live backend.
- Phase 4 (Appointments) is real and wired now — `doctor_details_screen`'s
  "Book Now" pushes into `lib/features/appointments` when both a slot and
  `profile.affiliationId` are selected/present. Booking is *disabled*, not
  broken, when `affiliationId` is null (i.e. against a real, unreconciled
  backend response today) — this is the correct degraded behavior, not a
  bug to silently "fix" by fabricating an id.
- Clinic detail (`GET /v1/clinics/{clinicId}`) — the parent/chain-level
  screen (`clinic_profile.dart` / `clinic_details_screen.dart` /
  `patientClinicDetails` route) was **removed 2026-08-28**: a clinic chain
  name alone has no address/phone to act on, so a patient never drills into
  it to "find the branches" — the branch itself is the unit browsed and
  detailed. The backend endpoint still exists (admin/back-office use), just
  nothing in this app calls it anymore.
- Clinic branch detail (`GET /v1/clinic-branches/{branchId}`) — added
  2026-08-25 (`clinic_branch.dart` / `clinic_branch_dto.dart` /
  `clinic_branch_repository*.dart` / `get_clinic_branch_usecase.dart` /
  `clinic_branch_providers.dart` / `clinic_branch_details_screen.dart`).
  Matches `GetClinicBranchUseCase`'s raw `ClinicBranchWithRelations` shape
  (branch + `address` + parent `clinic`). Route:
  `/patient/home/clinic-branches/:branchId` (`patientClinicBranchDetails`,
  nested under `/patient/home` since 2026-09-03 — see `search_routes.dart`'s
  doc comment for why it can no longer be a root-level route), wired in
  `search_routes.dart`. Mock handler: `registerClinicBranchMocks`.
- Pharmacy detail (`GET /v1/pharmacies/{pharmacyId}`) — the parent/chain-level
  screen (`pharmacy_profile.dart` / `pharmacy_details_screen.dart` /
  `patientPharmacyDetails` route) was **removed 2026-08-28**, same reasoning
  as the clinic-detail removal above: the branch is the unit patients
  browse/pick/order against, not the chain. `pharmacy_booking`'s select-a-
  branch step now pushes straight to `PharmacyBranchDetailsScreen`, which
  gained the `onSelect` "choose and continue" bottom bar this parent screen
  used to own. The backend endpoint still exists (admin/back-office use).
- Pharmacy branch detail (`GET /v1/pharmacy-branches/{branchId}`) — added
  2026-08-25 (`pharmacy_branch.dart` / `pharmacy_branch_dto.dart` /
  `pharmacy_branch_repository*.dart` / `get_pharmacy_branch_usecase.dart` /
  `pharmacy_branch_providers.dart` / `pharmacy_branch_details_screen.dart`).
  Originally built under a separate `lib/features/pharmacy_profile/`
  folder by a parallel workstream; reconciled during integration into this
  feature (`provider_profile`) alongside the sibling `clinic_branch_*` and
  `pharmacy_profile.dart` slices, to keep one canonical location for all
  provider-directory entity types — imports updated accordingly. Matches
  `GetPharmacyBranchUseCase`'s raw `PharmacyBranchWithRelations` shape
  (branch + `address` + parent `pharmacy`). Route:
  `/patient/pharmacy-branches/:branchId` (`patientPharmacyBranchDetails`),
  wired in `pharmacy_routes.dart`. Mock handler:
  `registerPharmacyBranchMocks`. Read-only screen with a stub "order
  medicine" CTA (actual ordering flow is `pharmacy_booking`, out of scope
  here). Added 2026-08-29: this screen now also accepts an optional
  `onSelect` callback (mirrors the old `PharmacyDetailsScreen`'s "select and
  continue" bar) — see `pharmacy_booking/STATUS.md` for the new
  `GET /v1/pharmacy-branches/search` (`clinic-reservations` File 12 Part 37)
  that now drives `pharmacy_booking`'s branch list end to end.

All five of the above endpoints are `@OptionalAuth()` on the real backend
and 404 non-admin callers for non-`VERIFIED`/deleted rows — none of this
was independently re-verified via Serena (its TS language server was
unavailable to every builder agent in this pass; verification fell back to
direct `Read` of clinic-reservations source, which is read-only and safe,
but flagging that the mandated Serena-only backend-exploration rule
couldn't be honored this round).

Appointment hold/confirm/cancel/reschedule on top of these slots now lives
in `lib/features/appointments` — see the `affiliationId` note above for how
`doctor_details_screen` hands off into it.

## Verified against a real local backend, 2026-08-25

All 5 clinic/pharmacy/branch endpoints above were re-verified end to end
against a real running `clinic-reservations` (local Postgres via
`docker-compose`, migrations applied, demo clinic/pharmacy seeded — not just
`MockInterceptor`):
- Fixed a real bug found during verification: the 5 new plain providers
  (`clinicProfileProvider`, `clinicBranchProvider`, `pharmacyProfileProvider`,
  `pharmacyBranchProvider`, and `core/specialties`'s `specialtiesProvider`)
  used `retry: null` intending "no retries" — riverpod 3.3.2 treats an
  explicit `null` as *unset* and falls through to the default ~34s/10-retry
  backoff, so a genuine fetch failure took 30s+ to surface as an error
  instead of immediately. Fixed to `retry: (retryCount, error) => null`.
- Navigation wiring added (2026-08-25): `ClinicDetailsScreen`/
  `PharmacyDetailsScreen`'s branch cards pushed to their branch-detail
  screen, whose header linked back up to the parent. **Removed 2026-08-28**
  along with the parent screens themselves (see above) — a branch is now
  the sole unit browsed and detailed, with no parent page to round-trip
  through.
- `DoctorDetailsScreen`'s "about" card now hides entirely when a doctor has
  no `bio` and no qualifications/fellowships (seeded/demo doctors commonly
  have none) instead of rendering a header with visibly empty content.
- Phone numbers rendered as static text (branch `phone`, the OTP-verify
  screens, doctor registration review) are now wrapped in
  `AppFormatters.ltrIsolate` — an Arabic (RTL) layout was bidi-reordering a
  raw `+20 ...` string into visibly scrambled digit order.

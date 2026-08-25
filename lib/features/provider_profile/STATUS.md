# Feature status: provider_profile

**Label:** `PARTIAL` (doctor detail: `BACKEND_READY`-shaped but unverified
wire format; availability: `BACKEND_READY`)

- Doctor detail (`GET /v1/doctors/{id}`) — calls the real Phase 2 contract,
  but the frontend's `DoctorProfileDto` assumes a flat, snake_case JSON
  shape that hasn't been verified against the real backend's actual
  response, which returns raw Prisma model shapes for `affiliations` (not a
  dedicated response DTO) — see
  `med-super/docs/backend_frontend_parity_matrix.md`. Verify before
  pointing at a real backend.
- Availability (`GET /v1/doctors/{doctorId}/slots`) — added 2026-08-14,
  matches the real, tested backend Phase 3 contract exactly (verified
  against `GetDoctorSlotsUseCase`'s response shape). No hold/booking
  affordance (Phase 4 doesn't exist). Timezone conversion is a fixed
  `Africa/Cairo` (+2:00) offset, not a general IANA converter — no
  timezone/tzdata package exists in `pubspec.yaml`; any other
  `ianaTimezone` value falls back to a UTC-labeled display rather than
  silently mislabeling it. See
  `lib/features/provider_profile/domain/utils/slot_grouping.dart`.
- `clinicBranchId`/`ianaTimezone` on `DoctorProfile` are currently
  mock-only fields (`branch-{doctorId}` / `'Africa/Cairo'`) standing in for
  what the real doctor-detail response should expose once its wire format
  is confirmed.
- Clinic detail (`GET /v1/clinics/{clinicId}`) — added 2026-08-25
  (`clinic_profile.dart` / `clinic_profile_dto.dart` /
  `clinic_repository*.dart` / `clinic_providers.dart` /
  `clinic_details_screen.dart`). Mirrors `GetClinicUseCase`'s raw-Prisma
  passthrough shape (`legal_name`/`brand_name`/`tax_id`/`region_code`/
  `status`/`branches[].address`), no dedicated backend response DTO. Route:
  `/patient/clinics/:clinicId` (`patientClinicDetails`), wired in
  `search_routes.dart`. Mock handler: `registerClinicMocks`.
- Clinic branch detail (`GET /v1/clinic-branches/{branchId}`) — added
  2026-08-25 (`clinic_branch.dart` / `clinic_branch_dto.dart` /
  `clinic_branch_repository*.dart` / `get_clinic_branch_usecase.dart` /
  `clinic_branch_providers.dart` / `clinic_branch_details_screen.dart`).
  Matches `GetClinicBranchUseCase`'s raw `ClinicBranchWithRelations` shape
  (branch + `address` + parent `clinic`). Route:
  `/patient/clinic-branches/:branchId` (`patientClinicBranchDetails`),
  wired in `search_routes.dart`. Mock handler: `registerClinicBranchMocks`.
- Pharmacy detail (`GET /v1/pharmacies/{pharmacyId}`) — added 2026-08-25
  (`pharmacy_profile.dart` / `pharmacy_profile_dto.dart` /
  `pharmacy_repository*.dart` / `pharmacy_providers.dart` /
  `pharmacy_details_screen.dart`), file-for-file mirror of the clinic-detail
  slice. Matches `GetPharmacyUseCase`'s raw Prisma passthrough shape
  (near-identical to `Clinic`, plus `branches[].delivery_capable`). Route:
  `/patient/pharmacies/:pharmacyId` (`patientPharmacyDetails`), wired in
  `pharmacy_routes.dart`. Mock handler: `registerPharmacyProfileMocks`.
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
  here).

All five of the above endpoints are `@OptionalAuth()` on the real backend
and 404 non-admin callers for non-`VERIFIED`/deleted rows — none of this
was independently re-verified via Serena (its TS language server was
unavailable to every builder agent in this pass; verification fell back to
direct `Read` of clinic-reservations source, which is read-only and safe,
but flagging that the mandated Serena-only backend-exploration rule
couldn't be honored this round).

**Do not build:** appointment hold/confirm/cancel on top of these slots —
Phase 4 doesn't exist yet.

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
- Navigation wiring added: `ClinicDetailsScreen`/`PharmacyDetailsScreen`'s
  branch cards now push to their branch-detail screen; the branch-detail
  screens' header (clinic/pharmacy name) links back up to the parent via
  `clinicId`/`pharmacyId`. Both directions use `context.pushReplacement`,
  not `context.push` — a plain push would let clinic→branch→clinic→branch
  taps grow the navigation stack without bound.
- `DoctorDetailsScreen`'s "about" card now hides entirely when a doctor has
  no `bio` and no qualifications/fellowships (seeded/demo doctors commonly
  have none) instead of rendering a header with visibly empty content.
- Phone numbers rendered as static text (branch `phone`, the OTP-verify
  screens, doctor registration review) are now wrapped in
  `AppFormatters.ltrIsolate` — an Arabic (RTL) layout was bidi-reordering a
  raw `+20 ...` string into visibly scrambled digit order.

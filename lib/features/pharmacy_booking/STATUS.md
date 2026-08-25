# Feature status: pharmacy_booking

**Label:** `DESIGN_ONLY`

Backend Pharmacy Fulfillment (Phase 7) is `NOT STARTED`. The Flutter
feature map allows this: *"Pharmacy fulfillment | 7 | Not built | Design
ahead only."* This feature is within that allowance — but its execution is
sloppier than `lab_booking`'s: there is **no data layer at all** (no
`data/` directory), no `MockInterceptor` registration, and no network calls
of any kind. All "pharmacies" shown are a hardcoded in-memory list behind
an artificial `Future.delayed`.

**Before going further:** either wire this through `MockInterceptor` like
every other feature (for consistency and so `dio_client.dart`'s interceptor
chain is actually exercised), or clearly mark the UI as a static prototype.
Do not connect the pharmacy *search/select* flow to a real backend endpoint
— Pharmacy Fulfillment (Phase 7) still doesn't exist, so there is still no
`GET /v1/pharmacies/search`-equivalent to call.

**Partial exception, added 2026-08-25:** `PharmacySelectScreen`'s cards now
have an optional drill-down — tapping a pharmacy's name/address (not the
"اختر" CTA) opens `provider_profile`'s real `PharmacyDetailsScreen`
(`GET /v1/pharmacies/:id`, **Provider Directory / Phase 2**, a different,
already-complete backend module — not Pharmacy Fulfillment/Phase 7), with a
"select and continue" action wired back into this flow via the route's
`extra`. This only works because `mockPharmacies`' 3 entries were given
fixed real UUIDs matching demo pharmacies seeded in `clinic-reservations`'
`db/seed.ts` — the list itself is still 100% hardcoded, just pointing at
real ids instead of placeholder strings like `'ph1'`.

## Not affected by ADR-006

`ADR-006-PROVIDER-SURFACE-SPLIT.md` (2026-08-14) routes future **pharmacy
dashboard** (pharmacy *staff* operations) work to a separate Next.js web
app. This feature is the *patient-facing* booking flow, a different
surface — unaffected either way. It stays gated on backend Phase 7
(Pharmacy Fulfillment), not on any Flutter-vs-Next.js question.

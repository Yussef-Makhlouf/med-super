# Feature status: pharmacy_booking

**Label:** `PARTIAL` (list + drill-down: `BACKEND_READY`; order review/confirmation/upload: still mocked, Phase 7 doesn't exist)

Backend Pharmacy Fulfillment (Phase 7 — order broadcast/accept/fulfillment) is still `NOT STARTED`. What changed 2026-08-29: the pharmacy-*selection* half of this flow no longer needs Phase 7 at all — it was never really a Pharmacy Fulfillment concern, it's Provider Directory's own "which branch is this" question, and Provider Directory (Phase 2) already has a real, complete backend. **Do not** read this as Phase 7 progress; the order-review/confirmation/upload screens downstream of selection are still 100% mocked, and stay that way until Phase 7 exists.

## Branch list (`GET /v1/pharmacy-branches/search`), added 2026-08-29

`clinic-reservations` had no pharmacy-search endpoint at all until File 12 Part 37 added one on `PharmacyBranchesController` — same gap-filling process Part 32 used for `GET /v1/doctors/search`. `pharmaciesProvider` (`pharmacy_search_providers.dart`) now calls it for real via a new `data/` layer (`PharmacyBranchSearchRemoteDatasource`/`PharmacyBranchSearchItemDto`) — this feature finally has a data layer and a `MockInterceptor` registration (`registerPharmacyBranchSearchMocks`), closing the gap this file used to flag.

Consequences of wiring real data, all deliberate:
- **`rating`/`ratingCount`/live open-closed status were removed from `Pharmacy` and `PharmacyCard` entirely** (2026-08-29) — `pharmacy_branches`/`pharmacies` have no reviews table and no operating-hours column, so there is nothing to back those fields with. Showing them anyway would mean fabricating data, which this codebase avoids elsewhere too (see `clinic-reservations`' own "never invent a business constant" rule, File 12 Part 12) — removed rather than faked.
- **The filter chip bar (`PharmacyFilterChipBar`, "مفتوح الآن"/"الأعلى تقييماً") was deleted along with it** — both chips filtered/sorted on the now-removed fields; the third ("الأقرب إليك") is now the only dimension and no longer needs a chip UI to select between alternatives.
- **`distanceKm` is real now**, sourced from the endpoint's PostGIS `ST_Distance` calculation — `pharmaciesProvider` best-effort reads the device's location via `ClinicLocationService` (reused from `provider_registration`, the same wrapper `PharmacyMapView`'s "locate me" button already uses) and passes `lat`/`lng` to the search call. If location is denied/unavailable, the search still runs (no `lat`/`lng`), every result's `distanceKm` comes back null, and `PharmacyCard` hides its distance row rather than showing a stale/fabricated number. The list still sorts nearest-first, unknown-distance results last.
- Each list entry is a *branch*, not a pharmacy chain — the same chain can have more than one branch, and only a branch has an address/phone to fulfil an order against. Tapping a card's name/address (not the "اختر" CTA) opens `provider_profile`'s `PharmacyBranchDetailsScreen` directly (`GET /v1/pharmacy-branches/:id`), no intermediate "pharmacy" page (that parent screen/route was removed 2026-08-28, see `provider_profile/STATUS.md`), with a "select and continue" action wired back via the route's `extra`.

**Still out of scope / unchanged:** everything past selection (`pharmacy_order_review_screen.dart` onward) — no network layer, no `MockInterceptor` registration, Phase 7-gated as before.

## Not affected by ADR-006

`ADR-006-PROVIDER-SURFACE-SPLIT.md` (2026-08-14) routes future **pharmacy
dashboard** (pharmacy *staff* operations) work to a separate Next.js web
app. This feature is the *patient-facing* booking flow, a different
surface — unaffected either way. Its order/fulfillment half stays gated on
backend Phase 7 (Pharmacy Fulfillment), not on any Flutter-vs-Next.js
question.

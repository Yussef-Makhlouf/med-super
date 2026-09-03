# Feature status: search_discovery

**Label:** `BACKEND_READY`

Calls `GET /v1/doctors/search` (fixed 2026-08-14 — previously called the
non-existent `/v1/search/doctors`), matching backend Phase 2 (COMPLETE).
Supports `q`, `specialty`, `sort`, `cursor`, `limit`; `latitude`/`longitude`/
`radiusKm`/`date` are plumbed through the repository/datasource layer but
unused by any current screen (no location-picker/date-picker UI exists yet
— not invented here). Cursor pagination is contract-correct end to end
(including in the mock) but no "load more" UI consumes `nextCursor` yet.

Runs against `MockInterceptor` by default; contract-verified against the
real backend's documented shape (`05_API_RULES.md`, `04_API_CONTRACT.md`).

**2026-08-25:** the specialty filter now receives the real specialty's
display name via a `title`/`initialSpecialtyName` param (from `home`'s real
`GET /v1/specialties` list) instead of resolving `specialties.$code`.tr()
against a fixed translation catalog that couldn't match an arbitrary
backend code. `DoctorResultCard` (this feature's result-row widget) also
got a color/hover refresh and is now reused as-is by `home`'s
featured-doctors row — no visual-language fork between the two screens.

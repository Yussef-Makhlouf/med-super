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

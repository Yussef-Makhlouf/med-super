# Feature status: home

**Label:** `DESIGN_ONLY` (shell/navigation only) — **except the patient home
screen's specialties row and featured-doctors row, which are real
(`BACKEND_READY`), added 2026-08-25:**
- ✅ Specialties row — `GET /v1/specialties` (via `core/specialties/`),
  replaces the old hardcoded 5-item list.
- ✅ Featured doctors row — reuses `search_discovery`'s
  `SearchDoctorsUseCase` (`GET /v1/doctors/search`, top-rated, capped to 5),
  replaces the old hardcoded `_mockDoctors` list. Same `DoctorResultCard`
  widget as the search screen, so it renders identically in mock and real
  backend modes.

App shell and tab navigation otherwise. The `appointments` screen here is now
wired to the real Phase 4 flow (see `lib/features/appointments/`, not this
folder); the `orders` tab is real (pharmacy + lab lists). The `notifications`
tab is wired to `lib/features/notifications/` (`GET/PATCH /v1/notifications`).

**Visual refresh (2026-09-24):** the patient home now leads with doctor search,
appointments, prescription upload, and wallet actions. All four quick actions
now use coordinated local illustrations; the two new compact assets are
transparent and optimized for card display. Their artwork is decorative and
excluded from semantics so screen readers announce each action once. The care
illustration is bundled locally; specialties and featured doctors still use
the same real providers and search card. No new API fields or sample health
data were added.

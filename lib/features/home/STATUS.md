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

App shell and tab navigation otherwise. `appointments`/`orders`/`notifications`
screens here are intentionally static placeholders (`*_placeholder_screen.dart`)
— Phase 4 (Appointments), Payments, and Notifications don't exist on the
backend yet. Do not wire these to real or mock network calls until the
owning feature (not `home`) is built against a real backend phase.

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

**Patient home service and specialty artwork (2026-09-25):** added a dedicated
lab-testing card that opens the existing `/patient/lab/upload` flow; it does
not claim to offer direct test-catalog selection. Five locally bundled
transparent illustrations cover the home specialties (cardiology, pediatrics,
dermatology, dental, and ophthalmology). The live catalog uses UUID codes, so
artwork selection also checks the existing Arabic specialty names and falls
back to the established icon for unknown entries. The doctor-search hero
button now explicitly uses white foreground styling for its label and icon.

**Specialty and order display refresh (2026-09-25):** added coordinated local
artwork for the other 16 specialties in the backend seed catalog. The home row
maps specialty UUIDs through their Arabic catalog names and uses icon fallback
for any specialty added later. The mock specialty catalog now mirrors the
backend's 21 seeded names. Specialty tiles use larger rounded artwork on home
and a responsive illustrated grid on the full list. Patient pharmacy and lab
order cards now use service illustrations, logical RTL status borders, and
available real summary data such as lab test names, collection method, pharmacy
quote notes, status, date, and price. No extra backend data or staff actions
were added.

**Orders navigation polish (2026-09-24):** the patient orders header now uses
the localized guest name and accessible profile/notification actions. Pharmacy
and lab tabs have announced selected states and 48dp touch height; the order
search field exposes a localized clear action.

**Service discovery refresh (2026-09-25):** replaced the single home hero and
duplicated quick-action grid with a swipeable, five-page service carousel for
doctor search, prescription upload, lab requests, appointments, and wallet.
Each page opens its existing route, with the pharmacy draft reset retained.
Carousel controls have expanded touch targets, localized English/Arabic labels,
and dynamic height for larger text. Main home content is capped and centered on
wide screens while remaining full-width on phones. Service discovery reuses
existing app capabilities; no new backend services are implied.

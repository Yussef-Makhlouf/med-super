# Feature status: lab_booking

**Label:** `PARTIAL` — un-blocked 2026-09-05

Previously `BLOCKED`: this feature was built against two invented,
mock-only endpoints (`GET /v1/lab-partners`, `POST /v1/lab-bookings`) with
no real backend counterpart. The backend Laboratory domain was itself
un-postponed 2026-09-02 (`clinic-reservations` File 12 Part 47/48) and
connected to `medsuper-laboratory-dashboard` (the lab **staff** console),
but this patient-facing feature stayed blocked until now — the explicit
un-defer decision this label required (per the old `BLOCKED` note) is the
user's 2026-09-05 request to connect the app and dashboard end-to-end.

## What's real now

- **Branch discovery**: `GET /v1/lab-branches/search` — new, additive
  backend endpoint added the same day (`SearchLabBranchesUseCase`,
  mirroring `provider-directory`'s pharmacy branch search exactly) since
  nothing let a patient discover a branch before this — the existing
  `GET /lab-branches/{id}` is `LAB_STAFF`-self-only. Real PostGIS
  distance sort when device location is available, name sort otherwise.
- **Request creation**: `POST /v1/lab-orders`, via the `prescriptionId`
  path — the upload step calls the same real
  `POST /v1/prescriptions/upload` endpoint `pharmacy_booking` already uses
  (`PrescriptionRemoteDatasource`, reused directly rather than duplicated),
  then passes the resulting `prescriptionId` into the lab order alongside
  `labBranchId`/`collectionType`.
- **Status tracking**: `GET /v1/lab-orders` (the "طلبات" tab's المعمل
  sub-tab, `home/orders_placeholder_screen.dart`) and
  `GET /v1/lab-orders/:id` (`LabOrderDetailScreen`) — the real state machine
  (`REQUESTED → QUOTED → AWAITING_SAMPLE → IN_ANALYSIS → RESULTS_READY`, or
  a `REJECTED`/`CANCELLED` side path), including the quote (price/
  appointment/prep instructions) once staff sets it and the booking code
  once confirmed.

Provider lab referrals (2026-09-23) use the same image-upload pipeline and
link the uploaded `LAB_REFERRAL` document to the provider-created lab order.
That order enters the existing branch intake queue; the existing detail
contract returns its linked images. Provider history renders those images,
while the backend remains authoritative for access and status.

## What's deliberately gone (was fabricated, not backed by real data)

Removed rather than kept as dead/misleading UI: lab rating, "starting
price", payment-method selection, and home-collection day/time/address
scheduling. None of these exist on the real backend — no ratings table, no
lab price catalog, payment is explicitly out of scope (`DEC-002`), and
price/appointment/prep instructions are only ever set later by lab staff
via `SubmitLabQuoteUseCase`, never chosen by the patient at request time.

## Product decision: no test catalog

The user explicitly excluded any test catalog on 2026-09-25. Requests are
created only from an uploaded referral linked by `prescriptionId`; neither
the patient app nor provider surfaces expose a test picker or catalog API.
Historical order item names remain readable for existing results.

## Not affected by ADR-006

`ADR-006-PROVIDER-SURFACE-SPLIT.md` (2026-08-14) routes lab **staff**
operations to `medsuper-laboratory-dashboard`, a separate Next.js app.
That's unchanged — this feature is the distinct patient-facing booking/
tracking flow, analogous to how patient doctor-search is distinct from the
doctor dashboard.

## Live order status refresh

Patient lab order lists and order details refresh from the API every 15
seconds while visible and foregrounded, with an immediate refetch on app
resume. Polling pauses while the app or screen is inactive; the API remains
the source of truth.

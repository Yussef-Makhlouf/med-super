# Feature status: lab_booking

**Label:** `BLOCKED` — do not extend

`MedSuper_Flutter_Documentation_Pack/11_FEATURE_MAP.md` is explicit:

> Laboratory | Deferred | Not built | **Do not implement**

This is stricter than the "design ahead only" guidance given to
Appointments/Payments/Prescriptions/Pharmacy — Laboratory isn't even
scheduled on the backend roadmap (schema-only, in
`prisma/schema/postponed.prisma`, alongside Reviews/Fraud/Analytics/Family
Accounts). This feature was nonetheless fully built (domain, data,
presentation, 34 tests, translations) against two invented, mock-only
endpoints (`GET /v1/lab-partners`, `POST /v1/lab-bookings`) with zero real
backend counterpart and none planned.

**Do not add screens, endpoints, or business logic to this feature.** It
stays as committed history until Laboratory is explicitly un-deferred by
the product/engineering decision register (see
`med-super/docs/backend_frontend_parity_matrix.md`, finding D5/G5).

## Not affected by ADR-006

`ADR-006-PROVIDER-SURFACE-SPLIT.md` (2026-08-14) routes future
**laboratory dashboard** (lab *staff* operations) work to a separate
Next.js web app. That's a different surface from this feature, which is
the *patient-facing* booking flow — analogous to how patient doctor-search
is distinct from the doctor dashboard. This feature's block is about the
backend Laboratory *domain* being deferred entirely, not about which
framework should host it. Un-deferring Laboratory on the backend is the
prerequisite here, not ADR-006.

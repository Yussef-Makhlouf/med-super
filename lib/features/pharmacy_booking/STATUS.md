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
Do not connect this to a real backend endpoint — none exists.

## Not affected by ADR-006

`ADR-006-PROVIDER-SURFACE-SPLIT.md` (2026-08-14) routes future **pharmacy
dashboard** (pharmacy *staff* operations) work to a separate Next.js web
app. This feature is the *patient-facing* booking flow, a different
surface — unaffected either way. It stays gated on backend Phase 7
(Pharmacy Fulfillment), not on any Flutter-vs-Next.js question.

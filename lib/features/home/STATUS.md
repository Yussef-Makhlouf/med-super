# Feature status: home

**Label:** `DESIGN_ONLY` (shell/navigation only)

App shell and tab navigation. `appointments`/`orders`/`notifications`
screens here are intentionally static placeholders (`*_placeholder_screen.dart`)
— Phase 4 (Appointments), Payments, and Notifications don't exist on the
backend yet. Do not wire these to real or mock network calls until the
owning feature (not `home`) is built against a real backend phase.

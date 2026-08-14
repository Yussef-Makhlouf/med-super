# Feature status: profile_settings

**Label:** `MOCKED`

Uses the `auth` feature's repository (`PATCH /v1/auth/me`) under the hood.
That endpoint is **not** in the backend's confirmed Phase 1 endpoint list —
verify it exists on the real backend before relying on it outside mock
mode (see `auth/STATUS.md` and
`med-super/docs/backend_frontend_parity_matrix.md`).

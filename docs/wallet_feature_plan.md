# Wallet (المحفظة) Feature — Implementation Plan

Branch: `connectbackend`
Screenshots: [`docs/design_screenshots/wallet/`](design_screenshots/wallet/) (copied from `~/OneDrive/Desktop/المحفظة`, renamed `01_..07_` in flow order)

## What this is

A new "Wallet" entry point reachable from the doctor/provider profile tab, plus its full flow: balance dashboard, add-balance (3-step stepper), transaction detail, and a refund request + status-tracking pair. Nothing wallet-related exists in the codebase today (confirmed: no `wallet` directory, no route, no mock endpoint — see Survey below). This is new feature work, not an edit to something partial.

## Survey of current state (facts, not opinions)

- Provider profile tab: `lib/features/provider_dashboard/presentation/screens/provider_profile_screen.dart`. Menu tiles built with the private `_buildNavTile(...)` helper (lines 202–266); four tiles exist today (lines 120–170: personal info, clinic settings, schedule, security), each navigating via plain `Navigator.of(context).push(MaterialPageRoute(...))` — **no go_router route is registered for any of them**. Same pattern to follow for the wallet tile.
- Reusable stepper: `lib/core/widgets/step_progress_header.dart` (`StepProgressHeader` — already shared by Lab Booking (3 steps) and Doctor Registration (4 steps)). The wallet deposit flow is a 3-step version of the same widget — **reuse it directly, do not build a new stepper.**
- No existing wallet/payments/transactions feature, route, or mock endpoint anywhere in `lib/`. `المحفظة`/"wallet" appears only as a caption string in `assets/translations/{en,ar}.json` and as *future* scope in the SRS/architecture docs — none of it is built.
- Feature module convention (per `CLAUDE.md`): every feature under `lib/features/` has `domain/`, `data/`, `presentation/`, and a `STATUS.md` stating its build state. Follow it for `lib/features/wallet/`.
- Mock API convention: add wallet endpoints to `lib/core/network/mock/mock_responses.dart` via a new `registerWalletMocks()`, registered in the same call chain as `registerAvailabilityMocks`/`registerSearchMocks`. Watch registration-order (more specific paths, e.g. `/v1/wallet/transactions/{id}`, before broader ones, e.g. `/v1/wallet/transactions`).
- Localization: add every user-facing string to **both** `assets/translations/en.json` and `ar.json`, accessed via `.tr()`. Do not hardcode strings (provider_dashboard already has ~25 that bypass this — don't add more).
- No new route strictly required for launch (sibling profile screens all use `Navigator.push`), but the wallet dashboard is a multi-screen sub-flow, not a single screen, so it gets its own internal `Navigator` push stack from the profile tile; no `GoRouter` route needed unless deep-linking is requested later.

## Screens (mapped to screenshots, in flow order)

| # | Screenshot | Screen | Notes |
|---|---|---|---|
| 1 | `01_wallet_dashboard.png` | `WalletDashboardScreen` | Balance card (رصيد متاح + transfer/deposit buttons), 3 quick-action tiles (بطاقات مرتبطة / سجل المعاملات / دفع الفواتير), "أحدث المعاملات" list with "عرض الكل" |
| 2 | `02_deposit_step1_amount.png` | `WalletAddBalanceScreen` | Stepper step 1/3. Preset amount chips (100/200/500/1000) + custom amount field, live "new balance" preview |
| 3 | `03_deposit_step2_payment_method.png` | `WalletPaymentMethodScreen` | Stepper step 2/3. Payment method radio list (saved card, new card, Apple Pay) |
| 4 | `04_deposit_success.png` | `WalletDepositSuccessScreen` | Terminal screen (step 3 collapses into success state) — transaction receipt summary + "العودة للمحفظة" |
| 5 | `05_transaction_detail.png` | `WalletTransactionDetailScreen` | Full transaction breakdown (service, doctor, date, fees, net amount) + download-receipt / help actions |
| 6 | `06_refund_request_form.png` | `WalletRefundRequestScreen` | Refund reason radio group + free-text detail field + submit |
| 7 | `07_refund_status_tracking.png` | `WalletRefundStatusScreen` | Timeline/status tracker (submitted → under review → approved → transferred) + support CTA |

## Module layout (`lib/features/wallet/`)

```
domain/
  entities/ wallet_balance.dart, wallet_transaction.dart, deposit_request.dart, refund_request.dart
  repositories/ wallet_repository.dart
data/
  models/ (json models mirroring the entities)
  datasources/ wallet_remote_datasource.dart   // Dio calls, hits MockInterceptor in dev
  repositories/ wallet_repository_impl.dart
presentation/
  controllers/ wallet_providers.dart           // plain Provider/FutureProvider.family, no codegen needed (same style as doctor_availability_providers.dart)
  screens/ the 7 screens above
  widgets/ balance_card.dart, quick_action_tile.dart, transaction_list_tile.dart, amount_chip.dart   // shared across dashboard + deposit + detail screens, reused rather than duplicated per screen
STATUS.md   // DESIGN_ONLY or MOCKED — set once data layer is wired to mock endpoints
```

Reuse checklist (do not rebuild any of these):
- `StepProgressHeader` (`lib/core/widgets/step_progress_header.dart`) for the deposit stepper (3 labels: المبلغ / طريقة الدفع / تأكيد).
- `AppButton` (used for the outlined/filled buttons across `provider_dashboard`) for all primary/secondary buttons.
- `AppColors` theme tokens — do not introduce new hardcoded hex colors beyond what a screenshot literally requires.
- The `_buildNavTile`-style card/tile visuals already in `provider_profile_screen.dart` for the wallet's own quick-action tiles, adapted into a shared `quick_action_tile.dart` widget rather than copy-pasted.

## Profile-tab integration

In `provider_profile_screen.dart`, insert a new nav tile after the "الأمان والخصوصية" tile (after line 170, before the `SizedBox(height: 36)` / logout button at line 171):

```dart
_buildNavTile(
  icon: Icons.account_balance_wallet_outlined,
  iconBg: const Color(0xFFEFF6FF),
  iconColor: brandBlue,
  title: 'المحفظة',
  subtitle: 'الرصيد والمعاملات المالية',
  onTap: () => Navigator.of(context).push(
    MaterialPageRoute(builder: (_) => const WalletDashboardScreen()),
  ),
),
```

## Mock backend

Add to `lib/core/network/mock/mock_responses.dart`:
- `GET /v1/wallet/balance`
- `GET /v1/wallet/transactions` (list)
- `GET /v1/wallet/transactions/{id}` (detail — register **before** the list pattern)
- `POST /v1/wallet/deposits`
- `POST /v1/wallet/refunds`
- `GET /v1/wallet/refunds/{id}` (status tracking)

## Workflow (agent breakdown)

One agent per page plus setup/integration/QA agents, each scoped to avoid file collisions:

1. **Setup agent** — scaffolds `lib/features/wallet/domain` + `data` (entities, repository, mock datasource, mock endpoint registration) + `STATUS.md`. Everyone else depends on this landing first.
2. **Page agents (parallel, one file each, run after Setup):**
   - Agent A → `WalletDashboardScreen` + `balance_card.dart` + `quick_action_tile.dart` + `transaction_list_tile.dart`
   - Agent B → `WalletAddBalanceScreen` (stepper step 1) + `amount_chip.dart`
   - Agent C → `WalletPaymentMethodScreen` (stepper step 2)
   - Agent D → `WalletDepositSuccessScreen`
   - Agent E → `WalletTransactionDetailScreen`
   - Agent F → `WalletRefundRequestScreen`
   - Agent G → `WalletRefundStatusScreen`
3. **Integration agent** — wires the profile-tab nav tile, connects screen-to-screen navigation (dashboard → add balance → payment method → success; dashboard → transaction detail; transaction detail → refund request → refund status), adds both translation keys to `en.json`/`ar.json`.
4. **Test agent(s)** — one widget test per screen under `test/features/wallet/`, matching this repo's existing per-feature test convention.
5. **Final QA agent** — runs on the fully-merged branch: `flutter analyze`, `flutter test`, confirms `en.json`/`ar.json` stay symmetric, confirms no hardcoded user-facing strings were introduced, confirms mock endpoint registration order is correct. Reports pass/fail; nothing is considered done until this agent is green.

## Out of scope / explicit non-goals

- No real backend integration — `clinic-reservations` has no wallet endpoints (capped at Phase 3/Availability); this stays mock-only, same as `provider_dashboard`.
- No changes to `lab_booking` (BLOCKED) even though it has an unrelated `LabPaymentMethod` type.
- No go_router route additions unless a later requirement needs the wallet deep-linkable from a push notification or external link.

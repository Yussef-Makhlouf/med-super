# Wallet Feature Module Status

State: `PARTIAL` — the reads and top-up initiation are wired to the real backend; the remaining writes (transfer/refund) are still mock-only.

## Backend-backed (real `clinic-reservations` endpoints, File 12 Part 50.3)

| Endpoint | Wired via | Notes |
|---|---|---|
| `GET /v1/wallet` | `WalletRemoteDatasource.getBalance` | `{walletId, balance, currency}`. A user who never topped up gets a zero balance, not a 404. |
| `GET /v1/wallet/transactions` | `WalletRemoteDatasource.getTransactions` | Cursor-paginated (`cursor`/`limit`, default 20). Only the first page is consumed today — `WalletTransactionPage.nextCursor` is parsed but no screen pages through it yet. |
| `POST /v1/wallet/top-up` | `WalletRemoteDatasource.initiateTopUp` | Card-only; takes `{amount: "300.00", customer: {firstName,lastName,email,phone}}` and returns `{walletTransactionId, paymentIntentId, redirectUrl}`. **Starts** a payment, doesn't complete one — see below. |

Both are `PATIENT`-role only and bearer-authenticated.

Shape notes that bit once and will again: keys are **camelCase**, money arrives as
fixed 2-decimal **strings** (`"350.00"`), and enums are SCREAMING_SNAKE
(`TOP_UP`/`APPOINTMENT_PAYMENT`/`REFUND`, `PENDING`/`COMPLETED`/`FAILED`).

### Deliberate absences

- **No per-transaction endpoint exists.** `GET /v1/wallet/transactions` is the
  whole ledger read, so `walletTransactionDetailProvider` resolves its
  transaction out of the already-loaded page instead of calling a route that
  doesn't exist.
- **A wallet transaction is a ledger row, not a receipt.** The backend returns
  no title, service name, doctor name, fee breakdown, VAT line, or payment
  method for a wallet movement. Those fields used to exist on the entity,
  populated purely by mock data; they've been removed. Transaction labels are
  now derived from the type (`walletTransactionTypeLabelKey`). Don't reintroduce
  them without a backend field to back them.
- `pendingBalance` is gone for the same reason — the backend exposes a single
  `balance`.

## Mock-only (no backend counterpart at all)

These still hit `MockInterceptor` on invented paths and will 404 the moment
`BASE_URL` points at a real server:

- `POST /v1/wallet/transfers` + the transfer-out flow — the wallet is prepaid
  only; there is no transfer/withdraw concept on the backend. `TransactionType.withdrawal`
  and the mock's `WITHDRAWAL` type exist solely for this flow.
- `POST /v1/wallet/refunds`, `GET /v1/wallet/refunds/{id}` — refunds are
  system-initiated on cancellation (`ProcessCancellationRefundUseCase`), not
  patient-requested. There is no refund-request API.
- Linked cards and pay-bills screens — design-only, no endpoint of any kind.

## Top-up stops at the checkout URL

The 3-step flow is now amount → billing details → review, and the review
step calls the real endpoint. What it *cannot* do is finish the payment:
`redirectUrl` is a Paymob iframe, and the app still has neither
`webview_flutter` nor `url_launcher`. So `WalletTopUpPendingScreen` shows
the URL for copying and says plainly that the balance won't move until the
payment is confirmed — which is the truth, since only the capture webhook
credits it (`ProcessWalletTopUpUseCase`).

The saved-card picker that used to be step 2 (Visa ****4242 / Apple Pay)
was **deleted**, not rewired: the real endpoint is card-only and takes no
payment-method parameter, so there was nothing behind those options. What
it does require — `customer` — nothing collected before now.

Adding an in-app browser is the one remaining piece; nothing else about
this flow needs to change when it lands.

## Spending the wallet

`POST /v1/appointments/{holdId}/confirm` with
`paymentMethod: INTERNAL_WALLET` is how the balance actually gets spent,
and it is wired now — `BookingConfirmScreen`'s payment-method picker sends
it (optionally with a `paymentAmount` string for a partial debit), and the
balance/transaction providers are invalidated on success. See
`appointments/STATUS.md`.

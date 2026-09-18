# MedSuper — Flutter Client

Healthcare super-app Flutter client. Two flavors: **patient** and **provider** (doctor/clinic). Backend: mock API by default (no server needed).

---

## Run

```bash
# Patient app
flutter run --flavor patient -t lib/main_patient.dart

# Provider app
flutter run --flavor provider -t lib/main_provider.dart
```

Or use the VS Code launch configurations in `.vscode/launch.json` (select from the Run & Debug panel).

---

## Code generation

Run after any change to `@freezed`, `@riverpod`, `@JsonSerializable`, or `@RestApi` annotated files:

```bash
dart run build_runner build
```

Watch mode (auto-regenerates on save):

```bash
dart run build_runner watch
```

---

## Architecture

Two-flavor, Clean Architecture, Riverpod 3 DI. See [`MedSuper_Flutter_Architecture.md`](MedSuper_Flutter_Architecture.md) for the full spec.

```
lib/
├── main_patient.dart       # entry — sets Flavor.patient
├── main_provider.dart      # entry — sets Flavor.provider
├── bootstrap.dart          # shared startup: Hive, Firebase, l10n, runApp
├── app/
│   ├── app.dart            # MaterialApp.router + theme + locale + responsive
│   ├── flavor.dart         # Flavor enum + global accessor
│   └── router/             # GoRouter per flavor, auth guard
├── core/
│   ├── config/             # AppConfig, EnvKeys
│   ├── constants/          # api paths, hive box names, storage keys, durations
│   ├── error/              # Failure (sealed), Result<T>, ApiException
│   ├── network/            # DioClient + interceptors + mock seam
│   ├── storage/            # HiveService, SecureStorageService, CachePolicy, Outbox
│   ├── notifications/      # FCM, priority router, local notifications
│   ├── crash/              # CrashlyticsService
│   ├── di/                 # core_providers.dart — all Riverpod providers
│   ├── theme/              # AppTheme, ColorSchemes, Typography, Breakpoints
│   ├── widgets/            # AppButton, AppTextField, AsyncValueView, EmptyState, ErrorBanner
│   └── utils/              # Validators, Formatters
└── features/               # Clean Architecture per feature (domain/data/presentation)
    ├── auth/               # Sprint 1
    ├── home/               # shell + placeholder screens
    ├── search_discovery/   # Sprint 2
    ├── appointments/       # Sprint 3
    ├── payments/           # Sprint 4
    ├── notifications_center/ # Sprint 5
    └── provider_dashboard/ # Sprint 6
```

---

## Mock API

All API calls are intercepted by `MockInterceptor` when `BASE_URL` is unset (default dev mode). To add a mock response:

```dart
// lib/core/network/mock/mock_responses.dart
interceptor.register('GET', '/v1/doctors', (_) => {
  'statusCode': 200,
  'data': { 'doctors': [...] },
});
```

Sprint 1 registers OTP request/verify, `/me`, refresh, and logout mocks. Mock OTP code: **`123456`**.

---

## Dev bypass (auth guard)

Set `kDevBypassAuth = true` in `session_provider.dart` to skip login/OTP for UI work. Keep `false` to exercise the real auth loop.

---

## Localization

- Default locale: English (`en`)
- Also supported: Arabic (`ar`) with full RTL
- Translation files: `assets/translations/en.json` and `ar.json`
- Add keys to both files; access via `'auth.sign_in'.tr()` (easy_localization)

---

## Android SDK setup

Flutter 3.44 and `flutter_secure_storage 11` require **Android SDK 37**.

If the build fails with `Failed to find target with hash string 'android-37'`:

1. Open Android Studio → SDK Manager → SDK Platforms
2. Install **Android 15 (API level 37)** (or the latest available)
3. Re-run `flutter build apk --flavor patient -t lib/main_patient.dart --debug`

---

## iOS schemes (Windows dev note)

iOS flavor schemes (`patient` / `provider`) must be created in Xcode on a Mac:

1. Duplicate the default `Runner` scheme
2. Rename to `patient` / `provider`
3. Set bundle ID suffixes: `com.medsuper.med_super.patient` / `.provider`

---

## Sprint plan

| Sprint | Scope |
|--------|-------|
| **0** ✅ | Foundation: flavors, theme, mock network, router shells |
| **1** ✅ | Identity & auth: OTP, session, role/flavor guard, light onboarding |
| **2** ✅ | Provider directory: search, doctor profile |
| 3 | Scheduling: booking, hold, cancel, reschedule |
| 4 | Payments: PaymentIntent, online/at-clinic, refund |
| 5 | Transactional notifications: FCM, priority router, center |
| 6 | Role dashboards: patient home, doctor calendar, clinic queue |
| 7 | Verified reviews + Phase 1 harden |

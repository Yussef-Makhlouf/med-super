import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:med_super/app/router/routes/auth_routes.dart';
import 'package:med_super/core/config/app_config.dart';
import 'package:med_super/core/constants/storage_keys.dart';
import 'package:med_super/core/di/core_providers.dart';
import 'package:med_super/app/router/routes/appointment_routes.dart';
import 'package:med_super/app/router/routes/lab_routes.dart';
import 'package:med_super/app/router/routes/pharmacy_routes.dart';
import 'package:med_super/app/router/routes/provider_dashboard_routes.dart';
import 'package:med_super/app/router/routes/provider_registration_routes.dart';
import 'package:med_super/app/router/routes/search_routes.dart';
import 'package:med_super/features/home/presentation/screens/patient_shell_screen.dart';
import 'package:med_super/features/home/presentation/screens/patient_home_screen.dart';
import 'package:med_super/features/home/presentation/screens/appointments_placeholder_screen.dart';
import 'package:med_super/features/home/presentation/screens/notifications_placeholder_screen.dart';
import 'package:med_super/features/home/presentation/screens/orders_placeholder_screen.dart';
import 'package:med_super/features/lab_booking/presentation/screens/lab_order_detail_screen.dart';
import 'package:med_super/features/pharmacy_booking/presentation/screens/pharmacy_order_detail_screen.dart';
import 'package:med_super/features/profile_settings/presentation/screens/edit_profile_screen.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:med_super/features/auth/presentation/controllers/session_provider.dart';

part 'app_router.g.dart';

final _patientShellNavigatorKey = GlobalKey<NavigatorState>(
  debugLabel: 'patientShell',
);

/// Lets a pushed-under screen (e.g. LoginScreen, still alive beneath a
/// pushed '/account-login') detect when it becomes visible again after a
/// pop, so transient UI state (like an expanded bottom sheet) can reset.
final routeObserver = RouteObserver<PageRoute<dynamic>>();

bool _isPublicAuthRoute(String path) =>
    path == '/login' ||
    path == '/verify-otp' ||
    path == '/account-login' ||
    path == '/forgot-password' ||
    path == '/verify-reset-code' ||
    path == '/reset-password';

bool _isProviderRegistrationRoute(String path) =>
    path.startsWith('/provider/registration');

/// The pending-status screen is itself a registration route (so
/// `_isProviderRegistrationRoute` lets it through), but it must never be
/// treated as "registration done" the way the other registration routes'
/// absence is — a submitted-but-still-PENDING doctor belongs on this
/// screen specifically, not free to roam `/provider/home`.
bool _isProviderRegistrationPendingRoute(String path) =>
    path == '/provider/registration/pending';

@riverpod
GoRouter appRouter(Ref ref) {
  // Trigger redirect re-evaluation when session changes without recreating
  // the entire GoRouter (which would reset the navigation stack).
  final refresh = ValueNotifier<int>(0);
  ref.listen(sessionControllerProvider, (_, _) {
    refresh.value++;
  });
  ref.onDispose(refresh.dispose);

  return GoRouter(
    initialLocation: '/account-login',
    refreshListenable: refresh,
    observers: [routeObserver],
    redirect: (context, state) async {
      final session = await ref.read(sessionControllerProvider.future);
      final path = state.uri.path;
      final isAuthRoute = _isPublicAuthRoute(path);
      final isOnboarding = path == '/onboarding';
      final isSetPassword = path == '/set-password';
      // '/' isn't a real route — screens go here after an auth action and
      // let this redirect decide the actual destination, so it must be
      // treated like an auth/onboarding entry point everywhere below or
      // GoRouter throws "no routes for location: /" when nothing matches.
      final isRoot = path == '/';

      if (session == null && !isAuthRoute) {
        return '/account-login';
      }

      if (session != null) {
        final registrationSubmitted =
            ref
                .read(hiveServiceProvider)
                .settingsBox
                .get(SettingsKeys.providerRegistrationSubmitted) ==
            'true';
        // Dev-mock convenience: a *mock* session whose role is already
        // provider-side (a mock doctor/clinic-staff login) skips the
        // registration wizard, same as before. Scoped to `isProvider`
        // specifically — folding this into the shared `registrationSubmitted`
        // above would also mark every mock PATIENT session as "registered,"
        // sending them into the pending-status screen the instant the
        // `isPatient` block below was added.
        final skipRegistrationForMockProvider =
            kDevSkipProviderRegistrationInMock &&
            AppConfig.instance.isMock &&
            session.user.isProvider;

        // Provider-registration routes are the one `/provider/*` sub-tree a
        // PATIENT session is legitimately allowed on (the whole self-
        // registration flow, including the pending-status screen, runs
        // while the applicant is still PATIENT — see the `isPatient` block
        // below). Excluding them here is required, not just tidy: without
        // it, a patient landing on `/provider/registration/pending` gets
        // bounced to `/patient/home` by this check, which the `isPatient`
        // block's own `registrationSubmitted` check then immediately
        // bounces right back to `/provider/registration/pending` — GoRouter
        // re-runs `redirect` after every redirect, so that pair fires
        // forever and throws "too many redirects."
        if (session.user.isPatient &&
            path.startsWith('/provider/') &&
            !_isProviderRegistrationRoute(path)) {
          return '/patient/home';
        }
        final providerRegistrationSatisfied =
            registrationSubmitted || skipRegistrationForMockProvider;

        if (session.user.isProvider && path.startsWith('/patient/')) {
          return providerRegistrationSatisfied
              ? '/provider/home'
              : '/provider/registration/basic-info';
        }

        if (session.user.isProvider) {
          if (!session.passwordComplete) {
            return isSetPassword ? null : '/set-password';
          }

          final isRegistrationRoute = _isProviderRegistrationRoute(path);

          // Clinic assistants (CLINIC_STAFF) must not access the assistant
          // management screen — that is Doctor-only. Redirect to home.
          if (session.user.isAssistant && path == '/provider/assistants') {
            return '/provider/home';
          }

          // Assistants skip the registration gate entirely — they have no
          // registration flow and registrationSubmitted will always be false
          // for their session. Route them straight to the provider dashboard.
          if (session.user.isAssistant) {
            if (isAuthRoute || isOnboarding || isSetPassword || isRoot) {
              return '/provider/home';
            }
            return null;
          }

          if (isAuthRoute || isOnboarding || isSetPassword || isRoot) {
            return providerRegistrationSatisfied
                ? '/provider/home'
                : '/provider/registration/basic-info';
          }

          if (!providerRegistrationSatisfied && !isRegistrationRoute) {
            return '/provider/registration/basic-info';
          }

          return null;
        }

        if (session.user.isPatient) {
          if (!session.passwordComplete) {
            return isSetPassword ? null : '/set-password';
          }

          // A self-registered doctor stays PATIENT (role membership only
          // changes on Admin verify — see `DoctorRegistrationPendingScreen`'s
          // doc comment) — so `session.user.isProvider` is never true for
          // them, and the `isProvider` branch above never runs for this
          // case. `registrationSubmitted` is re-synced against the real
          // backend status exactly once per login (`SessionController
          // .verifyOtp`/`.loginWithPassword`, not here) rather than on every
          // redirect — checking the backend on every navigation would mean
          // every patient, not just doctors, firing a request per screen
          // change. Without that one-time resync, a still-PENDING doctor
          // who logged out (which deliberately wipes this flag, to stop one
          // account's registration state leaking into the next login on the
          // same device) would never find their way back to this screen —
          // this check is what sends them here once the flag is restored.
          if (registrationSubmitted &&
              !_isProviderRegistrationPendingRoute(path)) {
            return '/provider/registration/pending';
          }

          // Separately: someone who just picked "doctor" on the login
          // screen and verified their OTP for the first time also arrives
          // here as a plain PATIENT (role selection at OTP-verify time is
          // out of scope for this phase by backend design — see
          // `SessionController.verifyOtp`'s doc comment). Route them into
          // doctor registration instead of patient onboarding — but only
          // up to the point they actually submit it (the check above takes
          // over from there) and only if they haven't finished patient
          // onboarding already (an existing patient switching to "doctor"
          // mid-session on the login screen, if that's even reachable,
          // must not be yanked out of their own account's flow).
          final choseDoctorAtSignup =
              ref
                  .read(hiveServiceProvider)
                  .settingsBox
                  .get(SettingsKeys.choseDoctorRoleAtSignup) ==
              'true';
          if (choseDoctorAtSignup &&
              !session.onboardingComplete &&
              !_isProviderRegistrationRoute(path)) {
            return '/provider/registration/basic-info';
          }

          if (isAuthRoute || isSetPassword || isRoot) {
            if (!session.onboardingComplete) return '/onboarding';
            return '/patient/home';
          }

          if (isOnboarding && session.onboardingComplete) {
            return '/patient/home';
          }
        }
      }

      return null;
    },
    routes: [
      ...authRoutes,
      ..._patientRoutes(),
      ...labRoutes,
      ...pharmacyRoutes,
      ..._providerRoutes(),
    ],
  );
}

List<RouteBase> _patientRoutes() => [
  StatefulShellRoute.indexedStack(
    builder: (context, state, shell) =>
        PatientShellScreen(navigationShell: shell),
    branches: [
      StatefulShellBranch(
        navigatorKey: _patientShellNavigatorKey,
        routes: [
          GoRoute(
            path: '/patient/home',
            name: 'patientHome',
            builder: (context, state) => const PatientHomeScreen(),
            routes: [...appointmentRoutes, ...searchRoutes],
          ),
        ],
      ),
      StatefulShellBranch(
        routes: [
          GoRoute(
            path: '/patient/appointments',
            name: 'patientAppointments',
            builder: (context, state) => const PatientAppointmentsScreen(),
          ),
        ],
      ),
      StatefulShellBranch(
        routes: [
          GoRoute(
            path: '/patient/orders',
            name: 'patientOrders',
            // `PatientOrdersScreen` has two top tabs — الصيدلية (real
            // `GET /v1/pharmacy-orders`, default) and المعمل (real
            // `GET /v1/lab-orders`, un-blocked 2026-09-05) — restoring the
            // original header/search-bar/card design instead of dropping
            // it. Nested `:orderId` keeps the shell's bottom tab bar visible
            // on the detail screen too, same pattern `/patient/home`'s
            // `appointmentRoutes` already uses. `lab/:orderId` is declared
            // as its own literal-prefixed path (3 segments after `orders`)
            // rather than reusing `:orderId` — a pharmacy order id and a lab
            // order id are different UUID spaces, so the detail screen needs
            // to know up front which datasource to call.
            builder: (context, state) => const PatientOrdersScreen(),
            routes: [
              GoRoute(
                path: ':orderId',
                name: 'patientOrderDetail',
                builder: (context, state) => PharmacyOrderDetailScreen(
                  orderId: state.pathParameters['orderId'] ?? '',
                ),
              ),
              GoRoute(
                path: 'lab/:orderId',
                name: 'patientLabOrderDetail',
                builder: (context, state) => LabOrderDetailScreen(
                  orderId: state.pathParameters['orderId'] ?? '',
                ),
              ),
            ],
          ),
        ],
      ),
      StatefulShellBranch(
        routes: [
          GoRoute(
            path: '/patient/notifications',
            name: 'patientNotifications',
            builder: (context, state) => const PatientNotificationsScreen(),
          ),
        ],
      ),
      StatefulShellBranch(
        routes: [
          GoRoute(
            path: '/patient/profile',
            name: 'patientProfile',
            builder: (context, state) => const EditProfileScreen(),
          ),
        ],
      ),
    ],
  ),
];

List<RouteBase> _providerRoutes() => [
  ...providerDashboardRoutes,
  ...providerRegistrationRoutes,
];

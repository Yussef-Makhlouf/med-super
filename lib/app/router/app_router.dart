import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:med_super/app/flavor.dart';
import 'package:med_super/app/router/routes/auth_routes.dart';
import 'package:med_super/app/router/routes/appointment_routes.dart';
import 'package:med_super/app/router/routes/provider_dashboard_routes.dart';
import 'package:med_super/app/router/routes/search_routes.dart';
import 'package:med_super/features/home/presentation/screens/patient_shell_screen.dart';
import 'package:med_super/features/home/presentation/screens/patient_home_screen.dart';
import 'package:med_super/features/home/presentation/screens/appointments_placeholder_screen.dart';
import 'package:med_super/features/home/presentation/screens/orders_placeholder_screen.dart';
import 'package:med_super/features/home/presentation/screens/notifications_placeholder_screen.dart';
import 'package:med_super/features/profile_settings/presentation/screens/edit_profile_screen.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:med_super/features/auth/presentation/controllers/session_provider.dart';

part 'app_router.g.dart';

final _patientShellNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'patientShell');

bool _isPublicAuthRoute(String path) =>
    path == '/login' || path == '/verify-otp';

@riverpod
GoRouter appRouter(Ref ref) {
  final flavor = currentFlavor;

  // Trigger redirect re-evaluation when session changes without recreating
  // the entire GoRouter (which would reset the navigation stack).
  final refresh = ValueNotifier<int>(0);
  ref.listen(sessionControllerProvider, (_, _) {
    refresh.value++;
  });
  ref.onDispose(refresh.dispose);

  return GoRouter(
    initialLocation: '/login',
    refreshListenable: refresh,
    redirect: (context, state) async {
      final session = await ref.read(sessionControllerProvider.future);
      final path = state.uri.path;
      final isAuthRoute = _isPublicAuthRoute(path);
      final isOnboarding = path == '/onboarding';

      if (session == null && !isAuthRoute) {
        return '/login';
      }

      if (session != null) {
        if (!roleMatchesFlavor(session.user.activeRole, flavor)) {
          await ref.read(sessionControllerProvider.notifier).logout();
          return '/login';
        }

        if (isAuthRoute) {
          if (!session.onboardingComplete) return '/onboarding';
          return flavor.isPatient ? '/patient/home' : '/provider/home';
        }

        if (isOnboarding && session.onboardingComplete) {
          return flavor.isPatient ? '/patient/home' : '/provider/home';
        }
      }

      return null;
    },
    routes: [
      ...authRoutes,
      ...searchRoutes,
      if (flavor.isPatient) ..._patientRoutes(),
      if (flavor.isProvider) ..._providerRoutes(),
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
                routes: appointmentRoutes,
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/patient/appointments',
                name: 'patientAppointments',
                builder: (context, state) =>
                    const PatientAppointmentsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/patient/orders',
                name: 'patientOrders',
                builder: (context, state) => const PatientOrdersScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/patient/notifications',
                name: 'patientNotifications',
                builder: (context, state) =>
                    const PatientNotificationsScreen(),
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
    ];

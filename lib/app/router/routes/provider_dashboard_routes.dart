import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:med_super/features/provider_dashboard/presentation/screens/provider_home_screen.dart';
import 'package:med_super/features/provider_dashboard/presentation/screens/provider_notifications_screen.dart';
import 'package:med_super/features/provider_dashboard/presentation/screens/provider_patients_screen.dart';
import 'package:med_super/features/provider_dashboard/presentation/screens/provider_profile_screen.dart';
import 'package:med_super/features/provider_dashboard/presentation/screens/provider_shell_screen.dart';

final _providerShellNavigatorKey = GlobalKey<NavigatorState>(
  debugLabel: 'providerShellNavigator',
);

final providerDashboardRoutes = <RouteBase>[
  StatefulShellRoute.indexedStack(
    builder: (context, state, shell) =>
        ProviderShellScreen(navigationShell: shell),
    branches: [
      StatefulShellBranch(
        navigatorKey: _providerShellNavigatorKey,
        routes: [
          GoRoute(
            path: '/provider/home',
            name: 'providerHome',
            builder: (context, state) => const ProviderHomeScreen(),
          ),
        ],
      ),
      StatefulShellBranch(
        routes: [
          GoRoute(
            path: '/provider/appointments',
            name: 'providerAppointments',
            builder: (context, state) => const ProviderHomeScreen(),
          ),
        ],
      ),
      StatefulShellBranch(
        routes: [
          GoRoute(
            path: '/provider/patients',
            name: 'providerPatients',
            builder: (context, state) => const ProviderPatientsScreen(),
          ),
        ],
      ),
      StatefulShellBranch(
        routes: [
          GoRoute(
            path: '/provider/profile',
            name: 'providerProfile',
            builder: (context, state) => const ProviderProfileScreen(),
          ),
        ],
      ),
    ],
  ),
  GoRoute(
    path: '/provider/notifications',
    name: 'providerNotifications',
    builder: (context, state) => const ProviderNotificationsScreen(),
  ),
];

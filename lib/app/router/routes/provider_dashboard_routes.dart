import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:med_super/features/provider_dashboard/presentation/screens/provider_appointments_screen.dart';
import 'package:med_super/features/provider_dashboard/presentation/screens/provider_home_screen.dart';
import 'package:med_super/features/provider_dashboard/presentation/screens/provider_notifications_screen.dart';
import 'package:med_super/features/provider_dashboard/presentation/screens/provider_patients_screen.dart';
import 'package:med_super/features/provider_dashboard/presentation/screens/provider_profile_screen.dart';
import 'package:med_super/features/provider_dashboard/presentation/screens/provider_shell_screen.dart';
import 'package:med_super/features/provider_dashboard/presentation/screens/assistant/assistant_list_screen.dart';

/// One navigator key per branch — exposed so [ProviderShellScreen] can pop an
/// imperatively-pushed screen (e.g. a profile sub-screen reached via
/// `Navigator.push`) back to that branch's root when its own tab is tapped
/// again. `goBranch(initialLocation: true)` alone only resets go_router's
/// declarative route state; it can't see plain `Navigator.push` pages sitting
/// on top of a branch, so without this key those pages would stay on screen.
final providerBranchNavigatorKeys = <GlobalKey<NavigatorState>>[
  GlobalKey<NavigatorState>(debugLabel: 'providerHomeNav'),
  GlobalKey<NavigatorState>(debugLabel: 'providerAppointmentsNav'),
  GlobalKey<NavigatorState>(debugLabel: 'providerPatientsNav'),
  GlobalKey<NavigatorState>(debugLabel: 'providerProfileNav'),
];

final providerDashboardRoutes = <RouteBase>[
  StatefulShellRoute.indexedStack(
    builder: (context, state, shell) => ProviderShellScreen(
      navigationShell: shell,
      branchNavigatorKeys: providerBranchNavigatorKeys,
    ),
    branches: [
      StatefulShellBranch(
        navigatorKey: providerBranchNavigatorKeys[0],
        routes: [
          GoRoute(
            path: '/provider/home',
            name: 'providerHome',
            builder: (context, state) => const ProviderHomeScreen(),
          ),
        ],
      ),
      StatefulShellBranch(
        navigatorKey: providerBranchNavigatorKeys[1],
        routes: [
          GoRoute(
            path: '/provider/appointments',
            name: 'providerAppointments',
            builder: (context, state) => const ProviderAppointmentsScreen(),
          ),
        ],
      ),
      StatefulShellBranch(
        navigatorKey: providerBranchNavigatorKeys[2],
        routes: [
          GoRoute(
            path: '/provider/patients',
            name: 'providerPatients',
            builder: (context, state) => const ProviderPatientsScreen(),
          ),
        ],
      ),
      StatefulShellBranch(
        navigatorKey: providerBranchNavigatorKeys[3],
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
  GoRoute(
    path: '/provider/assistants',
    name: 'providerAssistants',
    builder: (context, state) => const AssistantListScreen(),
  ),
];

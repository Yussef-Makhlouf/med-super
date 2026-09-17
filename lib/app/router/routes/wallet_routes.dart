import 'package:go_router/go_router.dart';
import 'package:med_super/features/wallet/presentation/screens/wallet_dashboard_screen.dart';

/// Nested under `/patient/home` (see `app_router.dart`'s `_patientRoutes`),
/// same pattern as `appointmentRoutes`/`searchRoutes` — only the wallet's
/// entry point is a real go_router route. Every screen inside the wallet
/// flow (add-balance, top-up, transfer, refund, transaction detail, ...)
/// still navigates with plain `Navigator.push`/`pop` among themselves; that
/// part didn't need to change.
///
/// Before this, `WalletDashboardScreen` was only ever reached via
/// `Navigator.of(context).push(MaterialPageRoute(...))` directly from
/// `PatientHomeScreen`/`ProviderProfileScreen` — invisible to go_router
/// entirely. That meant the wallet was rendered as a screen stacked on top
/// of the patient shell's `Navigator`, while the shell's bottom nav bar
/// (part of the *outer* `Scaffold`, unaffected by an inner push) stayed
/// visible and tappable underneath it. Tapping the Home tab then called
/// `navigationShell.goBranch(0, ...)` — which only resets go_router's own
/// branch state — with no way to know a plain `Navigator.push` was sitting
/// on top, so it never got popped and the wallet just stayed on screen.
/// Registering the wallet as a real nested route fixes that: it becomes
/// part of the Home branch's own navigation stack, so switching tabs
/// naturally leaves it behind like any other pushed screen in that stack.
final walletRoutes = <RouteBase>[
  GoRoute(
    path: 'wallet',
    name: 'patientWallet',
    builder: (context, state) => const WalletDashboardScreen(),
  ),
];

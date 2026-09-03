import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:med_super/app/flavor.dart';
import 'package:med_super/features/auth/presentation/controllers/session_provider.dart';

bool isPublicAuthRoute(String path) =>
    path == '/login' || path == '/verify-otp';

/// Shared redirect rules for GoRouter (auth, flavor/role, onboarding).
/// Prefer calling from [appRouter] with a Riverpod [Ref].
Future<String?> resolveAuthRedirect({
  required Session? session,
  required String path,
  required Flavor flavor,
  required Future<void> Function() logout,
}) async {
  final isAuthRoute = isPublicAuthRoute(path);
  final isOnboarding = path == '/onboarding';

  if (session == null && !isAuthRoute) {
    return '/login';
  }

  if (session != null) {
    if (!roleMatchesFlavor(session.user.activeRole, flavor)) {
      await logout();
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
}

/// Builds the top-level redirect function used by GoRouter.
GoRouterRedirect buildRedirect(WidgetRef ref) {
  return (context, state) async {
    final session = await ref.read(sessionControllerProvider.future);
    return resolveAuthRedirect(
      session: session,
      path: state.uri.path,
      flavor: currentFlavor,
      logout: () => ref.read(sessionControllerProvider.notifier).logout(),
    );
  };
}

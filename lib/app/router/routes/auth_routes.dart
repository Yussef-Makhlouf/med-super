import 'package:go_router/go_router.dart';
import 'package:med_super/features/auth/presentation/screens/login_screen.dart';
import 'package:med_super/features/auth/presentation/screens/onboarding_screen.dart';
import 'package:med_super/features/auth/presentation/screens/verify_otp_screen.dart';

final authRoutes = <RouteBase>[
  GoRoute(
    path: '/login',
    name: 'login',
    builder: (context, state) => const LoginScreen(),
  ),
  GoRoute(
    path: '/verify-otp',
    name: 'verifyOtp',
    builder: (context, state) {
      final extra = state.extra;
      var phone = '';
      var role = 'patient';
      if (extra is Map) {
        phone = '${extra['phone'] ?? ''}';
        role = '${extra['role'] ?? 'patient'}';
      }
      return VerifyOtpScreen(phone: phone, role: role);
    },
  ),
  GoRoute(
    path: '/onboarding',
    name: 'onboarding',
    builder: (context, state) => const OnboardingScreen(),
  ),
];

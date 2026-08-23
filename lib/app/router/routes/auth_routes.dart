import 'package:go_router/go_router.dart';
import 'package:med_super/features/auth/presentation/screens/account_login_screen.dart';
import 'package:med_super/features/auth/presentation/screens/login_screen.dart';
import 'package:med_super/features/auth/presentation/screens/onboarding_screen.dart';
import 'package:med_super/features/auth/presentation/screens/set_password_screen.dart';
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
      var requestId = '';
      if (extra is Map) {
        phone = '${extra['phone'] ?? ''}';
        role = '${extra['role'] ?? 'patient'}';
        requestId = '${extra['requestId'] ?? ''}';
      }
      return VerifyOtpScreen(phone: phone, role: role, requestId: requestId);
    },
  ),
  GoRoute(
    path: '/onboarding',
    name: 'onboarding',
    builder: (context, state) => const OnboardingScreen(),
  ),
  GoRoute(
    path: '/set-password',
    name: 'setPassword',
    builder: (context, state) {
      final extra = state.extra;
      var phone = '';
      var role = 'patient';
      if (extra is Map) {
        phone = '${extra['phone'] ?? ''}';
        role = '${extra['role'] ?? 'patient'}';
      }
      return SetPasswordScreen(phone: phone, role: role);
    },
  ),
  GoRoute(
    path: '/account-login',
    name: 'accountLogin',
    builder: (context, state) => const AccountLoginScreen(),
  ),
];

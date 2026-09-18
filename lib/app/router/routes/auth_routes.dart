import 'package:go_router/go_router.dart';
import 'package:med_super/features/auth/presentation/screens/account_login_screen.dart';
import 'package:med_super/features/auth/presentation/screens/forgot_password_screen.dart';
import 'package:med_super/features/auth/presentation/screens/login_screen.dart';
import 'package:med_super/features/auth/presentation/screens/onboarding_screen.dart';
import 'package:med_super/features/auth/presentation/screens/provider_login_screen.dart';
import 'package:med_super/features/auth/presentation/screens/reset_password_screen.dart';
import 'package:med_super/features/auth/presentation/screens/set_password_screen.dart';
import 'package:med_super/features/auth/presentation/screens/verify_otp_screen.dart';
import 'package:med_super/features/auth/presentation/screens/verify_reset_code_screen.dart';

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
    builder: (context, state) {
      final extra = state.extra;
      String? successMessageKey;
      if (extra is Map) {
        successMessageKey = extra['successMessageKey'] as String?;
      }
      return AccountLoginScreen(successMessageKey: successMessageKey);
    },
  ),
  GoRoute(
    path: '/provider-login',
    name: 'providerLogin',
    builder: (context, state) => const ProviderLoginScreen(),
  ),
  GoRoute(
    path: '/forgot-password',
    name: 'forgotPassword',
    builder: (context, state) => const ForgotPasswordScreen(),
  ),
  GoRoute(
    path: '/verify-reset-code',
    name: 'verifyResetCode',
    builder: (context, state) {
      final extra = state.extra;
      var phone = '';
      var requestId = '';
      if (extra is Map) {
        phone = '${extra['phone'] ?? ''}';
        requestId = '${extra['requestId'] ?? ''}';
      }
      return VerifyResetCodeScreen(phone: phone, requestId: requestId);
    },
  ),
  GoRoute(
    path: '/reset-password',
    name: 'resetPassword',
    builder: (context, state) {
      final extra = state.extra;
      var requestId = '';
      var code = '';
      if (extra is Map) {
        requestId = '${extra['requestId'] ?? ''}';
        code = '${extra['code'] ?? ''}';
      }
      return ResetPasswordScreen(requestId: requestId, code: code);
    },
  ),
];

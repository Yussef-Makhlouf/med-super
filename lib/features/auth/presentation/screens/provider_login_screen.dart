import 'package:flutter/widgets.dart';
import 'package:med_super/features/auth/presentation/screens/account_login_screen.dart';

/// Dedicated provider route. The underlying form deliberately remains the
/// same password-auth implementation used by patient login.
class ProviderLoginScreen extends StatelessWidget {
  const ProviderLoginScreen({super.key});

  @override
  Widget build(BuildContext context) => const AccountLoginScreen.provider();
}

import 'package:go_router/go_router.dart';
import 'package:med_super/features/provider_dashboard/presentation/screens/provider_home_screen.dart';

final providerDashboardRoutes = <RouteBase>[
  GoRoute(
    path: '/provider/home',
    name: 'providerHome',
    builder: (context, state) => const ProviderHomeScreen(),
  ),
];

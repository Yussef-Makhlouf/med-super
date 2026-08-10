import 'package:go_router/go_router.dart';
import 'package:med_super/features/provider_profile/presentation/screens/doctor_details_screen.dart';
import 'package:med_super/features/search_discovery/presentation/screens/doctor_search_screen.dart';

final searchRoutes = <RouteBase>[
  GoRoute(
    path: '/patient/search',
    name: 'patientSearch',
    builder: (context, state) {
      final specialty = state.uri.queryParameters['specialty'];
      final titleKey = state.uri.queryParameters['titleKey'];
      return DoctorSearchScreen(
        initialSpecialty: specialty,
        titleKey: titleKey,
      );
    },
  ),
  GoRoute(
    path: '/patient/doctors/:doctorId',
    name: 'patientDoctorDetails',
    builder: (context, state) {
      final doctorId = state.pathParameters['doctorId'] ?? '';
      return DoctorDetailsScreen(doctorId: doctorId);
    },
  ),
];

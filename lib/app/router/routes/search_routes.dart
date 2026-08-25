import 'package:go_router/go_router.dart';
import 'package:med_super/features/provider_profile/presentation/screens/clinic_branch_details_screen.dart';
import 'package:med_super/features/provider_profile/presentation/screens/clinic_details_screen.dart';
import 'package:med_super/features/provider_profile/presentation/screens/doctor_details_screen.dart';
import 'package:med_super/features/search_discovery/presentation/screens/doctor_search_screen.dart';

final searchRoutes = <RouteBase>[
  GoRoute(
    path: '/patient/search',
    name: 'patientSearch',
    builder: (context, state) {
      final specialty = state.uri.queryParameters['specialty'];
      final specialtyName = state.uri.queryParameters['title'];
      final titleKey = state.uri.queryParameters['titleKey'];
      return DoctorSearchScreen(
        initialSpecialty: specialty,
        initialSpecialtyName: specialtyName,
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
  GoRoute(
    path: '/patient/clinic-branches/:branchId',
    name: 'patientClinicBranchDetails',
    builder: (context, state) {
      final branchId = state.pathParameters['branchId'] ?? '';
      return ClinicBranchDetailsScreen(branchId: branchId);
    },
  ),
  GoRoute(
    path: '/patient/clinics/:clinicId',
    name: 'patientClinicDetails',
    builder: (context, state) {
      final clinicId = state.pathParameters['clinicId'] ?? '';
      return ClinicDetailsScreen(clinicId: clinicId);
    },
  ),
];

import 'package:go_router/go_router.dart';
import 'package:med_super/features/provider_profile/presentation/screens/clinic_branch_details_screen.dart';
import 'package:med_super/features/provider_profile/presentation/screens/doctor_details_screen.dart';
import 'package:med_super/features/search_discovery/presentation/screens/all_specialties_screen.dart';
import 'package:med_super/features/search_discovery/presentation/screens/doctor_search_screen.dart';

/// Nested under `/patient/home` (see `app_router.dart`'s `_patientRoutes`),
/// same as `appointmentRoutes` — **not** top-level routes anymore (moved
/// 2026-09-03). They used to sit outside the patient shell entirely
/// (`/patient/search`, `/patient/doctors/:id`, `/patient/clinic-branches/:id`
/// as root-level `GoRoute`s), which put `DoctorDetailsScreen` on the root
/// `Navigator` while its own "Book Now" button pushes
/// `/patient/home/appointments/confirm` — a path that only exists on the
/// shell's nested `Navigator`. That cross-navigator push is what caused a
/// `HeroControllerScope`/`!keyReservation.contains(key)` crash the instant
/// the confirm/detail screen tried to build: two different Navigators ended
/// up racing to reserve the same computed page key. Nesting these routes
/// here keeps every push in this whole booking flow on the shell's single
/// `Navigator`, matching how `appointment_detail_screen.dart`'s reschedule
/// flow (which never had this bug) is nested the same way.
final searchRoutes = <RouteBase>[
  GoRoute(
    path: 'specialties',
    name: 'patientSpecialties',
    builder: (context, state) => const AllSpecialtiesScreen(),
  ),
  GoRoute(
    path: 'search',
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
    path: 'doctors/:doctorId',
    name: 'patientDoctorDetails',
    builder: (context, state) {
      final doctorId = state.pathParameters['doctorId'] ?? '';
      return DoctorDetailsScreen(doctorId: doctorId);
    },
  ),
  GoRoute(
    path: 'clinic-branches/:branchId',
    name: 'patientClinicBranchDetails',
    builder: (context, state) {
      final branchId = state.pathParameters['branchId'] ?? '';
      return ClinicBranchDetailsScreen(branchId: branchId);
    },
  ),
];

import 'package:go_router/go_router.dart';
import 'package:med_super/features/provider_registration/presentation/screens/doctor_registration_basic_info_screen.dart';
import 'package:med_super/features/provider_registration/presentation/screens/doctor_registration_clinic_schedule_screen.dart';
import 'package:med_super/features/provider_registration/presentation/screens/doctor_registration_pending_screen.dart';
import 'package:med_super/features/provider_registration/presentation/screens/doctor_registration_review_screen.dart';
import 'package:med_super/features/provider_registration/presentation/screens/doctor_registration_verification_screen.dart';

final providerRegistrationRoutes = <RouteBase>[
  GoRoute(
    path: '/provider/registration/basic-info',
    name: 'providerRegBasicInfo',
    builder: (context, state) => const DoctorRegistrationBasicInfoScreen(),
  ),
  GoRoute(
    path: '/provider/registration/verification',
    name: 'providerRegVerification',
    builder: (context, state) => const DoctorRegistrationVerificationScreen(),
  ),
  GoRoute(
    path: '/provider/registration/clinic-schedule',
    name: 'providerRegClinicSchedule',
    builder: (context, state) => const DoctorRegistrationClinicScheduleScreen(),
  ),
  GoRoute(
    path: '/provider/registration/review',
    name: 'providerRegReview',
    builder: (context, state) => const DoctorRegistrationReviewScreen(),
  ),
  GoRoute(
    path: '/provider/registration/pending',
    name: 'providerRegPending',
    builder: (context, state) => const DoctorRegistrationPendingScreen(),
  ),
];

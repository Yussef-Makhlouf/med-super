import 'package:go_router/go_router.dart';
import 'package:med_super/features/lab_booking/domain/entities/lab_booking_confirmation.dart';
import 'package:med_super/features/lab_booking/presentation/screens/lab_booking_confirmation_screen.dart';
import 'package:med_super/features/lab_booking/presentation/screens/lab_request_upload_screen.dart';
import 'package:med_super/features/lab_booking/presentation/screens/lab_review_screen.dart';
import 'package:med_super/features/lab_booking/presentation/screens/lab_select_partner_screen.dart';

final labRoutes = <RouteBase>[
  GoRoute(
    path: '/patient/lab/upload',
    name: 'patientLabRequestUpload',
    builder: (context, state) => const LabRequestUploadScreen(),
  ),
  GoRoute(
    path: '/patient/lab/select-lab',
    name: 'patientLabSelectPartner',
    builder: (context, state) => const LabSelectPartnerScreen(),
  ),
  GoRoute(
    path: '/patient/lab/review',
    name: 'patientLabReview',
    builder: (context, state) => const LabReviewScreen(),
  ),
  GoRoute(
    path: '/patient/lab/confirmation',
    name: 'patientLabBookingConfirmation',
    builder: (context, state) => LabBookingConfirmationScreen(
      confirmation: state.extra as LabBookingConfirmation,
    ),
  ),
];

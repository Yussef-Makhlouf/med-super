import 'package:go_router/go_router.dart';
import 'package:med_super/features/pharmacy_booking/domain/entities/pharmacy_order_confirmation.dart';
import 'package:med_super/features/pharmacy_booking/presentation/screens/pharmacy_order_confirmation_screen.dart';
import 'package:med_super/features/pharmacy_booking/presentation/screens/pharmacy_order_review_screen.dart';
import 'package:med_super/features/pharmacy_booking/presentation/screens/pharmacy_prescription_upload_screen.dart';
import 'package:med_super/features/pharmacy_booking/presentation/screens/pharmacy_select_screen.dart';

final pharmacyRoutes = <RouteBase>[
  GoRoute(
    path: '/patient/pharmacy/upload',
    name: 'patientPharmacyUpload',
    builder: (context, state) => const PharmacyPrescriptionUploadScreen(),
  ),
  GoRoute(
    path: '/patient/pharmacy/select',
    name: 'patientPharmacySelect',
    builder: (context, state) => const PharmacySelectScreen(),
  ),
  GoRoute(
    path: '/patient/pharmacy/review',
    name: 'patientPharmacyReview',
    builder: (context, state) => const PharmacyOrderReviewScreen(),
  ),
  GoRoute(
    path: '/patient/pharmacy/confirmation',
    name: 'patientPharmacyConfirmation',
    builder: (context, state) => PharmacyOrderConfirmationScreen(
      confirmation: state.extra as PharmacyOrderConfirmation,
    ),
  ),
];

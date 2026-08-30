import 'package:flutter/foundation.dart' show VoidCallback;
import 'package:go_router/go_router.dart';
import 'package:med_super/features/pharmacy_booking/domain/entities/pharmacy_order_confirmation.dart';
import 'package:med_super/features/pharmacy_booking/presentation/screens/pharmacy_order_confirmation_screen.dart';
import 'package:med_super/features/pharmacy_booking/presentation/screens/pharmacy_order_review_screen.dart';
import 'package:med_super/features/pharmacy_booking/presentation/screens/pharmacy_prescription_upload_screen.dart';
import 'package:med_super/features/pharmacy_booking/presentation/screens/pharmacy_select_screen.dart';
import 'package:med_super/features/provider_profile/presentation/screens/pharmacy_branch_details_screen.dart';

final pharmacyRoutes = <RouteBase>[
  GoRoute(
    path: '/patient/pharmacy-branches/:branchId',
    name: 'patientPharmacyBranchDetails',
    builder: (context, state) {
      final branchId = state.pathParameters['branchId'] ?? '';
      // `extra` is how the pharmacy_booking select-step screen threads its
      // own "choose this one and continue" action through — see
      // PharmacySelectScreen's card onTap. Any other caller (a plain "view
      // branch" link, a search result, ...) leaves `extra` unset, so the
      // screen renders with no select action, same as before. A branch is
      // the unit patients choose here — there is no separate "pharmacy
      // chain" route to drill through first.
      return PharmacyBranchDetailsScreen(
        branchId: branchId,
        onSelect: state.extra as VoidCallback?,
      );
    },
  ),
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

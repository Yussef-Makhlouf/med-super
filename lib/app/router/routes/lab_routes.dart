import 'package:go_router/go_router.dart';
import 'package:med_super/features/lab_booking/domain/entities/lab_booking_confirmation.dart';
import 'package:med_super/features/lab_booking/presentation/screens/lab_booking_confirmation_screen.dart';
import 'package:med_super/features/lab_booking/presentation/screens/lab_schedule_payment_screen.dart';
import 'package:med_super/features/lab_booking/presentation/screens/lab_select_partner_screen.dart';
import 'package:med_super/features/lab_booking/presentation/screens/lab_test_selection_screen.dart';

final labRoutes = <RouteBase>[
  GoRoute(
    path: '/patient/lab/select-tests',
    name: 'patientLabTestSelection',
    builder: (context, state) => const LabTestSelectionScreen(),
  ),
  GoRoute(
    path: '/patient/lab/select-lab',
    name: 'patientLabSelectPartner',
    builder: (context, state) => const LabSelectPartnerScreen(),
  ),
  GoRoute(
    path: '/patient/lab/schedule-payment',
    name: 'patientLabSchedulePayment',
    builder: (context, state) => const LabSchedulePaymentScreen(),
  ),
  GoRoute(
    path: '/patient/lab/confirmation',
    name: 'patientLabBookingConfirmation',
    builder: (context, state) => LabBookingConfirmationScreen(
      confirmation: state.extra as LabBookingConfirmation,
    ),
  ),
];

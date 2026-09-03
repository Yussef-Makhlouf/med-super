import 'package:go_router/go_router.dart';
import 'package:med_super/features/appointments/domain/entities/booking_request.dart';
import 'package:med_super/features/appointments/domain/entities/reschedule_target.dart';
import 'package:med_super/features/appointments/presentation/screens/appointment_detail_screen.dart';
import 'package:med_super/features/appointments/presentation/screens/booking_confirm_screen.dart';
import 'package:med_super/features/appointments/presentation/screens/booking_success_screen.dart';
import 'package:med_super/features/appointments/presentation/screens/reschedule_screen.dart';

/// Phase 4 (Appointments) is real now — hold/confirm/cancel/reschedule all
/// match the backend's `File 12 Part 35` contract. Nested under
/// `/patient/home` (see `app_router.dart`'s `_patientRoutes`), reached from
/// `doctor_details_screen`'s "Book Now" button and
/// `PatientAppointmentsScreen`'s "Reschedule" button and card taps.
///
/// The `appointments/:appointmentId` detail route is deliberately listed
/// **last** — it's a catch-all param route and go_router tries sibling
/// routes in list order, so it must come after the literal
/// `confirm`/`success`/`reschedule` segments or it would swallow them.
final appointmentRoutes = <RouteBase>[
  GoRoute(
    path: 'appointments/confirm',
    name: 'bookingConfirm',
    // Either a plain BookingRequest (fresh booking from doctor_details_screen)
    // or a BookingConfirmArgs bundling a request with an already-created hold
    // (from RescheduleScreen, which must call RescheduleAppointmentUseCase
    // itself to get the hold before this screen can show it).
    builder: (context, state) {
      final extra = state.extra;
      if (extra is BookingConfirmArgs) {
        return BookingConfirmScreen(
          request: extra.request,
          initialHold: extra.initialHold,
        );
      }
      return BookingConfirmScreen(request: extra as BookingRequest);
    },
  ),
  GoRoute(
    path: 'appointments/success',
    name: 'bookingSuccess',
    builder: (context, state) =>
        BookingSuccessScreen(request: state.extra as BookingRequest),
  ),
  GoRoute(
    path: 'appointments/reschedule',
    name: 'appointmentReschedule',
    builder: (context, state) =>
        RescheduleScreen(target: state.extra as RescheduleTarget),
  ),
  GoRoute(
    path: 'appointments/:appointmentId',
    name: 'appointmentDetail',
    builder: (context, state) => AppointmentDetailScreen(
      appointmentId: state.pathParameters['appointmentId'] ?? '',
    ),
  ),
];

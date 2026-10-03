import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:med_super/core/widgets/simple_success_screen.dart';
import 'package:med_super/features/appointments/domain/entities/appointment_payment_method.dart';
import 'package:med_super/features/appointments/domain/entities/booking_request.dart';

/// Wraps the [BookingRequest] together with the payment method the patient
/// actually chose on the confirm screen — only reached via the two
/// synchronous methods (pay-at-clinic/wallet); Fawry never routes here
/// (see `BookingConfirmScreen._payWithFawry`).
class BookingSuccessArgs {
  const BookingSuccessArgs({required this.request, required this.method})
    : rescheduled = false;

  /// A completed reschedule: already confirmed, original payment carried
  /// over, so there is no payment method to describe.
  const BookingSuccessArgs.rescheduled({required this.request})
    : method = null,
      rescheduled = true;

  final BookingRequest request;
  final AppointmentPaymentMethod? method;
  final bool rescheduled;
}

class BookingSuccessScreen extends StatelessWidget {
  const BookingSuccessScreen({required this.args, super.key});

  final BookingSuccessArgs args;

  @override
  Widget build(BuildContext context) {
    final request = args.request;
    final messageKey = args.rescheduled
        ? 'appointments.reschedule_confirmed_message'
        : args.method == AppointmentPaymentMethod.wallet
        ? 'appointments.booking_confirmed_message_wallet'
        : 'appointments.booking_confirmed_message';
    return SimpleSuccessScreen(
      title: (args.rescheduled
              ? 'appointments.reschedule_confirmed'
              : 'appointments.booking_confirmed')
          .tr(),
      message: messageKey.tr(args: [request.doctorName, request.timeLabel]),
      primaryActionLabel: 'appointments.view_my_appointments'.tr(),
      onPrimaryAction: () => context.go('/patient/appointments'),
    );
  }
}

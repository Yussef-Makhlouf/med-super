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
  const BookingSuccessArgs({required this.request, required this.method});

  final BookingRequest request;
  final AppointmentPaymentMethod method;
}

class BookingSuccessScreen extends StatelessWidget {
  const BookingSuccessScreen({required this.args, super.key});

  final BookingSuccessArgs args;

  @override
  Widget build(BuildContext context) {
    final request = args.request;
    final messageKey = args.method == AppointmentPaymentMethod.wallet
        ? 'appointments.booking_confirmed_message_wallet'
        : 'appointments.booking_confirmed_message';
    return SimpleSuccessScreen(
      title: 'appointments.booking_confirmed'.tr(),
      message: messageKey.tr(args: [request.doctorName, request.timeLabel]),
      primaryActionLabel: 'appointments.view_my_appointments'.tr(),
      onPrimaryAction: () => context.go('/patient/appointments'),
    );
  }
}

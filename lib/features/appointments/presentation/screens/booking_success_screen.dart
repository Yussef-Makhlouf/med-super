import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:med_super/core/widgets/simple_success_screen.dart';
import 'package:med_super/features/appointments/domain/entities/booking_request.dart';

class BookingSuccessScreen extends StatelessWidget {
  const BookingSuccessScreen({required this.request, super.key});

  final BookingRequest request;

  @override
  Widget build(BuildContext context) {
    return SimpleSuccessScreen(
      title: 'appointments.booking_confirmed'.tr(),
      message: 'appointments.booking_confirmed_message'.tr(
        args: [request.doctorName, request.timeLabel],
      ),
      primaryActionLabel: 'appointments.view_my_appointments'.tr(),
      onPrimaryAction: () => context.go('/patient/appointments'),
    );
  }
}

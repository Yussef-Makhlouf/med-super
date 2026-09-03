import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:med_super/core/widgets/empty_state.dart';

class AppointmentsPlaceholderScreen extends StatelessWidget {
  const AppointmentsPlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: const Color(0xFFF3F6FB),
        appBar: AppBar(
          backgroundColor: Colors.white,
          title: Text('appointments.title'.tr()),
        ),
        body: EmptyState(
          title: 'appointments.empty'.tr(),
          subtitle: 'common.coming_soon'.tr(),
          icon: Icons.calendar_month_outlined,
        ),
      );
}

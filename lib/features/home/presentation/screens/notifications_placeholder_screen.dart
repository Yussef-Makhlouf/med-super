import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:med_super/core/widgets/empty_state.dart';

class NotificationsPlaceholderScreen extends StatelessWidget {
  const NotificationsPlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: const Color(0xFFF3F6FB),
        appBar: AppBar(
          backgroundColor: Colors.white,
          title: Text('notifications.title'.tr()),
        ),
        body: EmptyState(
          title: 'notifications.empty_title'.tr(),
          subtitle: 'notifications.empty_subtitle'.tr(),
          icon: Icons.notifications_none,
        ),
      );
}

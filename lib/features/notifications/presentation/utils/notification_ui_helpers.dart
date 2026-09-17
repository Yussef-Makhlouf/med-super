import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:med_super/core/theme/color_schemes.dart';

Color notificationIconBackground({
  required String templateCode,
  required bool isRead,
}) {
  if (isRead) return const Color(0xFFE5E7EB);
  return switch (templateCode) {
    'AppointmentConfirmed' || 'AppointmentCancelled' => brandBlue,
    'LabResultReady' || 'CriticalLabResult' => const Color(0xFFF59E0B),
    'PrescriptionUploaded' ||
    'PrescriptionAccepted' ||
    'PrescriptionRejected' => const Color(0xFF6B7280),
    'PaymentCaptured' ||
    'PaymentFailed' ||
    'RefundIssued' ||
    'PaymentAutoRefunded' ||
    'WalletToppedUp' => const Color(0xFF0891B2),
    _ => brandBlue,
  };
}

Color notificationIconForeground({required bool isRead}) =>
    isRead ? const Color(0xFF9CA3AF) : Colors.white;

IconData notificationIconData(String templateCode) {
  if (templateCode.startsWith('Appointment')) {
    return Icons.calendar_month_outlined;
  }
  if (templateCode.startsWith('Prescription')) {
    return Icons.description_outlined;
  }
  if (templateCode.startsWith('Lab') || templateCode == 'CriticalLabResult') {
    return Icons.science_outlined;
  }
  if (templateCode.startsWith('Payment') ||
      templateCode == 'WalletToppedUp' ||
      templateCode == 'RefundIssued') {
    return Icons.payments_outlined;
  }
  return Icons.notifications_none_rounded;
}

String formatNotificationTimeAgo(DateTime dateTime) {
  final diff = DateTime.now().difference(dateTime.toLocal());
  if (diff.inMinutes < 1) {
    return 'notifications.time_now'.tr();
  }
  if (diff.inMinutes < 60) {
    return 'notifications.time_minutes_ago'.tr(
      namedArgs: {'count': '${diff.inMinutes}'},
    );
  }
  if (diff.inHours < 24) {
    return 'notifications.time_hours_ago'.tr(
      namedArgs: {'count': '${diff.inHours}'},
    );
  }
  final now = DateTime.now();
  final local = dateTime.toLocal();
  if (local.year == now.year &&
      local.month == now.month &&
      local.day == now.day - 1) {
    return 'notifications.yesterday'.tr();
  }
  return DateFormat.jm().format(local);
}

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:med_super/core/theme/app_colors.dart';
import 'package:med_super/core/widgets/app_badge.dart';

/// A small colored pill for a `LabOrderStatus` value (backend enum,
/// `clinic-reservations` `prisma/schema/shared.prisma`) — shared between the
/// orders list and detail screens. Mirrors `pharmacy_booking`'s
/// `PharmacyOrderStatusPill`.
class LabOrderStatusPill extends StatelessWidget {
  const LabOrderStatusPill({required this.status, super.key});

  final String status;

  static const _colors = <String, Color>{
    'REQUESTED': AppColors.mutedText2,
    'QUOTED': AppColors.warningAmberText,
    'AWAITING_SAMPLE': AppColors.tealAccent,
    'IN_ANALYSIS': AppColors.patientPrimary,
    'RESULTS_READY': AppColors.tealAccent,
    'REJECTED': AppColors.errorRed,
    'CANCELLED': AppColors.mutedText2,
  };

  static const _labelKeys = <String, String>{
    'REQUESTED': 'lab_booking.orders.status_requested',
    'QUOTED': 'lab_booking.orders.status_quoted',
    'AWAITING_SAMPLE': 'lab_booking.orders.status_awaiting_sample',
    'IN_ANALYSIS': 'lab_booking.orders.status_in_analysis',
    'RESULTS_READY': 'lab_booking.orders.status_results_ready',
    'REJECTED': 'lab_booking.orders.status_rejected',
    'CANCELLED': 'lab_booking.orders.status_cancelled',
  };

  /// Exposed so other widgets rendering a `LabOrderDetail` (e.g. the
  /// orders-tab card's left status bar) can match this pill's color exactly
  /// instead of keeping a second copy of this map.
  static Color colorFor(String status) => _colors[status] ?? AppColors.mutedText2;

  @override
  Widget build(BuildContext context) {
    final labelKey = _labelKeys[status];
    return AppBadge.soft(
      label: labelKey == null ? status : labelKey.tr(),
      color: colorFor(status),
    );
  }
}

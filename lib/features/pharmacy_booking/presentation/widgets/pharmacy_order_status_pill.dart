import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:med_super/core/theme/app_colors.dart';
import 'package:med_super/core/widgets/app_badge.dart';

/// A small colored pill for a `PharmacyOrderStatus` value (backend enum,
/// `clinic-reservations` `prisma/schema/pharmacy.prisma`) — shared between
/// the orders list and detail screens.
class PharmacyOrderStatusPill extends StatelessWidget {
  const PharmacyOrderStatusPill({required this.status, super.key});

  final String status;

  static const _colors = <String, Color>{
    'RECEIVED': AppColors.mutedText2,
    'UNDER_REVIEW': AppColors.mutedText2,
    'ACCEPTED': AppColors.tealAccent,
    'PAID': AppColors.tealAccent,
    'READY_FOR_PICKUP': AppColors.patientPrimary,
    'OUT_FOR_DELIVERY': AppColors.patientPrimary,
    'FULFILLED': AppColors.tealAccent,
    'REJECTED': AppColors.errorRed,
  };

  static const _labelKeys = <String, String>{
    'RECEIVED': 'pharmacy_booking.orders.status_received',
    'UNDER_REVIEW': 'pharmacy_booking.orders.status_under_review',
    'ACCEPTED': 'pharmacy_booking.orders.status_accepted',
    'PAID': 'pharmacy_booking.orders.status_paid',
    'READY_FOR_PICKUP': 'pharmacy_booking.orders.status_ready_for_pickup',
    'OUT_FOR_DELIVERY': 'pharmacy_booking.orders.status_out_for_delivery',
    'FULFILLED': 'pharmacy_booking.orders.status_fulfilled',
    'REJECTED': 'pharmacy_booking.orders.status_rejected',
  };

  /// Exposed so other widgets rendering a `PharmacyOrderDetail` (e.g. the
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

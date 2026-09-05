import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:med_super/core/theme/app_colors.dart';
import 'package:med_super/core/theme/app_radii.dart';
import 'package:med_super/core/theme/color_schemes.dart';
import 'package:med_super/core/widgets/async_value_view.dart';
import 'package:med_super/features/lab_booking/domain/entities/lab_order_detail.dart';
import 'package:med_super/features/lab_booking/presentation/controllers/lab_order_list_providers.dart';
import 'package:med_super/features/lab_booking/presentation/widgets/lab_order_status_pill.dart';
import 'package:med_super/features/pharmacy_booking/domain/utils/order_id_format.dart';

String _formatOrderDate(String iso) {
  final parsed = DateTime.tryParse(iso);
  if (parsed == null) return iso;
  return DateFormat('d MMM y, h:mm a').format(parsed.toLocal());
}

/// `GET /v1/lab-orders/:id` — a single lab request's detail: status, the
/// quote once staff has priced it, the booking code once confirmed, and
/// each requested test's own result state. Mirrors
/// `pharmacy_booking`'s `PharmacyOrderDetailScreen` — no approve/pay or
/// confirm-receipt action here, since a lab order has no patient-side action
/// at all (payment is out of scope, `DEC-002`; results delivery is a staff
/// self-attestation, `DEC-004`).
class LabOrderDetailScreen extends ConsumerWidget {
  const LabOrderDetailScreen({required this.orderId, super.key});

  final String orderId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(labOrderDetailProvider(orderId));

    return Scaffold(
      backgroundColor: AppColors.surfaceApp,
      appBar: AppBar(
        title: Text('lab_booking.orders.detail_title'.tr()),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.ink900,
        elevation: 0,
        // The confirmation screen's "تتبع الطلب" reaches this route via
        // `context.go` (a stack replace, not a push), so `context.pop()` has
        // nothing to pop when arriving that way — falling back to the
        // orders list keeps this screen from ever being a dead end.
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'lab_booking.orders.back_to_list'.tr(),
          onPressed: () =>
              context.canPop() ? context.pop() : context.go('/patient/orders'),
        ),
      ),
      body: AsyncValueView(
        value: detailAsync,
        onRetry: () => ref.invalidate(labOrderDetailProvider(orderId)),
        data: (order) => _OrderDetailBody(order: order),
      ),
    );
  }
}

class _OrderDetailBody extends StatelessWidget {
  const _OrderDetailBody({required this.order});

  final LabOrderDetail order;

  @override
  Widget build(BuildContext context) {
    final quote = order.quote;
    final rejection = order.rejection;
    final textTheme = Theme.of(context).textTheme;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border(
              left: BorderSide(
                width: 5,
                color: LabOrderStatusPill.colorFor(order.status),
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    LabOrderStatusPill(status: order.status),
                    const Spacer(),
                    Text(
                      '#${shortOrderId(order.id)}',
                      style: textTheme.bodySmall?.copyWith(
                        color: AppColors.ink900,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEEF4FF),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.biotech_outlined,
                        size: 20,
                        color: brandBlue,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  _formatOrderDate(order.createdAt),
                  style: textTheme.bodySmall?.copyWith(
                    color: AppColors.mutedText2,
                  ),
                ),
                if (order.updatedAt.isNotEmpty &&
                    order.updatedAt != order.createdAt) ...[
                  const SizedBox(height: 4),
                  Text(
                    '${'lab_booking.orders.updated_at_label'.tr()}: ${_formatOrderDate(order.updatedAt)}',
                    style: textTheme.bodySmall?.copyWith(
                      color: AppColors.mutedText2,
                    ),
                  ),
                ],
                if (order.bookingCode != null &&
                    order.bookingCode!.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  const Divider(height: 1, color: Color(0xFFEFF2F7)),
                  const SizedBox(height: 10),
                  Text(
                    '${'lab_booking.orders.booking_code_label'.tr()}: ${order.bookingCode}',
                    style: textTheme.bodySmall?.copyWith(
                      color: AppColors.patientPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        if (order.items.isNotEmpty) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppRadii.md),
              border: Border.all(color: AppColors.borderLight),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'lab_booking.orders.items_label'.tr(),
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink900,
                  ),
                ),
                const SizedBox(height: 10),
                for (final item in order.items)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            item.displayName,
                            style: const TextStyle(color: AppColors.ink900),
                          ),
                        ),
                        Text(
                          item.resultState,
                          style: const TextStyle(
                            color: AppColors.mutedText2,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
        if (quote != null) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppRadii.md),
              border: Border.all(color: AppColors.borderLight),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('lab_booking.orders.quote_total_label'.tr()),
                    Text(
                      '${quote.totalPrice} ${quote.currency}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.patientPrimary,
                      ),
                    ),
                  ],
                ),
                if (quote.appointmentAt.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    '${'lab_booking.orders.appointment_label'.tr()}: ${_formatOrderDate(quote.appointmentAt)}',
                    style: const TextStyle(color: AppColors.mutedText2),
                  ),
                ],
                if (quote.prepInstructions.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    '${'lab_booking.orders.prep_instructions_label'.tr()}: ${quote.prepInstructions}',
                    style: const TextStyle(color: AppColors.mutedText2),
                  ),
                ],
              ],
            ),
          ),
        ],
        if (rejection != null) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.errorRed.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(AppRadii.md),
            ),
            child: Text(
              '${'lab_booking.orders.rejection_label'.tr()}: ${rejection.reason}',
              style: const TextStyle(color: AppColors.errorRed),
            ),
          ),
        ],
      ],
    );
  }
}

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:med_super/core/theme/app_colors.dart';
import 'package:med_super/core/theme/app_radii.dart';
import 'package:med_super/core/theme/color_schemes.dart';
import 'package:med_super/core/widgets/app_button.dart';
import 'package:med_super/core/widgets/app_nav_icons.dart';
import 'package:med_super/core/widgets/async_value_view.dart';
import 'package:med_super/core/widgets/image_gallery_viewer.dart';
import 'package:med_super/features/pharmacy_booking/domain/entities/delivery_method.dart';
import 'package:med_super/features/pharmacy_booking/domain/entities/pharmacy_order_detail.dart';
import 'package:med_super/features/pharmacy_booking/domain/utils/order_id_format.dart';
import 'package:med_super/features/pharmacy_booking/presentation/controllers/pharmacy_order_list_providers.dart';
import 'package:med_super/features/pharmacy_booking/presentation/widgets/pharmacy_order_status_pill.dart';
import 'package:solar_icons/solar_icons.dart';

/// `order.createdAt` is a raw ISO-8601 string straight off the wire — shown
/// formatted, never as the literal `2026-09-01T01:08:15.961Z`. Falls back to
/// the raw string if it somehow doesn't parse, rather than crashing the
/// whole detail screen over a display nicety.
String _formatOrderDate(String iso) {
  final parsed = DateTime.tryParse(iso);
  if (parsed == null) return iso;
  return DateFormat('d MMM y, h:mm a').format(parsed.toLocal());
}

String _prescriptionHeroTag(String orderId, int index) =>
    'pharmacy-order-$orderId-prescription-$index';

/// `GET /v1/pharmacy-orders/:id` — a read-only patient view of pharmacy
/// pricing and fulfillment status, plus receipt confirmation for delivery.
class PharmacyOrderDetailScreen extends ConsumerWidget {
  const PharmacyOrderDetailScreen({required this.orderId, super.key});

  final String orderId;

  Future<void> _confirmReceipt(BuildContext context, WidgetRef ref) async {
    // Terminal action, no undo (same "ask before an irreversible action"
    // convention as `appointment_detail_screen.dart`'s cancel dialog) — the
    // order closes to FULFILLED the moment this is confirmed.
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'pharmacy_booking.orders.confirm_receipt_dialog_title'.tr(),
        ),
        content: Text(
          'pharmacy_booking.orders.confirm_receipt_dialog_message'.tr(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'pharmacy_booking.orders.confirm_receipt_dialog_dismiss'.tr(),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              'pharmacy_booking.orders.confirm_receipt_dialog_confirm'.tr(),
              style: const TextStyle(
                color: AppColors.patientPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    await ref
        .read(pharmacyOrderConfirmReceiptControllerProvider.notifier)
        .confirmReceipt(orderId);
    if (!context.mounted) return;

    final result = ref.read(pharmacyOrderConfirmReceiptControllerProvider);
    if (result.hasError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('pharmacy_booking.orders.confirm_receipt_error'.tr()),
        ),
      );
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('pharmacy_booking.orders.confirm_receipt_success'.tr()),
      ),
    );
    ref.invalidate(pharmacyOrderDetailProvider(orderId));
    ref.invalidate(pharmacyOrdersProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(pharmacyOrderDetailProvider(orderId));
    final confirmingReceipt = ref
        .watch(pharmacyOrderConfirmReceiptControllerProvider)
        .isLoading;

    return Scaffold(
      backgroundColor: AppColors.surfaceApp,
      appBar: AppBar(
        title: Text('pharmacy_booking.orders.detail_title'.tr()),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.ink900,
        elevation: 0,
        // The confirmation screen's "تتبع الطلب" reaches this route via
        // `context.go` (a stack replace, not a push), so `context.pop()`
        // has nothing to pop when arriving that way — falling back to the
        // orders list keeps this screen from ever being a dead end
        // regardless of how the patient got here.
        leading: IconButton(
          icon: Icon(AppNavIcons.back(context)),
          tooltip: 'pharmacy_booking.orders.back_to_list'.tr(),
          onPressed: () =>
              context.canPop() ? context.pop() : context.go('/patient/orders'),
        ),
      ),
      body: AsyncValueView(
        value: detailAsync,
        onRetry: () => ref.invalidate(pharmacyOrderDetailProvider(orderId)),
        data: (order) => _OrderDetailBody(
          order: order,
          confirmingReceipt: confirmingReceipt,
          onConfirmReceipt: () => _confirmReceipt(context, ref),
        ),
      ),
    );
  }
}

class _OrderDetailBody extends StatelessWidget {
  const _OrderDetailBody({
    required this.order,
    required this.confirmingReceipt,
    required this.onConfirmReceipt,
  });

  final PharmacyOrderDetail order;
  final bool confirmingReceipt;
  final VoidCallback onConfirmReceipt;

  @override
  Widget build(BuildContext context) {
    final quote = order.quote;
    final rejection = order.rejection;
    final textTheme = Theme.of(context).textTheme;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Same card language as the orders-list card (colored left border by
        // status, rounded white card, icon badge) instead of a plain bordered
        // box, so this screen doesn't look like a different app.
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border(
              left: BorderSide(
                width: 5,
                color: PharmacyOrderStatusPill.colorFor(order.status),
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
                    PharmacyOrderStatusPill(status: order.status),
                    const Spacer(),
                    Text(
                      // `shortOrderId` — same truncation the confirmation
                      // screen uses, so this never again reads as a
                      // different order number for the same order.
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
                        SolarIconsOutline.pills,
                        size: 20,
                        color: brandBlue,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  order.pharmacyName ??
                      'pharmacy_booking.orders.pharmacy_label'.tr(),
                  style: textTheme.titleSmall?.copyWith(
                    color: brandBlue,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  DeliveryMethod.fromApiValue(
                    order.fulfillmentType,
                  ).titleKey.tr(),
                  style: textTheme.bodySmall?.copyWith(color: AppColors.ink900),
                ),
                const SizedBox(height: 4),
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
                    '${'pharmacy_booking.orders.updated_at_label'.tr()}: ${_formatOrderDate(order.updatedAt)}',
                    style: textTheme.bodySmall?.copyWith(
                      color: AppColors.mutedText2,
                    ),
                  ),
                ],
                if (order.doctorName != null &&
                    order.doctorName!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    '${'pharmacy_booking.orders.doctor_label'.tr()}: ${order.doctorName}',
                    style: textTheme.bodySmall?.copyWith(
                      color: AppColors.mutedText2,
                    ),
                  ),
                ],
                if (order.patientNote != null &&
                    order.patientNote!.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  const Divider(height: 1, color: Color(0xFFEFF2F7)),
                  const SizedBox(height: 10),
                  Text(
                    '${'pharmacy_booking.orders.patient_note_label'.tr()}: ${order.patientNote}',
                    style: textTheme.bodySmall?.copyWith(
                      color: AppColors.mutedText2,
                    ),
                  ),
                ],
                // Only shown when there's no quote — `quote.note` is the
                // exact same `staff_note` column, already rendered in the
                // quote card below once a quote exists, so this avoids
                // printing the identical text twice.
                if (quote == null &&
                    order.staffNote != null &&
                    order.staffNote!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    '${'pharmacy_booking.orders.staff_note_label'.tr()}: ${order.staffNote}',
                    style: textTheme.bodySmall?.copyWith(
                      color: AppColors.mutedText2,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        if (order.prescriptionImages.isNotEmpty) ...[
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
                  'pharmacy_booking.orders.prescription_images_label'.tr(),
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink900,
                  ),
                ),
                const SizedBox(height: 12),
                // Portrait 3:4 tiles — prescriptions are almost always
                // photographed upright, so a square crop cut off most of
                // the content. Tapping opens the full-screen viewer.
                SizedBox(
                  height: 128,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: order.prescriptionImages.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 10),
                    itemBuilder: (context, i) => _PrescriptionThumbnail(
                      url: order.prescriptionImages[i].fileUrl,
                      heroTag: _prescriptionHeroTag(order.id, i),
                      onTap: () => ImageGalleryViewer.open(
                        context,
                        imageUrls: [
                          for (final image in order.prescriptionImages)
                            image.fileUrl,
                        ],
                        initialIndex: i,
                        heroTagFor: (index) =>
                            _prescriptionHeroTag(order.id, index),
                      ),
                    ),
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
                    Text('pharmacy_booking.orders.quote_total_label'.tr()),
                    Text(
                      '${quote.totalPrice} ${quote.currency}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.patientPrimary,
                      ),
                    ),
                  ],
                ),
                if (quote.note != null && quote.note!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    '${'pharmacy_booking.orders.quote_note_label'.tr()}: ${quote.note}',
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
              '${'pharmacy_booking.orders.rejection_label'.tr()}: ${rejection.reason}',
              style: const TextStyle(color: AppColors.errorRed),
            ),
          ),
        ],
        if (order.canConfirmReceipt) ...[
          const SizedBox(height: 24),
          AppButton.filled(
            label: 'pharmacy_booking.orders.confirm_receipt_cta'.tr(),
            fullWidth: true,
            isLoading: confirmingReceipt,
            backgroundColor: AppColors.patientPrimary,
            foregroundColor: Colors.white,
            borderRadius: AppRadii.xl,
            onPressed: confirmingReceipt ? null : onConfirmReceipt,
          ),
        ],
      ],
    );
  }
}

class _PrescriptionThumbnail extends StatelessWidget {
  const _PrescriptionThumbnail({
    required this.url,
    required this.heroTag,
    required this.onTap,
  });

  final String url;
  final Object heroTag;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceMuted,
      borderRadius: BorderRadius.circular(AppRadii.sm),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          width: 96,
          height: 128,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Hero(
                tag: heroTag,
                child: Image.network(
                  url,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => const Icon(
                    SolarIconsOutline.gallery,
                    color: AppColors.mutedText2,
                  ),
                ),
              ),
              PositionedDirectional(
                bottom: 6,
                end: 6,
                child: Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    SolarIconsOutline.maximizeSquare,
                    size: 14,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

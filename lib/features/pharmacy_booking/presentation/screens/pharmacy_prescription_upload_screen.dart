import 'package:easy_localization/easy_localization.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:med_super/core/theme/app_colors.dart';
import 'package:med_super/core/theme/app_radii.dart';
import 'package:med_super/core/widgets/app_button.dart';
import 'package:med_super/core/widgets/step_progress_header.dart';
import 'package:med_super/features/pharmacy_booking/domain/entities/delivery_method.dart';
import 'package:med_super/features/pharmacy_booking/domain/entities/prescription_image.dart';
import 'package:med_super/features/pharmacy_booking/presentation/controllers/pharmacy_search_providers.dart';
import 'package:med_super/features/pharmacy_booking/presentation/controllers/pharmacy_upload_providers.dart';
import 'package:med_super/features/pharmacy_booking/presentation/controllers/prescription_upload_controller.dart';
import 'package:solar_icons/solar_icons.dart';

/// Step 1 of the pharmacy booking flow — attach a photo of the prescription
/// and choose how the medication should be received. Mirrors the structure
/// of `LabRequestUploadScreen` (lab_booking), including its back-button
/// header, with side-by-side delivery-method cards per the mockup.
class PharmacyPrescriptionUploadScreen extends ConsumerStatefulWidget {
  const PharmacyPrescriptionUploadScreen({this.resetFlow = false, super.key});

  final bool? resetFlow;

  @override
  ConsumerState<PharmacyPrescriptionUploadScreen> createState() =>
      _PharmacyPrescriptionUploadScreenState();
}

class _PharmacyPrescriptionUploadScreenState
    extends ConsumerState<PharmacyPrescriptionUploadScreen> {
  final _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.resetFlow != true) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _startNewPharmacyFlow();
    });
  }

  void _startNewPharmacyFlow() {
    ref.read(uploadedPrescriptionImagesProvider.notifier).clear();
    ref.read(selectedDeliveryMethodProvider.notifier).reset();
    ref.read(selectedPharmacyProvider.notifier).clear();
    ref.read(pharmacySearchQueryProvider.notifier).setQuery('');
    ref.invalidate(pharmacySearchProvider);
    ref.invalidate(prescriptionUploadControllerProvider);
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    FilePickerResult? result;
    try {
      result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: true,
        // Bytes (not just a path) are required on every platform: on
        // Flutter Web there is no real filesystem path to read from later,
        // and dart:io's File/Image.file don't work there at all.
        withData: true,
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('errors.image_picker_failed'.tr())),
      );
      return;
    }
    final files = result?.files ?? const <PlatformFile>[];
    if (files.isEmpty) return;
    final added = ref
        .read(uploadedPrescriptionImagesProvider.notifier)
        .addImages(
          files.map(
            (file) => (path: file.path ?? file.name, bytes: file.bytes),
          ),
        );
    if (!mounted || added >= files.length) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'pharmacy_booking.upload.max_images_reached'.tr(
            args: ['$maxPrescriptionImages'],
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    final images = ref.read(uploadedPrescriptionImagesProvider);
    final notes = _notesController.text.trim();
    await ref
        .read(prescriptionUploadControllerProvider.notifier)
        .submit(images: images, notes: notes.isEmpty ? null : notes);
    if (!mounted) return;
    final result = ref.read(prescriptionUploadControllerProvider);
    if (result.hasError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('pharmacy_booking.upload.submit_error'.tr())),
      );
      return;
    }
    if (!mounted) return;
    context.push('/patient/pharmacy/select');
  }

  @override
  Widget build(BuildContext context) {
    final images = ref.watch(uploadedPrescriptionImagesProvider);
    final selectedMethod = ref.watch(selectedDeliveryMethodProvider);
    final canSubmit = ref.watch(canSubmitPrescriptionUploadProvider);
    final isSubmitting = ref
        .watch(prescriptionUploadControllerProvider)
        .isLoading;

    return Scaffold(
      backgroundColor: AppColors.surfaceApp,
      body: SafeArea(
        child: Column(
          children: [
            const _Header(),
            StepProgressHeader(
              stepLabels: [
                'pharmacy_booking.step_upload'.tr(),
                'pharmacy_booking.step_pharmacy'.tr(),
                'pharmacy_booking.step_delivery'.tr(),
              ],
              currentStep: 0,
              accentColor: AppColors.patientPrimary,
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                children: [
                  _UploadBox(onTap: _pickImages),
                  if (images.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _ImageThumbnailRow(
                      images: images,
                      onAdd: _pickImages,
                      onRemove: (id) => ref
                          .read(uploadedPrescriptionImagesProvider.notifier)
                          .removeImage(id),
                    ),
                  ],
                  const SizedBox(height: 32),
                  _DeliveryMethodSection(
                    selected: selectedMethod,
                    onSelect: (method) => ref
                        .read(selectedDeliveryMethodProvider.notifier)
                        .select(method),
                  ),
                  const SizedBox(height: 24),
                  _NotesField(controller: _notesController),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: AppButton.filled(
                label: 'pharmacy_booking.upload.submit_cta'.tr(),
                fullWidth: true,
                backgroundColor: AppColors.patientPrimary,
                foregroundColor: Colors.white,
                borderRadius: AppRadii.xl,
                isLoading: isSubmitting,
                onPressed: (canSubmit && !isSubmitting) ? _submit : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surfaceApp,
      padding: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Balances the trailing back button's width so the title stays
            // visually centered — mirrors LabRequestUploadScreen's header.
            const SizedBox(width: 48),
            Expanded(
              child: Text(
                'pharmacy_booking.upload.title'.tr(),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: AppColors.ink900,
                ),
              ),
            ),
            IconButton(
              onPressed: () => context.pop(),
              icon: const Icon(SolarIconsOutline.arrowRight),
            ),
          ],
        ),
      ),
    );
  }
}

/// Big dashed-border tap target — the primary way to attach the first
/// image(s) of the prescription.
class _UploadBox extends StatelessWidget {
  const _UploadBox({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadii.xl),
      child: CustomPaint(
        painter: const _DashedRRectPainter(
          color: AppColors.borderMedium,
          radius: AppRadii.xl,
        ),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppRadii.xl),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.patientPrimary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  SolarIconsOutline.cameraAdd,
                  color: AppColors.patientPrimary,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'pharmacy_booking.upload.upload_cta'.tr(),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'pharmacy_booking.upload.upload_hint'.tr(),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.mutedText,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Horizontal row below the upload box: one tile per attached image (each
/// with a red delete badge) followed by a small dashed "+" tile to attach
/// more without scrolling back up to [_UploadBox].
class _ImageThumbnailRow extends StatelessWidget {
  const _ImageThumbnailRow({
    required this.images,
    required this.onAdd,
    required this.onRemove,
  });

  final List<PrescriptionImage> images;
  final VoidCallback onAdd;
  final ValueChanged<String> onRemove;

  static const _tileSize = 80.0;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _tileSize,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: images.length + 1,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          if (index == images.length) {
            return _AddImageTile(onTap: onAdd, size: _tileSize);
          }
          final image = images[index];
          return _ImageThumbnail(
            key: ValueKey(image.id),
            image: image,
            size: _tileSize,
            onRemove: () => onRemove(image.id),
          );
        },
      ),
    );
  }
}

class _AddImageTile extends StatelessWidget {
  const _AddImageTile({required this.onTap, required this.size});

  final VoidCallback onTap;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'pharmacy_booking.upload.add_image_tooltip'.tr(),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadii.md),
        child: CustomPaint(
          painter: const _DashedRRectPainter(
            color: AppColors.borderMedium,
            radius: AppRadii.md,
          ),
          child: SizedBox(
            width: size,
            height: size,
            child: const Icon(Icons.add, color: AppColors.patientPrimary),
          ),
        ),
      ),
    );
  }
}

class _ImageThumbnail extends StatelessWidget {
  const _ImageThumbnail({
    required this.image,
    required this.size,
    required this.onRemove,
    super.key,
  });

  final PrescriptionImage image;
  final double size;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadii.md),
          child: Container(
            width: size,
            height: size,
            color: AppColors.surfaceMuted,
            child: image.bytes == null
                ? const Icon(SolarIconsOutline.gallery, color: AppColors.mutedText)
                : Image.memory(
                    image.bytes!,
                    width: size,
                    height: size,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => const Icon(
                      SolarIconsOutline.gallery,
                      color: AppColors.mutedText,
                    ),
                  ),
          ),
        ),
        Positioned(
          top: -6,
          right: -6,
          child: Tooltip(
            message: 'pharmacy_booking.upload.remove_image_tooltip'.tr(),
            child: GestureDetector(
              onTap: onRemove,
              child: Container(
                width: 22,
                height: 22,
                decoration: const BoxDecoration(
                  color: AppColors.errorRed,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, size: 14, color: Colors.white),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// "طريقة الاستلام" — the three side-by-side selectable delivery cards.
/// Defaults to [DeliveryMethod.homeDelivery] (see
/// [SelectedDeliveryMethod]).
class _DeliveryMethodSection extends StatelessWidget {
  const _DeliveryMethodSection({
    required this.selected,
    required this.onSelect,
  });

  final DeliveryMethod selected;
  final ValueChanged<DeliveryMethod> onSelect;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'pharmacy_booking.upload.delivery_method_title'.tr(),
          textAlign: TextAlign.right,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.ink900,
          ),
        ),
        const SizedBox(height: 16),
        // `IntrinsicHeight` so all three cards match the tallest one's
        // height — without it, each `_DeliveryMethodCard` sizes to only its
        // own title's wrap (2 vs 3 Arabic words wrap differently), leaving
        // the three cards visibly different heights side by side.
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _DeliveryMethodCard(
                  method: DeliveryMethod.pickup,
                  isSelected: selected == DeliveryMethod.pickup,
                  icon: SolarIconsOutline.shop,
                  onTap: () => onSelect(DeliveryMethod.pickup),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _DeliveryMethodCard(
                  method: DeliveryMethod.homeDelivery,
                  isSelected: selected == DeliveryMethod.homeDelivery,
                  icon: SolarIconsOutline.delivery,
                  onTap: () => onSelect(DeliveryMethod.homeDelivery),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _DeliveryMethodCard(
                  method: DeliveryMethod.clinicHandover,
                  isSelected: selected == DeliveryMethod.clinicHandover,
                  icon: SolarIconsOutline.hospital,
                  onTap: () => onSelect(DeliveryMethod.clinicHandover),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DeliveryMethodCard extends StatelessWidget {
  const _DeliveryMethodCard({
    required this.method,
    required this.isSelected,
    required this.icon,
    required this.onTap,
  });

  final DeliveryMethod method;
  final bool isSelected;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadii.lg),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppRadii.lg),
          border: Border.all(
            color: isSelected
                ? AppColors.patientPrimary
                : AppColors.borderLight,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected ? AppColors.patientPrimary : Colors.white,
                    border: Border.all(
                      color: isSelected
                          ? AppColors.patientPrimary
                          : AppColors.borderMedium,
                      width: 2,
                    ),
                  ),
                  child: isSelected
                      ? const Icon(Icons.check, size: 14, color: Colors.white)
                      : null,
                ),
                Icon(icon, color: AppColors.patientPrimary),
              ],
            ),
            const SizedBox(height: 12),
            // Fixed to 2 lines regardless of actual wrap so all three cards
            // reserve identical title height — "توصيل للمنزل" (2 words) vs
            // "تسليم في العيادة"/"استلام من الصيدلية" (3 words) would
            // otherwise wrap to a different number of lines and make this
            // card visibly shorter than its siblings.
            SizedBox(
              height: 36,
              child: Text(
                method.titleKey.tr(),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink900,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotesField extends StatelessWidget {
  const _NotesField({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'pharmacy_booking.upload.notes_label'.tr(),
          textAlign: TextAlign.right,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.ink900,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          minLines: 3,
          maxLines: 4,
          // Backend caps `notes` at 500 chars (`UploadPrescriptionDto`,
          // File 12 Part 37.2) — enforced client-side too.
          maxLength: 500,
          decoration: InputDecoration(
            hintText: 'pharmacy_booking.upload.notes_hint'.tr(),
            hintStyle: const TextStyle(color: AppColors.mutedText),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.all(12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadii.md),
              borderSide: const BorderSide(color: AppColors.borderLight),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadii.md),
              borderSide: const BorderSide(color: AppColors.borderLight),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadii.md),
              borderSide: const BorderSide(color: AppColors.patientPrimary),
            ),
          ),
        ),
      ],
    );
  }
}

/// Draws a dashed rounded-rect border. Used for both the big upload box and
/// the small "+" tile — mirrors the lab_booking template's private painter.
class _DashedRRectPainter extends CustomPainter {
  const _DashedRRectPainter({required this.color, required this.radius});

  final Color color;
  final double radius;

  static const _dashWidth = 6.0;
  static const _dashSpace = 4.0;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(radius),
    );
    final dashPath = Path();
    for (final metric in (Path()..addRRect(rrect)).computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        dashPath.addPath(
          metric.extractPath(distance, distance + _dashWidth),
          Offset.zero,
        );
        distance += _dashWidth + _dashSpace;
      }
    }
    canvas.drawPath(dashPath, paint);
  }

  @override
  bool shouldRepaint(covariant _DashedRRectPainter oldDelegate) =>
      color != oldDelegate.color || radius != oldDelegate.radius;
}

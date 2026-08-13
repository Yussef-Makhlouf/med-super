import 'package:easy_localization/easy_localization.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:med_super/core/theme/app_colors.dart';
import 'package:med_super/core/theme/app_radii.dart';
import 'package:med_super/core/widgets/app_button.dart';
import 'package:med_super/core/widgets/step_progress_header.dart';
import 'package:med_super/features/lab_booking/domain/entities/lab_request_image.dart';
import 'package:med_super/features/lab_booking/domain/entities/lab_service_type.dart';
import 'package:med_super/features/lab_booking/presentation/controllers/lab_upload_providers.dart';

/// Step 1 of the lab booking flow — attach a photo of the paper/digital lab
/// request and choose how the sample should be collected. Figma screen 1
/// ("تحميل طلب المختبر"). Replaces the old test-catalog picker that used to
/// live in this slot (`LabTestSelectionScreen`).
class LabRequestUploadScreen extends ConsumerStatefulWidget {
  const LabRequestUploadScreen({super.key});

  @override
  ConsumerState<LabRequestUploadScreen> createState() =>
      _LabRequestUploadScreenState();
}

class _LabRequestUploadScreenState
    extends ConsumerState<LabRequestUploadScreen> {
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
      // No translation key for this error exists in the Stage A3 contract
      // and this screen has no other localized fallback text to reuse, so
      // a plain literal is used here per the plan's placeholder rule —
      // flagged in the final report as needing a real translation key.
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not open the image picker. Please try again.'),
        ),
      );
      return;
    }
    final files = result?.files ?? const <PlatformFile>[];
    if (files.isEmpty) return;
    ref
        .read(uploadedLabRequestImagesProvider.notifier)
        .addImages(
          files.map(
            (file) => (path: file.path ?? file.name, bytes: file.bytes),
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    final images = ref.watch(uploadedLabRequestImagesProvider);
    final selectedType = ref.watch(selectedLabServiceTypeProvider);
    final canContinue = ref.watch(canContinueFromUploadProvider);

    return Scaffold(
      backgroundColor: AppColors.surfaceApp,
      body: SafeArea(
        child: Column(
          children: [
            const _Header(),
            StepProgressHeader(
              // Same step labels/order as the other two screens of this
              // flow — the stepper must read identically everywhere.
              stepLabels: [
                'lab_booking.step_upload'.tr(),
                'lab_booking.step_select_lab'.tr(),
                'lab_booking.step_review'.tr(),
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
                          .read(uploadedLabRequestImagesProvider.notifier)
                          .removeImage(id),
                    ),
                  ],
                  const SizedBox(height: 32),
                  _ServiceTypeSection(
                    selected: selectedType,
                    onSelect: (type) => ref
                        .read(selectedLabServiceTypeProvider.notifier)
                        .select(type),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: AppButton.filled(
                label: 'lab_booking.upload.continue_cta'.tr(),
                fullWidth: true,
                // Explicit brand color/radius — the shared ElevatedButton
                // theme default is colorScheme.primary (brandBlue), which is
                // a visibly different blue than AppColors.patientPrimary
                // used everywhere else in this flow (stepper accent, price
                // text, every other CTA). Must match the mockup exactly.
                backgroundColor: AppColors.patientPrimary,
                // Without this, ElevatedButton's default M3 style computes
                // the label color against the *theme's* primary rather
                // than this explicit override, landing on a low-contrast
                // near-invisible blue-on-blue label.
                foregroundColor: Colors.white,
                borderRadius: AppRadii.xl,
                onPressed: canContinue
                    ? () => context.push('/patient/lab/select-lab')
                    : null,
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
            // Balances the trailing back button's width so the title
            // stays visually centered now that nothing occupies the
            // leading slot (the mockup's help icon was dropped — no help
            // content exists for this screen).
            const SizedBox(width: 48),
            Expanded(
              child: Text(
                'lab_booking.upload.title'.tr(),
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
              icon: const Icon(Icons.arrow_forward),
            ),
          ],
        ),
      ),
    );
  }
}

/// Big dashed-border tap target — the primary way to attach the first
/// image(s) of the lab request.
class _UploadBox extends StatelessWidget {
  const _UploadBox({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadii.lg),
      child: CustomPaint(
        painter: const _DashedRRectPainter(
          color: AppColors.borderMedium,
          radius: AppRadii.lg,
        ),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppRadii.lg),
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
                  Icons.add_a_photo_outlined,
                  color: AppColors.patientPrimary,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'lab_booking.upload.upload_cta'.tr(),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'lab_booking.upload.upload_hint'.tr(),
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

  final List<LabRequestImage> images;
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
      message: 'lab_booking.upload.add_image_tooltip'.tr(),
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

  final LabRequestImage image;
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
                ? const Icon(Icons.image_outlined, color: AppColors.mutedText)
                : Image.memory(
                    image.bytes!,
                    width: size,
                    height: size,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => const Icon(
                      Icons.image_outlined,
                      color: AppColors.mutedText,
                    ),
                  ),
          ),
        ),
        Positioned(
          top: -6,
          right: -6,
          child: Tooltip(
            message: 'lab_booking.upload.remove_image_tooltip'.tr(),
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

/// "نوع الخدمة" — the two selectable service-type cards. No default
/// selection on purpose (see [SelectedLabServiceType]).
class _ServiceTypeSection extends StatelessWidget {
  const _ServiceTypeSection({required this.selected, required this.onSelect});

  final LabServiceType? selected;
  final ValueChanged<LabServiceType> onSelect;

  // Purple tokens for the home-collection icon badge — not part of the
  // shared AppColors palette (only this card uses purple), so kept local.
  static const _homeIconBg = Color(0xFFF3E8FF);
  static const _homeIconColor = Color(0xFF9333EA);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Container(
              width: 4,
              height: 20,
              decoration: BoxDecoration(
                color: AppColors.patientPrimary,
                borderRadius: BorderRadius.circular(AppRadii.pill),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'lab_booking.upload.service_type_title'.tr(),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.ink900,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _ServiceTypeCard(
          type: LabServiceType.branchVisit,
          isSelected: selected == LabServiceType.branchVisit,
          icon: Icons.apartment_outlined,
          iconBg: AppColors.tealBg,
          iconColor: AppColors.tealAccent,
          onTap: () => onSelect(LabServiceType.branchVisit),
        ),
        const SizedBox(height: 12),
        _ServiceTypeCard(
          type: LabServiceType.homeCollection,
          isSelected: selected == LabServiceType.homeCollection,
          icon: Icons.medical_services_outlined,
          iconBg: _homeIconBg,
          iconColor: _homeIconColor,
          onTap: () => onSelect(LabServiceType.homeCollection),
        ),
      ],
    );
  }
}

class _ServiceTypeCard extends StatelessWidget {
  const _ServiceTypeCard({
    required this.type,
    required this.isSelected,
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.onTap,
  });

  final LabServiceType type;
  final bool isSelected;
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadii.lg),
      child: Container(
        padding: const EdgeInsets.all(16),
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
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
              child: Icon(icon, color: iconColor),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    type.titleKey.tr(),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    type.subtitleKey.tr(),
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.mutedText,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
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
          ],
        ),
      ),
    );
  }
}

/// Draws a dashed rounded-rect border. Used for both the big upload box and
/// the small "+" tile — Flutter has no built-in dashed border and this
/// feature owns no other file where a reusable widget could live, so it's
/// kept private to this screen.
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

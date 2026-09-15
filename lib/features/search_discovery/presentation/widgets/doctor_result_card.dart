import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:med_super/core/theme/app_palette.dart';
import 'package:med_super/core/theme/app_radii.dart';
import 'package:med_super/core/theme/app_shadows.dart';
import 'package:med_super/core/utils/avatar_image.dart';
import 'package:med_super/core/widgets/app_icon_tile.dart';
import 'package:med_super/features/search_discovery/domain/entities/doctor_summary.dart';
import 'package:solar_icons/solar_icons.dart';

class DoctorResultCard extends StatefulWidget {
  const DoctorResultCard({
    required this.doctor,
    required this.onBook,
    required this.onTap,
    super.key,
  });

  final DoctorSummary doctor;
  final VoidCallback onBook;
  final VoidCallback onTap;

  @override
  State<DoctorResultCard> createState() => _DoctorResultCardState();
}

class _DoctorResultCardState extends State<DoctorResultCard> {
  // Both `onTap` (the card's own InkWell) and `onBook` (the nested "Book
  // Now" button) call the same navigation in every current caller — a
  // FilledButton nested inside an InkWell normally absorbs its own taps,
  // but on Flutter web a mouse click can occasionally reach both handlers
  // in the same gesture-arena pass, firing the identical `context.push`
  // twice. go_router then ends up with two pages computing the same key in
  // its stack at once, tripping the framework's
  // "!keyReservation.contains(key)" duplicate-page assertion on the next
  // frame. This flag collapses both handlers into a single fire per tap.
  bool _handled = false;

  void _guardedTap(VoidCallback action) {
    if (_handled) return;
    setState(() => _handled = true);
    action();
    // Reset on the next frame rather than staying permanently latched —
    // this widget doesn't unmount on navigation away/back (it's reused in
    // a scrolling list), so a one-shot flag would wrongly disable taps
    // forever after the first one.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _handled = false);
    });
  }

  DoctorSummary get doctor => widget.doctor;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final feeLabel = doctor.currency == 'EGP'
        ? '${doctor.consultationFee} ج.م'
        : '${doctor.consultationFee} ${doctor.currency}';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        boxShadow: AppShadows.resting,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        child: InkWell(
          onTap: () => _guardedTap(widget.onTap),
          borderRadius: BorderRadius.circular(AppRadii.lg),
          hoverColor: Colors.transparent,
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadii.lg),
            ),
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DoctorAvatar(
                      name: doctor.name,
                      photoUrl: doctor.photoUrl,
                      size: 64,
                      borderRadius: BorderRadius.circular(AppRadii.md),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // `doctor.isVerified` is never true here — the real
                          // `GET /v1/doctors/search` response
                          // (`SearchDoctorItem`) has no verification field at
                          // all, so this always defaulted to `false`. Removed
                          // rather than kept as permanently-dead UI; doctor
                          // detail (`GET /v1/doctors/{id}`) does carry a real
                          // `status` and shows verification there instead.
                          Text(
                            doctor.name,
                            style: textTheme.titleMedium?.copyWith(
                              color: AppPalette.primary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            doctor.specialty,
                            style: textTheme.bodyMedium?.copyWith(
                              color: AppPalette.primary.withValues(alpha: 0.85),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          // Experience-years row removed — `SearchDoctorItem`
                          // (the real `GET /v1/doctors/search` shape) has no
                          // `experience_years` field, so this always rendered
                          // "0 سنوات خبرة" against a live backend. The doctor
                          // detail screen shows the real value where it
                          // exists (`Doctor.experience_years`, ADR-005 Part
                          // 34.2).
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Rating/review-count row removed: `rating_avg`/
                // `rating_count` are real columns but no reviews feature
                // exists to ever write a non-zero value to them (the
                // `reviews` module is POSTPONEd) — every doctor shows
                // "0.0 (0)" forever, not a meaningful signal.
                _MetaRow(
                  icon: SolarIconsOutline.mapPointHospital,
                  iconColor: AppPalette.secondary,
                  // `distanceKm` is null when the search ran without the
                  // device's location (denied/unavailable) — show just the
                  // clinic name rather than a fabricated "0.0 km".
                  text: doctor.distanceKm == null
                      ? doctor.locationLabel
                      : '${doctor.locationLabel} (${doctor.distanceKm!.toStringAsFixed(1)} كم)',
                ),
                const SizedBox(height: 8),
                _MetaRow(
                  icon: SolarIconsOutline.walletMoney,
                  iconColor: AppPalette.success,
                  text: 'search.consultation_fee'.tr(args: [feeLabel]),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  height: 48,
                  child: FilledButton(
                    onPressed: () => _guardedTap(widget.onBook),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppPalette.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadii.md),
                      ),
                    ),
                    child: Text(
                      'home.book_now'.tr(),
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({
    required this.icon,
    required this.text,
    this.iconColor = AppPalette.inkMuted,
  });

  final IconData icon;
  final String text;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        AppIconTile(icon: icon, color: iconColor, size: 24, iconSize: 14),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppPalette.ink.withValues(alpha: 0.8),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}


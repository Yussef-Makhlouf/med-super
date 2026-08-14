import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:med_super/core/theme/color_schemes.dart';
import 'package:med_super/features/search_discovery/domain/entities/doctor_summary.dart';

class DoctorResultCard extends StatelessWidget {
  const DoctorResultCard({
    required this.doctor,
    required this.onBook,
    required this.onTap,
    super.key,
  });

  final DoctorSummary doctor;
  final VoidCallback onBook;
  final VoidCallback onTap;

  static const _ink = Color(0xFF1A2B4A);
  static const _muted = Color(0xFF8A94A6);

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final feeLabel = doctor.currency == 'EGP'
        ? '${doctor.consultationFee} ج.م'
        : '${doctor.consultationFee} ${doctor.currency}';

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Avatar(photoUrl: doctor.photoUrl),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                doctor.name,
                                style: textTheme.titleMedium?.copyWith(
                                  color: brandBlue,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            if (doctor.isVerified) ...[
                              const SizedBox(width: 4),
                              const Icon(
                                Icons.verified,
                                size: 18,
                                color: brandBlue,
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          doctor.specialty,
                          style: textTheme.bodyMedium?.copyWith(
                            color: brandBlue.withValues(alpha: 0.85),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(
                              Icons.work_outline,
                              size: 14,
                              color: _muted,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'search.experience_years'.tr(
                                args: ['${doctor.experienceYears}'],
                              ),
                              style: textTheme.bodySmall?.copyWith(
                                color: _muted,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _MetaRow(
                icon: Icons.star,
                iconColor: const Color(0xFFF59E0B),
                text:
                    '${doctor.rating.toStringAsFixed(1)} (${doctor.reviewCount})',
              ),
              const SizedBox(height: 6),
              _MetaRow(
                icon: Icons.place_outlined,
                text:
                    '${doctor.locationLabel} (${doctor.distanceKm.toStringAsFixed(1)} كم)',
              ),
              const SizedBox(height: 6),
              _MetaRow(
                icon: Icons.payments_outlined,
                text: 'search.consultation_fee'.tr(args: [feeLabel]),
              ),
              const SizedBox(height: 14),
              SizedBox(
                height: 48,
                child: FilledButton(
                  onPressed: onBook,
                  style: FilledButton.styleFrom(
                    backgroundColor: brandBlue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'home.book_now'.tr(),
                    style: const TextStyle(fontWeight: FontWeight.w800),
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

class _MetaRow extends StatelessWidget {
  const _MetaRow({
    required this.icon,
    required this.text,
    this.iconColor = DoctorResultCard._muted,
  });

  final IconData icon;
  final String text;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: iconColor),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: DoctorResultCard._ink.withValues(alpha: 0.75),
            ),
          ),
        ),
      ],
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({this.photoUrl});

  final String? photoUrl;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 64,
        height: 64,
        color: const Color(0xFFDCE8FF),
        child: photoUrl != null
            ? Image.network(photoUrl!, fit: BoxFit.cover)
            : const Icon(Icons.person, color: brandBlue, size: 32),
      ),
    );
  }
}

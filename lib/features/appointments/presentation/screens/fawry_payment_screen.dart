import 'dart:async';
// `easy_localization` re-exports `intl`, whose `TextDirection` shadows the
// `dart:ui` enum this file needs for the LTR reference code.
import 'dart:ui' as ui;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:med_super/core/theme/app_colors.dart';
import 'package:med_super/core/theme/app_radii.dart';
import 'package:med_super/core/widgets/app_button.dart';
import 'package:med_super/features/appointments/domain/entities/online_payment_initiation.dart';

/// Terminal screen of the Fawry booking path: the patient pays this
/// reference at any Fawry outlet, and `clinic-reservations` confirms the
/// appointment from the gateway webhook (File 12 Part 50.1) — the app never
/// confirms it, so there is deliberately no "I've paid" button here. The
/// booking only becomes real once it shows up in "My Appointments".
class FawryPaymentScreen extends StatefulWidget {
  const FawryPaymentScreen({required this.initiation, super.key});

  final OnlinePaymentInitiation initiation;

  @override
  State<FawryPaymentScreen> createState() => _FawryPaymentScreenState();
}

class _FawryPaymentScreenState extends State<FawryPaymentScreen> {
  Timer? _ticker;
  Duration _remaining = Duration.zero;

  @override
  void initState() {
    super.initState();
    _tick();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  void _tick() {
    final left = widget.initiation.expiresAt.difference(
      DateTime.now().toUtc(),
    );
    if (!mounted) return;
    setState(() => _remaining = left.isNegative ? Duration.zero : left);
    if (left.isNegative) _ticker?.cancel();
  }

  Future<void> _copyReference() async {
    final code = widget.initiation.referenceCode;
    if (code == null) return;
    await Clipboard.setData(ClipboardData(text: code));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('payments.reference_copied'.tr())),
    );
  }

  @override
  Widget build(BuildContext context) {
    final code = widget.initiation.referenceCode;
    final minutes = _remaining.inMinutes.toString().padLeft(2, '0');
    final seconds = (_remaining.inSeconds % 60).toString().padLeft(2, '0');
    final expired = _remaining == Duration.zero;

    return Scaffold(
      backgroundColor: AppColors.surfaceApp,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 32, 20, 24),
                children: [
                  const Icon(
                    Icons.receipt_long_outlined,
                    size: 64,
                    color: AppColors.patientPrimary,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'payments.fawry_title'.tr(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.ink900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'payments.fawry_subtitle'.tr(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.mutedText2,
                    ),
                  ),
                  const SizedBox(height: 28),
                  if (code != null) _ReferenceCard(code: code, onCopy: _copyReference),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: (expired ? AppColors.errorRed : AppColors.tealAccent)
                          .withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(AppRadii.sm),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.timer_outlined,
                          size: 18,
                          color: expired
                              ? AppColors.errorRed
                              : AppColors.tealAccent,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            expired
                                ? 'payments.fawry_expired'.tr()
                                : 'payments.fawry_countdown'.tr(
                                    args: ['$minutes:$seconds'],
                                  ),
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: expired
                                  ? AppColors.errorRed
                                  : AppColors.tealAccent,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'payments.fawry_pending_note'.tr(),
                    style: const TextStyle(
                      fontSize: 13,
                      height: 1.6,
                      color: AppColors.bodyText,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: AppColors.borderSubtle)),
              ),
              child: SafeArea(
                top: false,
                child: AppButton.filled(
                  label: 'payments.go_to_appointments'.tr(),
                  fullWidth: true,
                  borderRadius: AppRadii.xl,
                  backgroundColor: AppColors.patientPrimary,
                  onPressed: () => context.go('/patient/appointments'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReferenceCard extends StatelessWidget {
  const _ReferenceCard({required this.code, required this.onCopy});

  final String code;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        children: [
          Text(
            'payments.fawry_reference_label'.tr(),
            style: const TextStyle(fontSize: 13, color: AppColors.mutedText2),
          ),
          const SizedBox(height: 10),
          SelectableText(
            code,
            textDirection: ui.TextDirection.ltr,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              letterSpacing: 2,
              color: AppColors.ink900,
            ),
          ),
          const SizedBox(height: 12),
          AppButton.outlined(
            label: 'payments.copy_reference'.tr(),
            icon: const Icon(Icons.copy_rounded, size: 16),
            borderRadius: AppRadii.sm,
            onPressed: onCopy,
          ),
        ],
      ),
    );
  }
}

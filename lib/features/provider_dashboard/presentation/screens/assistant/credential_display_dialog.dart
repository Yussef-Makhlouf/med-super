import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:med_super/core/theme/app_colors.dart';
import 'package:med_super/core/theme/color_schemes.dart';
import 'package:med_super/features/provider_dashboard/domain/entities/provisioned_assistant.dart';

/// One-time credential display shown immediately after creating a new
/// assistant. The Doctor must copy and share these credentials manually —
/// they are never shown again after this dialog is dismissed.
class CredentialDisplayDialog extends StatelessWidget {
  const CredentialDisplayDialog({required this.provisioned, super.key});

  final ProvisionedAssistant provisioned;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header icon + title
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFECFDF5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.check_circle_outline_rounded,
                    color: Color(0xFF059669),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'assistants.created_title'.tr(),
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: AppColors.ink900,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Warning banner
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.warningAmberBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.warningAmberBorder),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.warning_amber_rounded,
                    size: 16,
                    color: AppColors.warningAmberText,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'assistants.password_warning'.tr(),
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.warningAmberText,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Phone credential box
            _CredentialBox(
              label: 'assistants.phone_label'.tr(),
              value: provisioned.phone,
              onCopy: (ctx) => _copy(
                ctx,
                provisioned.phone,
                'assistants.copied_phone'.tr(),
              ),
            ),
            const SizedBox(height: 12),

            // Password credential box
            _CredentialBox(
              label: 'assistants.password_label'.tr(),
              value: provisioned.generatedPassword,
              onCopy: (ctx) => _copy(
                ctx,
                provisioned.generatedPassword,
                'assistants.copied_password'.tr(),
              ),
              obscure: true,
            ),
            const SizedBox(height: 24),

            // Done button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: brandBlue,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  'assistants.done_cta'.tr(),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Copy [text] to clipboard and show a brief SnackBar. Task #37.
  void _copy(BuildContext context, String text, String message) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

// ─── Credential box widget ────────────────────────────────────────────────────

class _CredentialBox extends StatefulWidget {
  const _CredentialBox({
    required this.label,
    required this.value,
    required this.onCopy,
    this.obscure = false,
  });

  final String label;
  final String value;
  final void Function(BuildContext context) onCopy;
  final bool obscure;

  @override
  State<_CredentialBox> createState() => _CredentialBoxState();
}

class _CredentialBoxState extends State<_CredentialBox> {
  bool _revealed = false;

  @override
  Widget build(BuildContext context) {
    final displayValue = (widget.obscure && !_revealed)
        ? '•' * widget.value.length
        : widget.value;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.mutedText2,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.surfaceCard,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.borderLight),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  displayValue,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.ink900,
                    letterSpacing: widget.obscure && !_revealed ? 2 : 0.3,
                    fontFamily: widget.obscure && !_revealed
                        ? null
                        : 'monospace',
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // Reveal toggle for password
              if (widget.obscure)
                GestureDetector(
                  onTap: () => setState(() => _revealed = !_revealed),
                  child: Icon(
                    _revealed
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    size: 18,
                    color: AppColors.mutedText,
                  ),
                ),
              if (widget.obscure) const SizedBox(width: 10),
              // Copy button
              GestureDetector(
                onTap: () => widget.onCopy(context),
                child: const Icon(
                  Icons.copy_rounded,
                  size: 18,
                  color: AppColors.mutedText,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:med_super/core/theme/app_colors.dart';

/// What the doctor confirmed: an optional note shown to the patient.
typedef ProviderCancelDecision = ({String? note});

/// Explicit confirmation before a provider-initiated cancellation.
///
/// Cancelling is irreversible and has real consequences for the patient (a
/// full refund, a released slot, a notification), so it is never a one-tap
/// action. Returns `null` if the doctor backs out.
Future<ProviderCancelDecision?> showProviderCancelDialog(
  BuildContext context, {
  required String patientName,
}) {
  return showDialog<ProviderCancelDecision>(
    context: context,
    builder: (dialogContext) => _ProviderCancelDialog(patientName: patientName),
  );
}

class _ProviderCancelDialog extends StatefulWidget {
  const _ProviderCancelDialog({required this.patientName});

  final String patientName;

  @override
  State<_ProviderCancelDialog> createState() => _ProviderCancelDialogState();
}

class _ProviderCancelDialogState extends State<_ProviderCancelDialog> {
  final _noteController = TextEditingController();

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('provider_dashboard.cancel.title'.tr()),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.patientName,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              color: AppColors.ink900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'provider_dashboard.cancel.message'.tr(),
            style: const TextStyle(color: AppColors.mutedText2, fontSize: 13),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _noteController,
            maxLength: 500,
            maxLines: 2,
            decoration: InputDecoration(
              labelText: 'provider_dashboard.cancel.note_label'.tr(),
              border: const OutlineInputBorder(),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('provider_dashboard.cancel.keep'.tr()),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: AppColors.errorRed),
          onPressed: () {
            final note = _noteController.text.trim();
            Navigator.of(context).pop((note: note.isEmpty ? null : note));
          },
          child: Text('provider_dashboard.cancel.confirm'.tr()),
        ),
      ],
    );
  }
}

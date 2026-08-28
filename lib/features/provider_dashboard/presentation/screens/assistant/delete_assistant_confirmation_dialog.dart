import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:med_super/core/theme/app_colors.dart';
import 'package:med_super/features/provider_dashboard/domain/entities/assistant.dart';
import 'package:med_super/features/provider_dashboard/presentation/controllers/assistant_providers.dart';

/// Confirmation dialog shown before deleting an assistant.
/// Shows the assistant's name, Cancel and red Confirm buttons, and a loading
/// state during the delete call.
class DeleteAssistantConfirmationDialog extends ConsumerStatefulWidget {
  const DeleteAssistantConfirmationDialog({required this.assistant, super.key});

  final Assistant assistant;

  @override
  ConsumerState<DeleteAssistantConfirmationDialog> createState() =>
      _DeleteAssistantConfirmationDialogState();
}

class _DeleteAssistantConfirmationDialogState
    extends ConsumerState<DeleteAssistantConfirmationDialog> {
  bool _loading = false;
  String? _errorMessage;

  Future<void> _confirm() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    final failure = await ref
        .read(assistantsProvider.notifier)
        .delete(widget.assistant.id);

    if (!mounted) return;

    if (failure != null) {
      setState(() {
        _loading = false;
        _errorMessage = 'assistants.delete_failed'.tr();
      });
      return;
    }

    setState(() => _loading = false);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      contentPadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Warning icon
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF2F2),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.person_remove_outlined,
              color: AppColors.errorRed,
              size: 28,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'assistants.delete_title'.tr(),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.ink900,
            ),
          ),
          const SizedBox(height: 8),
          RichText(
            text: TextSpan(
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.mutedText2,
                height: 1.5,
              ),
              children: [
                TextSpan(text: 'assistants.delete_confirm_prefix'.tr()),
                TextSpan(
                  text: widget.assistant.displayName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink900,
                  ),
                ),
                TextSpan(text: 'assistants.delete_confirm_suffix'.tr()),
              ],
            ),
          ),
          // Error message
          if (_errorMessage != null) ...[
            const SizedBox(height: 12),
            Text(
              _errorMessage!,
              style: const TextStyle(fontSize: 13, color: AppColors.errorRed),
            ),
          ],
          const SizedBox(height: 8),
        ],
      ),
      actions: [
        // Cancel
        TextButton(
          onPressed: _loading ? null : () => Navigator.of(context).pop(),
          child: Text(
            'common.cancel'.tr(),
            style: const TextStyle(
              color: AppColors.mutedText2,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        // Confirm (red)
        ElevatedButton(
          onPressed: _loading ? null : _confirm,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.errorRed,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          ),
          child: _loading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text(
                  'common.delete'.tr(),
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
        ),
      ],
    );
  }
}

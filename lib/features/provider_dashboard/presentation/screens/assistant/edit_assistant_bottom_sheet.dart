import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:med_super/core/theme/app_colors.dart';
import 'package:med_super/core/theme/color_schemes.dart';
import 'package:med_super/features/provider_dashboard/domain/entities/assistant.dart';
import 'package:med_super/features/provider_dashboard/domain/entities/assistant_status.dart';
import 'package:med_super/features/provider_dashboard/presentation/controllers/assistant_providers.dart';

/// Bottom sheet for editing an existing assistant's display name and status.
/// Pre-fills fields from [assistant] and saves changes via [AssistantsNotifier].
class EditAssistantBottomSheet extends ConsumerStatefulWidget {
  const EditAssistantBottomSheet({required this.assistant, super.key});

  final Assistant assistant;

  @override
  ConsumerState<EditAssistantBottomSheet> createState() =>
      _EditAssistantBottomSheetState();
}

class _EditAssistantBottomSheetState
    extends ConsumerState<EditAssistantBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late AssistantStatus _selectedStatus;
  bool _loading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.assistant.displayName);
    _selectedStatus = widget.assistant.status;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final newName = _nameController.text.trim();
    final nameChanged = newName != widget.assistant.displayName;
    final statusChanged = _selectedStatus != widget.assistant.status;

    if (!nameChanged && !statusChanged) {
      Navigator.of(context).pop();
      return;
    }

    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    final failure = await ref
        .read(assistantsProvider.notifier)
        .updateAssistant(
          id: widget.assistant.id,
          displayName: nameChanged ? newName : null,
          status: statusChanged ? _selectedStatus : null,
        );

    if (!mounted) return;

    if (failure != null) {
      setState(() {
        _loading = false;
        _errorMessage = 'assistants.update_failed'.tr();
      });
      return;
    }

    setState(() => _loading = false);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(24, 20, 24, 24 + bottomInset),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.borderMedium,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'assistants.edit_title'.tr(),
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppColors.ink900,
              ),
            ),
            const SizedBox(height: 24),

            // Display name field (pre-filled)
            Text(
              'profile.full_name'.tr(),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.ink900,
              ),
            ),
            const SizedBox(height: 6),
            TextFormField(
              controller: _nameController,
              textDirection: TextDirection.rtl,
              decoration: _inputDecoration(hint: 'assistants.name_hint_edit'.tr()),
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return 'assistants.name_required'.tr();
                }
                if (v.trim().length < 2) return 'assistants.name_too_short'.tr();
                return null;
              },
            ),
            const SizedBox(height: 20),

            // Status toggle
            Text(
              'assistants.status_label'.tr(),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.ink900,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _StatusChip(
                  label: 'assistants.status_active'.tr(),
                  selected: _selectedStatus == AssistantStatus.active,
                  selectedColor: const Color(0xFF059669),
                  selectedBg: const Color(0xFFECFDF5),
                  onTap: () =>
                      setState(() => _selectedStatus = AssistantStatus.active),
                ),
                const SizedBox(width: 10),
                _StatusChip(
                  label: 'assistants.status_suspended'.tr(),
                  selected: _selectedStatus == AssistantStatus.suspended,
                  selectedColor: AppColors.errorRed,
                  selectedBg: const Color(0xFFFEF2F2),
                  onTap: () => setState(
                    () => _selectedStatus = AssistantStatus.suspended,
                  ),
                ),
              ],
            ),

            // Error banner
            if (_errorMessage != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.errorRed.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 16,
                      color: AppColors.errorRed,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.errorRed,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 24),

            // Save button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _loading ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: brandBlue,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: _loading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        'profile.save_changes'.tr(),
                        style: const TextStyle(
                          fontSize: 16,
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

  InputDecoration _inputDecoration({required String hint}) => InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(color: AppColors.placeholderText),
    filled: true,
    fillColor: AppColors.surfaceCard,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: AppColors.borderLight),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: AppColors.borderLight),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: brandBlue, width: 1.5),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: AppColors.errorRed),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: AppColors.errorRed, width: 1.5),
    ),
  );
}

// ─── Status chip ─────────────────────────────────────────────────────────────

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.label,
    required this.selected,
    required this.selectedColor,
    required this.selectedBg,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final Color selectedColor;
  final Color selectedBg;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? selectedBg : AppColors.surfaceCard,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: selected ? selectedColor : AppColors.borderLight,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: selected ? selectedColor : AppColors.mutedText,
          ),
        ),
      ),
    );
  }
}

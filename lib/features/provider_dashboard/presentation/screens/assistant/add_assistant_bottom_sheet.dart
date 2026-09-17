import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:med_super/core/theme/app_colors.dart';
import 'package:med_super/core/theme/color_schemes.dart';
import 'package:med_super/features/auth/presentation/controllers/session_provider.dart'
    show isValidEgyptPhone, normalizeEgyptPhone;
import 'package:med_super/features/provider_dashboard/domain/entities/provisioned_assistant.dart';
import 'package:med_super/features/provider_dashboard/presentation/controllers/assistant_providers.dart';
import 'package:med_super/features/provider_dashboard/presentation/controllers/provider_dashboard_providers.dart';
import 'package:med_super/features/provider_dashboard/presentation/widgets/branch_multi_select.dart';

/// Bottom sheet for adding a new clinic assistant.
/// Returns [ProvisionedAssistant] (with generated password) on success,
/// or null if the user cancelled.
class AddAssistantBottomSheet extends ConsumerStatefulWidget {
  const AddAssistantBottomSheet({super.key});

  @override
  ConsumerState<AddAssistantBottomSheet> createState() =>
      _AddAssistantBottomSheetState();
}

class _AddAssistantBottomSheetState
    extends ConsumerState<AddAssistantBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _nameController = TextEditingController();
  final _titleController = TextEditingController();
  final _subtitleController = TextEditingController();
  final Set<String> _selectedBranchIds = {};
  bool _loading = false;
  String? _errorMessage;
  String? _branchesErrorMessage;

  @override
  void dispose() {
    _phoneController.dispose();
    _nameController.dispose();
    _titleController.dispose();
    _subtitleController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final formValid = _formKey.currentState?.validate() ?? false;
    final branchesValid = _selectedBranchIds.isNotEmpty;
    setState(() {
      _branchesErrorMessage = branchesValid
          ? null
          : 'assistants.branches_required'.tr();
    });
    if (!formValid || !branchesValid) return;

    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    final phone = normalizeEgyptPhone(_phoneController.text.trim());
    final name = _nameController.text.trim();
    final title = _titleController.text.trim();
    final subtitle = _subtitleController.text.trim();

    final (provisioned, failure) = await ref
        .read(assistantsProvider.notifier)
        .create(
          phone: phone,
          displayName: name,
          title: title.isEmpty ? null : title,
          subtitle: subtitle.isEmpty ? null : subtitle,
          clinicBranchIds: _selectedBranchIds.toList(),
        );

    if (!mounted) return;

    if (failure != null) {
      setState(() {
        _loading = false;
        _errorMessage = 'assistants.create_failed'.tr();
      });
      return;
    }

    setState(() => _loading = false);
    // Return the provisioned assistant to the caller (AssistantListScreen)
    // so it can show the credential dialog.
    if (mounted) Navigator.of(context).pop(provisioned);
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    // Leaves room below the status bar even when the keyboard is open and
    // every field is showing a validation error — a fixed 24px top padding
    // alone isn't enough once this form's content (name, phone, title,
    // subtitle, branch picker) exceeds the sheet's natural height.
    final maxHeight =
        MediaQuery.of(context).size.height -
        MediaQuery.of(context).padding.top -
        24;

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxHeight),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: EdgeInsets.fromLTRB(24, 20, 24, 24 + bottomInset),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
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
                  'assistants.add_new'.tr(),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'assistants.add_sheet_subtitle'.tr(),
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.mutedText2,
                  ),
                ),
                const SizedBox(height: 24),

                // Display name field
                _FieldLabel(text: 'profile.full_name'.tr()),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _nameController,
                  textDirection: TextDirection.rtl,
                  decoration: _inputDecoration(
                    hint: 'assistants.name_hint'.tr(),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'assistants.name_required'.tr();
                    }
                    if (v.trim().length < 2)
                      return 'assistants.name_too_short'.tr();
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Phone field — tasks #34 + #35
                _FieldLabel(text: 'assistants.phone_label'.tr()),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  textDirection: TextDirection.ltr,
                  decoration: _inputDecoration(hint: '01XXXXXXXXX'),
                  maxLength: 11,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'assistants.phone_required'.tr();
                    }
                    if (!isValidEgyptPhone(v.trim())) {
                      return 'assistants.phone_invalid'.tr();
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Title field
                _FieldLabel(text: 'assistants.title_label'.tr()),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _titleController,
                  textDirection: TextDirection.rtl,
                  decoration: _inputDecoration(
                    hint: 'assistants.title_hint'.tr(),
                  ),
                  maxLength: 200,
                ),
                const SizedBox(height: 16),

                // Subtitle field
                _FieldLabel(text: 'assistants.subtitle_label'.tr()),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _subtitleController,
                  textDirection: TextDirection.rtl,
                  decoration: _inputDecoration(
                    hint: 'assistants.subtitle_hint'.tr(),
                  ),
                  maxLength: 200,
                ),
                const SizedBox(height: 16),

                // Branch multi-select
                _FieldLabel(text: 'assistants.branches_label'.tr()),
                const SizedBox(height: 6),
                Consumer(
                  builder: (context, ref, _) {
                    final clinicsAsync = ref.watch(myClinicsProvider);
                    return clinicsAsync.when(
                      data: (clinics) => BranchMultiSelect(
                        branches: clinics,
                        selectedBranchIds: _selectedBranchIds,
                        onChanged: (next) => setState(() {
                          _selectedBranchIds
                            ..clear()
                            ..addAll(next);
                          _branchesErrorMessage = null;
                        }),
                      ),
                      loading: () => const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Center(
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                      ),
                      error: (_, _) => Text(
                        'assistants.branches_load_failed'.tr(),
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.errorRed,
                        ),
                      ),
                    );
                  },
                ),
                if (_branchesErrorMessage != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    _branchesErrorMessage!,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.errorRed,
                    ),
                  ),
                ],

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

                // Submit button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _submit,
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
                            'assistants.create_cta'.tr(),
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
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({required String hint}) => InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(color: AppColors.placeholderText),
    filled: true,
    fillColor: AppColors.surfaceCard,
    counterText: '',
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

class _FieldLabel extends StatelessWidget {
  const _FieldLabel({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      color: AppColors.ink900,
    ),
  );
}

import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/foundation.dart' show setEquals;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:med_super/core/theme/app_colors.dart';
import 'package:med_super/core/theme/app_radii.dart';
import 'package:med_super/core/theme/color_schemes.dart';
import 'package:med_super/core/widgets/app_text_field.dart';
import 'package:med_super/core/widgets/section_header.dart';
import 'package:med_super/features/provider_dashboard/domain/entities/assistant.dart';
import 'package:med_super/features/provider_dashboard/domain/entities/assistant_status.dart';
import 'package:med_super/features/provider_dashboard/presentation/controllers/assistant_providers.dart';
import 'package:med_super/features/provider_dashboard/presentation/controllers/provider_dashboard_providers.dart';
import 'package:med_super/features/provider_dashboard/presentation/widgets/branch_multi_select.dart';
import 'package:solar_icons/solar_icons.dart';

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
  late final TextEditingController _passwordController;
  late final TextEditingController _titleController;
  late final TextEditingController _subtitleController;
  late AssistantStatus _selectedStatus;
  late Set<String> _selectedBranchIds;
  bool _loading = false;
  bool _obscurePassword = true;
  String? _errorMessage;
  String? _branchesErrorMessage;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.assistant.displayName);
    _passwordController = TextEditingController();
    _titleController = TextEditingController(
      text: widget.assistant.title ?? '',
    );
    _subtitleController = TextEditingController(
      text: widget.assistant.subtitle ?? '',
    );
    _selectedStatus = widget.assistant.status;
    _selectedBranchIds = Set.of(widget.assistant.clinicBranchIds);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _passwordController.dispose();
    _titleController.dispose();
    _subtitleController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_selectedBranchIds.isEmpty) {
      setState(
        () => _branchesErrorMessage = 'assistants.branches_required'.tr(),
      );
      return;
    }

    final newName = _nameController.text.trim();
    final nameChanged = newName != widget.assistant.displayName;
    final statusChanged = _selectedStatus != widget.assistant.status;
    final newPassword = _passwordController.text.trim();
    final passwordChanged = newPassword.isNotEmpty;
    final newTitle = _titleController.text.trim();
    final titleChanged = newTitle != (widget.assistant.title ?? '');
    final newSubtitle = _subtitleController.text.trim();
    final subtitleChanged = newSubtitle != (widget.assistant.subtitle ?? '');
    final branchesChanged = !setEquals(
      _selectedBranchIds,
      Set.of(widget.assistant.clinicBranchIds),
    );

    if (!nameChanged &&
        !statusChanged &&
        !passwordChanged &&
        !titleChanged &&
        !subtitleChanged &&
        !branchesChanged) {
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
          password: passwordChanged ? newPassword : null,
          title: titleChanged ? newTitle : null,
          subtitle: subtitleChanged ? newSubtitle : null,
          clinicBranchIds: branchesChanged ? _selectedBranchIds.toList() : null,
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
    // Leaves room below the status bar even when the keyboard is open and
    // every field is showing a validation error — see AddAssistantBottomSheet
    // for the same fix and rationale.
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
                  'assistants.edit_title'.tr(),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink900,
                  ),
                ),
                const SizedBox(height: 24),

                // Display name field (pre-filled)
                AppTextField(
                  label: 'profile.full_name'.tr(),
                  hint: 'assistants.name_hint_edit'.tr(),
                  controller: _nameController,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'assistants.name_required'.tr();
                    }
                    if (v.trim().length < 2) {
                      return 'assistants.name_too_short'.tr();
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                AppTextField(
                  label: 'assistants.title_label'.tr(),
                  hint: 'assistants.title_hint'.tr(),
                  controller: _titleController,
                  maxLength: 200,
                ),
                const SizedBox(height: 20),

                AppTextField(
                  label: 'assistants.subtitle_label'.tr(),
                  hint: 'assistants.subtitle_hint'.tr(),
                  controller: _subtitleController,
                  maxLength: 200,
                ),
                const SizedBox(height: 20),

                SectionHeader(title: 'assistants.branches_label'.tr()),
                const SizedBox(height: 10),
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
                const SizedBox(height: 20),

                AppTextField(
                  label: 'assistants.password_label'.tr(),
                  hint: 'assistants.password_hint_edit'.tr(),
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  suffix: IconButton(
                    tooltip: 'assistants.password_show'.tr(),
                    icon: Icon(
                      _obscurePassword
                          ? SolarIconsOutline.eye
                          : SolarIconsOutline.eyeClosed,
                    ),
                    onPressed: () => setState(
                      () => _obscurePassword = !_obscurePassword,
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Status toggle
                SectionHeader(title: 'assistants.status_label'.tr()),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _StatusChip(
                      label: 'assistants.status_active'.tr(),
                      selected: _selectedStatus == AssistantStatus.active,
                      selectedColor: const Color(0xFF059669),
                      selectedBg: const Color(0xFFECFDF5),
                      onTap: () => setState(
                        () => _selectedStatus = AssistantStatus.active,
                      ),
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
                      color: AppColors.errorRed.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(AppRadii.md),
                      border: Border.all(
                        color: AppColors.errorRed.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          SolarIconsOutline.dangerCircle,
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
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: brandBlue,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: const StadiumBorder(),
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
        ),
      ),
    );
  }
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
          borderRadius: BorderRadius.circular(AppRadii.pill),
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

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:med_super/core/error/failure.dart';
import 'package:med_super/core/error/failure_message.dart';
import 'package:med_super/core/theme/app_colors.dart';
import 'package:med_super/core/theme/color_schemes.dart';
import 'package:med_super/features/provider_dashboard/domain/entities/assistant.dart';
import 'package:med_super/features/provider_dashboard/domain/entities/provisioned_assistant.dart';
import 'package:med_super/features/provider_dashboard/presentation/controllers/assistant_providers.dart';
import 'package:med_super/features/provider_dashboard/presentation/screens/assistant/add_assistant_bottom_sheet.dart';
import 'package:med_super/features/provider_dashboard/presentation/screens/assistant/credential_display_dialog.dart';
import 'package:med_super/features/provider_dashboard/presentation/screens/assistant/delete_assistant_confirmation_dialog.dart';
import 'package:med_super/features/provider_dashboard/presentation/screens/assistant/edit_assistant_bottom_sheet.dart';
import 'package:med_super/features/provider_dashboard/presentation/widgets/assistant_card.dart';

/// Doctor-only screen — lists all clinic assistants and exposes add/edit/delete.
class AssistantListScreen extends ConsumerWidget {
  const AssistantListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final assistantsAsync = ref.watch(assistantsProvider);

    return Scaffold(
      backgroundColor: AppColors.surfaceApp,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          color: AppColors.ink900,
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'assistants.title'.tr(),
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.ink900,
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddSheet(context, ref),
        backgroundColor: brandBlue,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.person_add_outlined),
        label: Text('assistants.add_fab'.tr()),
      ),
      body: assistantsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _ErrorState(
          message: error is Failure
              ? _failureMessage(error)
              : 'errors.unexpected'.tr(),
          onRetry: () => ref.invalidate(assistantsProvider),
        ),
        data: (assistants) => assistants.isEmpty
            ? _AssistantEmptyState(onAdd: () => _showAddSheet(context, ref))
            : ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                itemCount: assistants.length,
                separatorBuilder: (_, i) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final assistant = assistants[index];
                  return AssistantCard(
                    assistant: assistant,
                    onEdit: () => _showEditSheet(context, ref, assistant),
                    onDelete: () => _showDeleteDialog(context, ref, assistant),
                  );
                },
              ),
      ),
    );
  }

  Future<void> _showAddSheet(BuildContext context, WidgetRef ref) async {
    final provisioned = await showModalBottomSheet<ProvisionedAssistant>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const AddAssistantBottomSheet(),
    );
    if (provisioned != null && context.mounted) {
      // Add to list without re-fetch
      ref
          .read(assistantsProvider.notifier)
          .addToList(provisioned.toAssistant());
      // Show credentials dialog
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (_) => CredentialDisplayDialog(provisioned: provisioned),
      );
    }
  }

  Future<void> _showEditSheet(
    BuildContext context,
    WidgetRef ref,
    Assistant assistant,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => EditAssistantBottomSheet(assistant: assistant),
    );
  }

  Future<void> _showDeleteDialog(
    BuildContext context,
    WidgetRef ref,
    Assistant assistant,
  ) async {
    await showDialog<void>(
      context: context,
      builder: (_) => DeleteAssistantConfirmationDialog(assistant: assistant),
    );
  }

  /// Delegates to the app-wide Arabic mapper — see
  /// `core/error/failure_message.dart`.
  String _failureMessage(Failure failure) =>
      failureMessage(failure, screenFallback: 'provider_dashboard.errors.generic');
}

class _AssistantEmptyState extends StatelessWidget {
  const _AssistantEmptyState({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: brandBlue.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.badge_outlined,
                size: 48,
                color: brandBlue.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'assistants.empty_title'.tr(),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.ink900,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'assistants.empty_subtitle'.tr(),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.mutedText2,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: onAdd,
              style: ElevatedButton.styleFrom(
                backgroundColor: brandBlue,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              icon: const Icon(Icons.person_add_outlined),
              label: Text(
                'assistants.add_new'.tr(),
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Error state ─────────────────────────────────────────────────────────────

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 56,
              color: AppColors.mutedText,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 15, color: AppColors.mutedText2),
            ),
            const SizedBox(height: 24),
            OutlinedButton(
              onPressed: onRetry,
              child: Text('common.retry'.tr()),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Empty state ─────────────────────────────────────────────────────────────

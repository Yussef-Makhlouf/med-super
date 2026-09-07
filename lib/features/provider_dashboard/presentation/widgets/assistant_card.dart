import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:med_super/core/theme/app_colors.dart';
import 'package:med_super/core/theme/color_schemes.dart';
import 'package:med_super/features/provider_dashboard/domain/entities/assistant.dart';
import 'package:med_super/features/provider_dashboard/domain/entities/assistant_status.dart';

/// A card displaying one clinic assistant with edit and delete action buttons.
class AssistantCard extends StatelessWidget {
  const AssistantCard({
    required this.assistant,
    required this.onEdit,
    required this.onDelete,
    super.key,
  });

  final Assistant assistant;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final initials = _initials(assistant.displayName);

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFF1F5F9)),
        ),
        child: Row(
          children: [
            // Avatar with initials
            CircleAvatar(
              radius: 24,
              backgroundColor: brandBlue.withValues(alpha: 0.12),
              child: Text(
                initials,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: brandBlue,
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Name, phone, status
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          assistant.displayName,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.ink900,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      _StatusBadge(status: assistant.status),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    assistant.phone,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.mutedText2,
                      letterSpacing: 0.3,
                    ),
                  ),
                  if (assistant.title != null && assistant.title!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      assistant.title!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.mutedText2,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 4),
            // Edit button
            IconButton(
              onPressed: onEdit,
              icon: const Icon(Icons.edit_outlined, size: 20),
              color: AppColors.mutedText,
              tooltip: 'common.edit'.tr(),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            ),
            // Delete button
            IconButton(
              onPressed: onDelete,
              icon: const Icon(Icons.delete_outline, size: 20),
              color: AppColors.errorRed,
              tooltip: 'common.delete'.tr(),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            ),
          ],
        ),
      ),
    );
  }

  /// Returns up to 2-character initials from the display name.
  static String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '?';
    if (parts.length == 1) {
      return parts.first.characters.take(2).toString().toUpperCase();
    }
    return '${parts.first.characters.first}${parts[1].characters.first}'
        .toUpperCase();
  }
}

// ─── Status badge ─────────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final AssistantStatus status;

  @override
  Widget build(BuildContext context) {
    final isActive = status == AssistantStatus.active;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFFECFDF5) : const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        isActive ? 'assistants.status_active'.tr() : 'assistants.status_suspended'.tr(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: isActive ? const Color(0xFF059669) : AppColors.errorRed,
        ),
      ),
    );
  }
}

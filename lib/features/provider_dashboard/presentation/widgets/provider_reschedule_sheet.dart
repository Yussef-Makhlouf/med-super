import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:med_super/core/theme/app_colors.dart';
import 'package:med_super/core/widgets/empty_state.dart';
import 'package:med_super/core/widgets/error_banner.dart';
import 'package:med_super/features/provider_dashboard/presentation/controllers/doctor_open_slots_provider.dart';
import 'package:med_super/features/provider_dashboard/presentation/controllers/provider_failure_message.dart';
import 'package:med_super/features/provider_dashboard/presentation/widgets/provider_appointment_card.dart';
import 'package:med_super/features/provider_profile/domain/entities/doctor_slot.dart';

/// Picks a replacement slot for a provider-initiated reschedule.
///
/// Reuses the existing `GET /v1/doctors/{doctorId}/slots` client rather than
/// adding a second one — it already returns only `OPEN` slots and is keyed by
/// `(doctorId, clinicBranchId)`, which is exactly the constraint the backend
/// enforces on reschedule: the new slot must belong to the **same
/// affiliation**, so only this branch's slots may be offered.
///
/// Returns the chosen `slotId`, or `null` if the doctor backed out.
Future<String?> showProviderRescheduleSheet(
  BuildContext context, {
  required String doctorId,
  required String clinicBranchId,
  required String clinicName,
}) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => _ProviderRescheduleSheet(
      doctorId: doctorId,
      clinicBranchId: clinicBranchId,
      clinicName: clinicName,
    ),
  );
}

class _ProviderRescheduleSheet extends ConsumerWidget {
  const _ProviderRescheduleSheet({
    required this.doctorId,
    required this.clinicBranchId,
    required this.clinicName,
  });

  final String doctorId;
  final String clinicBranchId;
  final String clinicName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(
      doctorOpenSlotsProvider((
        doctorId: doctorId,
        clinicBranchId: clinicBranchId,
        from: null,
        to: null,
      )),
    );

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      maxChildSize: 0.92,
      builder: (context, scrollController) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'provider_dashboard.reschedule.title'.tr(),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: AppColors.ink900,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'provider_dashboard.reschedule.same_branch_note'.tr(),
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.mutedText2,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              clinicName,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.ink900,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: async.when(
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (error, _) => ErrorBanner(
                  message: providerFailureMessageOf(error),
                  onRetry: () => ref.invalidate(
                    doctorOpenSlotsProvider((
                      doctorId: doctorId,
                      clinicBranchId: clinicBranchId,
                      from: null,
                      to: null,
                    )),
                  ),
                ),
                data: (slots) => slots.isEmpty
                    ? EmptyState(
                        title: 'provider_dashboard.reschedule.no_slots'.tr(),
                        icon: Icons.event_busy_outlined,
                      )
                    : ListView.separated(
                        controller: scrollController,
                        itemCount: slots.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
                        itemBuilder: (context, index) =>
                            _slotTile(context, slots[index]),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _slotTile(BuildContext context, DoctorSlot slot) {
    final local = slot.startAtUtc.toLocal();
    final dateLabel =
        '${'provider_dashboard.weekday.${local.weekday}'.tr()} ${local.day}/${local.month}';

    return ListTile(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      leading: const Icon(Icons.schedule, color: AppColors.mutedText2),
      title: Text(
        formatAppointmentTime(slot.startAtUtc),
        style: const TextStyle(fontWeight: FontWeight.w800),
      ),
      subtitle: Text(dateLabel),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => Navigator.of(context).pop(slot.slotId),
    );
  }
}

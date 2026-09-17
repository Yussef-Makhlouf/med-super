import 'dart:ui' as ui;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:med_super/core/theme/app_colors.dart';
import 'package:med_super/core/theme/color_schemes.dart';
import 'package:med_super/core/widgets/empty_state.dart';
import 'package:med_super/core/widgets/error_banner.dart';
import 'package:med_super/core/widgets/skeleton_loader.dart';
import 'package:med_super/features/auth/presentation/controllers/session_provider.dart';
import 'package:med_super/features/provider_dashboard/domain/entities/doctor_clinic.dart';
import 'package:med_super/features/provider_dashboard/presentation/controllers/doctor_open_slots_provider.dart';
import 'package:med_super/features/provider_dashboard/presentation/controllers/provider_dashboard_providers.dart';
import 'package:med_super/features/provider_dashboard/presentation/controllers/provider_failure_message.dart';
import 'package:med_super/features/provider_dashboard/presentation/widgets/provider_appointment_card.dart';
import 'package:med_super/features/provider_profile/domain/entities/doctor_slot.dart';

/// Real walk-in booking, `POST
/// /v1/doctors/me/appointments/branch/{clinicBranchId}/create`
/// (`BookWalkInAppointmentUseCase`). Callable by DOCTOR or CLINIC_STAFF.
///
/// Three steps in one sheet: branch (only affiliations where
/// `isAcceptingBookings` is true) -> open slot for that branch (reusing
/// `doctorOpenSlotsProvider`, the same client/pattern as
/// `provider_reschedule_sheet.dart`) -> patient identification (phone and
/// name both required on this form — the backend's own DTO allows an
/// optional name, but the doctor/staff typing at the desk must always give
/// one so a brand-new account is never created nameless).
///
/// Returns `true` when a booking was made (so the caller knows to refresh),
/// `null`/`false` otherwise.
Future<bool?> showBookWalkInAppointmentSheet(
  BuildContext context, {
  required String doctorId,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: _BookWalkInAppointmentSheet(doctorId: doctorId),
    ),
  );
}

class _BookWalkInAppointmentSheet extends ConsumerStatefulWidget {
  const _BookWalkInAppointmentSheet({required this.doctorId});

  final String doctorId;

  @override
  ConsumerState<_BookWalkInAppointmentSheet> createState() =>
      _BookWalkInAppointmentSheetState();
}

class _BookWalkInAppointmentSheetState
    extends ConsumerState<_BookWalkInAppointmentSheet> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _nameController = TextEditingController();

  DoctorClinic? _branch;
  DateTime? _selectedDay;
  DoctorSlot? _slot;
  bool _submitting = false;
  String? _submitError;

  @override
  void dispose() {
    _phoneController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final branch = _branch;
    final slot = _slot;
    if (branch == null || slot == null) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _submitting = true;
      _submitError = null;
    });

    final phone = normalizeEgyptPhone(_phoneController.text.trim());
    final name = _nameController.text.trim();

    final result = await ref
        .read(bookWalkInAppointmentUseCaseProvider)
        .call(
          clinicBranchId: branch.clinicBranchId,
          slotId: slot.slotId,
          patientPhone: phone,
          patientName: name,
        );

    if (!mounted) return;

    result.when(
      ok: (_) {
        ref.invalidate(doctorAppointmentsProvider);
        Navigator.of(context).pop(true);
      },
      err: (failure) {
        // Someone else (or a stray double-submit) claimed this slot between
        // when the list loaded and when this request landed — the slot
        // picked from the now-stale list no longer exists as OPEN. Refresh
        // the open-slots list and clear the dead selection so the user
        // picks a genuinely still-open one instead of retrying the same
        // 409 forever.
        ref.invalidate(
          doctorOpenSlotsProvider((
            doctorId: widget.doctorId,
            clinicBranchId: branch.clinicBranchId,
            from: null,
            to: null,
          )),
        );
        setState(() {
          _submitting = false;
          _submitError = providerFailureMessage(failure);
          _slot = null;
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final clinicsAsync = ref.watch(myClinicsProvider);

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      builder: (context, scrollController) => SingleChildScrollView(
        controller: scrollController,
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'provider_dashboard.walk_in.title'.tr(),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: AppColors.ink900,
                ),
              ),
              const SizedBox(height: 20),
              _sectionLabel('provider_dashboard.walk_in.step_branch'.tr()),
              const SizedBox(height: 8),
              clinicsAsync.when(
                loading: () => _chipRowSkeleton(),
                error: (error, _) => ErrorBanner(
                  message: providerFailureMessageOf(error),
                  onRetry: () => ref.invalidate(myClinicsProvider),
                ),
                data: _branchPicker,
              ),
              if (_branch != null) ...[
                const SizedBox(height: 20),
                _sectionLabel('provider_dashboard.walk_in.step_slot'.tr()),
                const SizedBox(height: 8),
                _slotPicker(_branch!),
              ],
              if (_slot != null) ...[
                const SizedBox(height: 20),
                _sectionLabel('provider_dashboard.walk_in.step_patient'.tr()),
                const SizedBox(height: 8),
                _patientFields(),
              ],
              if (_submitError != null) ...[
                const SizedBox(height: 12),
                ErrorBanner(message: _submitError!),
              ],
              const SizedBox(height: 20),
              SizedBox(
                height: 48,
                width: double.infinity,
                child: FilledButton(
                  onPressed: (_branch != null && _slot != null && !_submitting)
                      ? _submit
                      : null,
                  child: _submitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text('provider_dashboard.walk_in.submit'.tr()),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) => Text(
    text,
    style: const TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w800,
      color: AppColors.ink900,
    ),
  );

  Widget _chipRowSkeleton() => SizedBox(
    height: 72,
    child: ListView.separated(
      scrollDirection: Axis.horizontal,
      itemCount: 3,
      separatorBuilder: (_, _) => const SizedBox(width: 8),
      itemBuilder: (_, _) =>
          const SkeletonLoader(width: 130, height: 72, borderRadius: 12),
    ),
  );

  Widget _slotPickerSkeleton() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      SizedBox(
        height: 64,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: 4,
          separatorBuilder: (_, _) => const SizedBox(width: 8),
          itemBuilder: (_, _) =>
              const SkeletonLoader(width: 62, height: 64, borderRadius: 14),
        ),
      ),
      const SizedBox(height: 12),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: const [
          SkeletonLoader(width: 70, height: 38, borderRadius: 10),
          SkeletonLoader(width: 70, height: 38, borderRadius: 10),
          SkeletonLoader(width: 70, height: 38, borderRadius: 10),
          SkeletonLoader(width: 70, height: 38, borderRadius: 10),
        ],
      ),
    ],
  );

  Widget _branchPicker(List<DoctorClinic> clinics) {
    final acceptingBranches = clinics
        .where((clinic) => clinic.isAcceptingBookings)
        .toList();

    if (acceptingBranches.isEmpty) {
      return EmptyState(
        title: 'provider_dashboard.walk_in.no_branches_title'.tr(),
        subtitle: 'provider_dashboard.walk_in.no_branches_subtitle'.tr(),
        icon: Icons.store_mall_directory_outlined,
      );
    }

    // Auto-select the first branch as soon as the list loads, so the sheet
    // never sits with an empty first step waiting for a tap — the user can
    // still change it, same as the day/slot pickers below auto-select their
    // own first option.
    if (_branch == null ||
        !acceptingBranches.any((c) => c.clinicBranchId == _branch!.clinicBranchId)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _branch = acceptingBranches.first;
            _selectedDay = null;
            _slot = null;
          });
        }
      });
    }

    return SizedBox(
      height: 72,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: acceptingBranches.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) => _branchChip(acceptingBranches[index]),
      ),
    );
  }

  Widget _branchChip(DoctorClinic clinic) {
    final selected = _branch?.clinicBranchId == clinic.clinicBranchId;
    return GestureDetector(
      onTap: () => setState(() {
        _branch = clinic;
        _selectedDay = null;
        _slot = null;
      }),
      child: Container(
        width: 130,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? brandBlue.withValues(alpha: 0.08) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? brandBlue : const Color(0xFFE2E8F0),
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.store_mall_directory_outlined,
                  size: 14,
                  color: selected ? brandBlue : AppColors.mutedText2,
                ),
                const Spacer(),
                if (selected) const Icon(Icons.check_circle, color: brandBlue, size: 16),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              clinic.address.city,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
            ),
            Text(
              clinic.displayAddressLine,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 10, color: AppColors.mutedText2),
            ),
          ],
        ),
      ),
    );
  }

  Widget _slotPicker(DoctorClinic branch) {
    final async = ref.watch(
      doctorOpenSlotsProvider((
        doctorId: widget.doctorId,
        clinicBranchId: branch.clinicBranchId,
        from: null,
        to: null,
      )),
    );

    return async.when(
      loading: _slotPickerSkeleton,
      error: (error, _) => ErrorBanner(
        message: providerFailureMessageOf(error),
        onRetry: () => ref.invalidate(
          doctorOpenSlotsProvider((
            doctorId: widget.doctorId,
            clinicBranchId: branch.clinicBranchId,
            from: null,
            to: null,
          )),
        ),
      ),
      data: (slots) {
        if (slots.isEmpty) {
          return EmptyState(
            title: 'provider_dashboard.walk_in.no_slots'.tr(),
            icon: Icons.event_busy_outlined,
          );
        }

        final byDay = <DateTime, List<DoctorSlot>>{};
        for (final slot in slots) {
          final local = slot.startAtUtc.toLocal();
          final day = DateTime(local.year, local.month, local.day);
          (byDay[day] ??= []).add(slot);
        }
        final days = byDay.keys.toList()..sort();

        final selectedDay = (_selectedDay != null && byDay.containsKey(_selectedDay))
            ? _selectedDay!
            : days.first;
        if (_selectedDay != selectedDay) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) setState(() => _selectedDay = selectedDay);
          });
        }

        final daySlots = (byDay[selectedDay] ?? const <DoctorSlot>[])
          ..sort((a, b) => a.startAtUtc.compareTo(b.startAtUtc));

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 64,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: days.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, index) => _dayChip(days[index], days[index] == selectedDay),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [for (final slot in daySlots) _slotChip(slot)],
            ),
          ],
        );
      },
    );
  }

  Widget _dayChip(DateTime day, bool selected) {
    return GestureDetector(
      onTap: () => setState(() {
        _selectedDay = day;
        _slot = null;
      }),
      child: Container(
        width: 62,
        decoration: BoxDecoration(
          color: selected ? brandBlue : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: selected ? brandBlue : const Color(0xFFE2E8F0)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'provider_dashboard.weekday.${day.weekday}'.tr(),
              style: TextStyle(
                fontSize: 11,
                color: selected ? Colors.white.withValues(alpha: 0.9) : AppColors.mutedText2,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${day.day}/${day.month}',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: selected ? Colors.white : AppColors.ink900,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _slotChip(DoctorSlot slot) {
    final selected = _slot?.slotId == slot.slotId;
    return GestureDetector(
      onTap: () => setState(() => _slot = slot),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? brandBlue.withValues(alpha: 0.08) : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? brandBlue : const Color(0xFFE2E8F0),
            width: selected ? 2 : 1,
          ),
        ),
        child: Text(
          formatAppointmentTime(slot.startAtUtc),
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 12,
            color: selected ? brandBlue : AppColors.ink900,
          ),
        ),
      ),
    );
  }

  Widget _patientFields() {
    return Column(
      children: [
        TextFormField(
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          textDirection: ui.TextDirection.ltr,
          textAlign: TextAlign.left,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(11),
          ],
          decoration: InputDecoration(
            labelText: 'provider_dashboard.walk_in.phone_label'.tr(),
            hintText: 'provider_dashboard.walk_in.phone_hint'.tr(),
            border: const OutlineInputBorder(),
            isDense: true,
          ),
          validator: (value) {
            final trimmed = (value ?? '').trim();
            if (trimmed.isEmpty) {
              return 'provider_dashboard.walk_in.phone_required'.tr();
            }
            if (!isValidEgyptPhone(trimmed)) {
              return 'provider_dashboard.walk_in.phone_invalid'.tr();
            }
            return null;
          },
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _nameController,
          decoration: InputDecoration(
            labelText: 'provider_dashboard.walk_in.name_label'.tr(),
            hintText: 'provider_dashboard.walk_in.name_hint'.tr(),
            border: const OutlineInputBorder(),
            isDense: true,
          ),
          validator: (value) {
            if ((value ?? '').trim().isEmpty) {
              return 'provider_dashboard.walk_in.name_required'.tr();
            }
            return null;
          },
        ),
      ],
    );
  }
}

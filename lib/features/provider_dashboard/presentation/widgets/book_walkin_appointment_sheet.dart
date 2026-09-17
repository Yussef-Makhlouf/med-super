import 'dart:ui' as ui;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:med_super/core/theme/app_colors.dart';
import 'package:med_super/core/theme/app_radii.dart';
import 'package:med_super/core/theme/app_shadows.dart';
import 'package:med_super/core/theme/color_schemes.dart';
import 'package:med_super/core/widgets/app_icon_tile.dart';
import 'package:med_super/core/widgets/empty_state.dart';
import 'package:med_super/core/widgets/error_banner.dart';
import 'package:med_super/core/widgets/section_header.dart';
import 'package:med_super/core/widgets/skeleton_loader.dart';
import 'package:med_super/features/auth/presentation/controllers/session_provider.dart';
import 'package:med_super/features/provider_dashboard/domain/entities/doctor_clinic.dart';
import 'package:med_super/features/provider_dashboard/presentation/controllers/doctor_open_slots_provider.dart';
import 'package:med_super/features/provider_dashboard/presentation/controllers/provider_dashboard_providers.dart';
import 'package:med_super/features/provider_dashboard/presentation/controllers/provider_failure_message.dart';
import 'package:med_super/features/provider_dashboard/presentation/widgets/provider_appointment_card.dart';
import 'package:med_super/features/provider_profile/domain/entities/doctor_slot.dart';
import 'package:solar_icons/solar_icons.dart';

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
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.xl)),
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
      initialChildSize: 0.88,
      maxChildSize: 0.95,
      builder: (context, scrollController) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _dragHandle(),
          _titleBar(),
          Expanded(
            child: SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SectionHeader(
                      title: 'provider_dashboard.walk_in.step_branch'.tr(),
                    ),
                    const SizedBox(height: 12),
                    clinicsAsync.when(
                      loading: () => _chipRowSkeleton(),
                      error: (error, _) => ErrorBanner(
                        message: providerFailureMessageOf(error),
                        onRetry: () => ref.invalidate(myClinicsProvider),
                      ),
                      data: _branchPicker,
                    ),
                    if (_branch != null) ...[
                      const SizedBox(height: 24),
                      SectionHeader(
                        title: 'provider_dashboard.walk_in.step_slot'.tr(),
                      ),
                      const SizedBox(height: 12),
                      _slotPicker(_branch!),
                    ],
                    if (_slot != null) ...[
                      const SizedBox(height: 24),
                      SectionHeader(
                        title: 'provider_dashboard.walk_in.step_patient'.tr(),
                      ),
                      const SizedBox(height: 12),
                      _patientFields(),
                    ],
                    if (_submitError != null) ...[
                      const SizedBox(height: 12),
                      ErrorBanner(message: _submitError!),
                    ],
                  ],
                ),
              ),
            ),
          ),
          _submitBar(),
        ],
      ),
    );
  }

  Widget _dragHandle() => Padding(
    padding: const EdgeInsets.only(top: 10, bottom: 4),
    child: Container(
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: AppColors.borderMedium,
        borderRadius: BorderRadius.circular(AppRadii.pill),
      ),
    ),
  );

  Widget _titleBar() => Padding(
    padding: const EdgeInsets.fromLTRB(20, 8, 12, 12),
    child: Row(
      children: [
        Expanded(
          child: Text(
            'provider_dashboard.walk_in.title'.tr(),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.ink900,
            ),
          ),
        ),
        IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.close, color: AppColors.mutedText2),
          style: IconButton.styleFrom(
            backgroundColor: AppColors.surfaceMuted,
            shape: const CircleBorder(),
          ),
        ),
      ],
    ),
  );

  Widget _submitBar() => Container(
    padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
    decoration: const BoxDecoration(
      color: Colors.white,
      boxShadow: AppShadows.raised,
    ),
    child: SafeArea(
      top: false,
      child: SizedBox(
        height: 56,
        width: double.infinity,
        child: FilledButton(
          style: FilledButton.styleFrom(
            shape: const StadiumBorder(),
            backgroundColor: brandBlue,
          ),
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
              : Text(
                  'provider_dashboard.walk_in.submit'.tr(),
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                ),
        ),
      ),
    ),
  );

  Widget _chipRowSkeleton() => SizedBox(
    height: 132,
    child: ListView.separated(
      scrollDirection: Axis.horizontal,
      itemCount: 3,
      separatorBuilder: (_, _) => const SizedBox(width: 10),
      itemBuilder: (_, _) =>
          const SkeletonLoader(width: 168, height: 132, borderRadius: AppRadii.lg),
    ),
  );

  Widget _slotPickerSkeleton() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      SizedBox(
        height: 68,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: 4,
          separatorBuilder: (_, _) => const SizedBox(width: 8),
          itemBuilder: (_, _) =>
              const SkeletonLoader(width: 68, height: 68, borderRadius: AppRadii.md),
        ),
      ),
      const SizedBox(height: 12),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: const [
          SkeletonLoader(width: 76, height: 40, borderRadius: AppRadii.pill),
          SkeletonLoader(width: 76, height: 40, borderRadius: AppRadii.pill),
          SkeletonLoader(width: 76, height: 40, borderRadius: AppRadii.pill),
          SkeletonLoader(width: 76, height: 40, borderRadius: AppRadii.pill),
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
        icon: SolarIconsOutline.buildings,
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
      height: 132,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: acceptingBranches.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
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
        width: 168,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected ? brandBlue.withValues(alpha: 0.06) : Colors.white,
          borderRadius: BorderRadius.circular(AppRadii.lg),
          border: Border.all(
            color: selected ? brandBlue : AppColors.borderLight,
            width: selected ? 2 : 1,
          ),
          boxShadow: AppShadows.resting,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                AppIconTile(
                  icon: SolarIconsOutline.buildings,
                  color: selected ? brandBlue : AppColors.mutedText2,
                  size: 40,
                  iconSize: 20,
                ),
                const Spacer(),
                if (selected)
                  const Icon(
                    SolarIconsBold.checkCircle,
                    color: brandBlue,
                    size: 20,
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              clinic.address.city,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
            ),
            const SizedBox(height: 2),
            Text(
              clinic.displayAddressLine,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 11, color: AppColors.mutedText2),
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
            icon: SolarIconsOutline.calendarMinimalistic,
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
              height: 68,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: days.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, index) => _dayChip(days[index], days[index] == selectedDay),
              ),
            ),
            const SizedBox(height: 14),
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
        width: 68,
        decoration: BoxDecoration(
          color: selected ? brandBlue : Colors.white,
          borderRadius: BorderRadius.circular(AppRadii.md),
          border: Border.all(color: selected ? brandBlue : AppColors.borderLight),
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
                fontSize: 15,
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
        decoration: BoxDecoration(
          color: selected ? brandBlue : Colors.white,
          borderRadius: BorderRadius.circular(AppRadii.pill),
          border: Border.all(
            color: selected ? brandBlue : AppColors.borderLight,
            width: selected ? 2 : 1,
          ),
        ),
        child: Text(
          formatAppointmentTime(slot.startAtUtc),
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 13,
            color: selected ? Colors.white : AppColors.ink900,
          ),
        ),
      ),
    );
  }

  Widget _patientFields() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceApp,
        borderRadius: BorderRadius.circular(AppRadii.lg),
      ),
      child: Column(
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
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadii.md),
                borderSide: const BorderSide(color: AppColors.borderLight),
              ),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
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
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadii.md),
                borderSide: const BorderSide(color: AppColors.borderLight),
              ),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            ),
            validator: (value) {
              if ((value ?? '').trim().isEmpty) {
                return 'provider_dashboard.walk_in.name_required'.tr();
              }
              return null;
            },
          ),
        ],
      ),
    );
  }
}

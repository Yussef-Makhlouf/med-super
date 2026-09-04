import 'dart:ui' as ui;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:med_super/core/theme/app_colors.dart';
import 'package:med_super/core/theme/color_schemes.dart';
import 'package:med_super/core/widgets/empty_state.dart';
import 'package:med_super/core/widgets/error_banner.dart';
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

    final phone = _phoneController.text.trim();
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
      err: (failure) => setState(() {
        _submitting = false;
        _submitError = providerFailureMessage(failure);
      }),
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
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
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

    return Column(
      children: [
        for (final clinic in acceptingBranches) ...[
          _branchTile(clinic),
          const SizedBox(height: 8),
        ],
      ],
    );
  }

  Widget _branchTile(DoctorClinic clinic) {
    final selected = _branch?.clinicBranchId == clinic.clinicBranchId;
    return ListTile(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: selected ? brandBlue : const Color(0xFFE2E8F0),
          width: selected ? 2 : 1,
        ),
      ),
      tileColor: selected ? brandBlue.withValues(alpha: 0.06) : null,
      leading: Icon(
        Icons.store_mall_directory_outlined,
        color: selected ? brandBlue : AppColors.mutedText2,
      ),
      title: Text(
        clinic.displayTitle,
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
      trailing: selected ? const Icon(Icons.check_circle, color: brandBlue) : null,
      onTap: () => setState(() {
        _branch = clinic;
        _slot = null;
      }),
    );
  }

  Widget _slotPicker(DoctorClinic branch) {
    final async = ref.watch(
      doctorOpenSlotsProvider((
        doctorId: widget.doctorId,
        clinicBranchId: branch.clinicBranchId,
      )),
    );

    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => ErrorBanner(
        message: providerFailureMessageOf(error),
        onRetry: () => ref.invalidate(
          doctorOpenSlotsProvider((
            doctorId: widget.doctorId,
            clinicBranchId: branch.clinicBranchId,
          )),
        ),
      ),
      data: (slots) => slots.isEmpty
          ? EmptyState(
              title: 'provider_dashboard.walk_in.no_slots'.tr(),
              icon: Icons.event_busy_outlined,
            )
          : ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: slots.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, index) =>
                  _slotTile(slots[index]),
            ),
    );
  }

  Widget _slotTile(DoctorSlot slot) {
    final selected = _slot?.slotId == slot.slotId;
    final local = slot.startAtUtc.toLocal();
    final dateLabel =
        '${'provider_dashboard.weekday.${local.weekday}'.tr()} ${local.day}/${local.month}';

    return ListTile(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: selected ? brandBlue : const Color(0xFFE2E8F0),
          width: selected ? 2 : 1,
        ),
      ),
      tileColor: selected ? brandBlue.withValues(alpha: 0.06) : null,
      leading: Icon(
        Icons.schedule,
        color: selected ? brandBlue : AppColors.mutedText2,
      ),
      title: Text(
        formatAppointmentTime(slot.startAtUtc),
        style: const TextStyle(fontWeight: FontWeight.w800),
      ),
      subtitle: Text(dateLabel),
      trailing: selected ? const Icon(Icons.check_circle, color: brandBlue) : null,
      onTap: () => setState(() => _slot = slot),
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
            if (!RegExp(r'^\+[1-9]\d{7,14}$').hasMatch(trimmed)) {
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

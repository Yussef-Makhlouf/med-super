import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:med_super/core/error/failure.dart';
import 'package:med_super/core/error/failure_message.dart';
import 'package:med_super/core/theme/app_palette.dart';
import 'package:med_super/core/theme/app_radii.dart';
import 'package:med_super/core/utils/formatters.dart';
import 'package:med_super/core/widgets/app_surface_card.dart';
import 'package:med_super/core/widgets/async_value_view.dart';
import 'package:med_super/core/widgets/error_banner.dart';
import 'package:med_super/features/appointments/domain/entities/booking_request.dart';
import 'package:med_super/features/appointments/domain/entities/reschedule_target.dart';
import 'package:med_super/features/appointments/presentation/controllers/appointment_providers.dart';
import 'package:med_super/features/appointments/presentation/screens/booking_confirm_screen.dart';
import 'package:med_super/features/provider_profile/domain/entities/available_day.dart';
import 'package:med_super/features/provider_profile/domain/entities/doctor_profile.dart';
import 'package:med_super/features/provider_profile/presentation/controllers/doctor_availability_providers.dart';
import 'package:med_super/features/provider_profile/presentation/controllers/doctor_profile_providers.dart';
import 'package:solar_icons/solar_icons.dart';

typedef _SlotSelection = void Function(String id, String label);

/// Reschedule step 1: pick a new slot for an existing confirmed appointment,
/// then call `POST /v1/appointments/{id}/reschedule` (File 12 Part 35.10).
/// That endpoint returns a fresh hold, not a confirmed appointment — so on
/// success this hands off to [BookingConfirmScreen] with that hold already
/// set, reusing its countdown + confirm UI. Reached from
/// `PatientAppointmentsScreen`'s "Reschedule" button.
class RescheduleScreen extends ConsumerStatefulWidget {
  const RescheduleScreen({required this.target, super.key});

  final RescheduleTarget target;

  @override
  ConsumerState<RescheduleScreen> createState() => _RescheduleScreenState();
}

class _RescheduleScreenState extends ConsumerState<RescheduleScreen> {
  String? _selectedDayId;
  String? _selectedDayLabel;
  String? _selectedSlotId;
  String? _selectedTimeLabel;
  bool _submitting = false;
  Failure? _submitError;

  Future<void> _submit(DoctorProfile profile) async {
    final slotId = _selectedSlotId;
    if (slotId == null) return;

    setState(() {
      _submitting = true;
      _submitError = null;
    });

    final result = await ref
        .read(rescheduleAppointmentUseCaseProvider)
        .call(appointmentId: widget.target.appointmentId, newSlotId: slotId);
    if (!mounted) return;

    result.when(
      ok: (hold) {
        ref.read(myAppointmentsRefreshProvider.notifier).state++;
        context.pushReplacement(
          '/patient/home/appointments/confirm',
          extra: BookingConfirmArgs(
            request: BookingRequest(
              doctorClinicAffiliationId:
                  widget.target.doctorClinicAffiliationId,
              slotId: slotId,
              doctorName: profile.name,
              specialty: profile.specialty,
              dayLabel: _selectedDayLabel ?? '',
              timeLabel: _selectedTimeLabel ?? '',
              consultationFee: profile.consultationFee,
              currency: profile.currency,
            ),
            initialHold: hold,
          ),
        );
      },
      err: (failure) => setState(() {
        _submitting = false;
        _submitError = failure;
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final doctorId = widget.target.doctorId;

    final asyncProfile = doctorId.isEmpty
        ? null
        : ref.watch(doctorProfileProvider(doctorId));
    final resolvedProfile = asyncProfile?.asData?.value;

    return Scaffold(
      backgroundColor: AppPalette.paper,
      body: SafeArea(
        child: Column(
          children: [
            _Header(onBack: () => context.pop()),
            Expanded(
              child: doctorId.isEmpty || asyncProfile == null
                  ? _UnavailableBody(
                      currentStartAt: widget.target.currentStartAt,
                    )
                  : _SlotPickerBody(
                      doctorId: doctorId,
                      asyncProfile: asyncProfile,
                      currentStartAt: widget.target.currentStartAt,
                      selectedDayId: _selectedDayId,
                      selectedSlotId: _selectedSlotId,
                      submitError: _submitError,
                      onDaySelected: (id, label) => setState(() {
                        _selectedDayId = id;
                        _selectedDayLabel = label;
                        _selectedSlotId = null;
                        _selectedTimeLabel = null;
                      }),
                      onSlotSelected: (id, label) => setState(() {
                        _selectedSlotId = id;
                        _selectedTimeLabel = label;
                      }),
                    ),
            ),
            if (resolvedProfile != null)
              _SubmitBar(
                canSubmit: _selectedSlotId != null && !_submitting,
                isBusy: _submitting,
                onSubmit: () => _submit(resolvedProfile),
              ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          const SizedBox(width: 48),
          Expanded(
            child: Text(
              'appointments.reschedule_title'.tr(),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppPalette.primary,
              ),
            ),
          ),
          IconButton(
            onPressed: onBack,
            icon: const Icon(SolarIconsOutline.arrowRight),
          ),
        ],
      ),
    );
  }
}

class _UnavailableBody extends StatelessWidget {
  const _UnavailableBody({required this.currentStartAt});

  final DateTime currentStartAt;

  @override
  Widget build(BuildContext context) {
    final locale = context.locale.languageCode;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        _CurrentSlotCard(currentStartAt: currentStartAt, locale: locale),
        const SizedBox(height: 20),
        AppSurfaceCard(
          child: Row(
            children: [
              const Icon(
                SolarIconsOutline.infoCircle,
                color: AppPalette.inkMuted,
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'appointments.reschedule_unavailable'.tr(),
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppPalette.ink,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CurrentSlotCard extends StatelessWidget {
  const _CurrentSlotCard({required this.currentStartAt, required this.locale});

  final DateTime currentStartAt;
  final String locale;

  @override
  Widget build(BuildContext context) {
    final local = currentStartAt.toLocal();
    return AppSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'appointments.reschedule_current_slot'.tr(),
            style: const TextStyle(fontSize: 13, color: AppPalette.inkMuted),
          ),
          const SizedBox(height: 6),
          Text(
            '${AppFormatters.fullDate(local, locale: locale)} · ${AppFormatters.time(local, locale: locale)}',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppPalette.ink,
            ),
          ),
        ],
      ),
    );
  }
}

class _SlotPickerBody extends ConsumerWidget {
  const _SlotPickerBody({
    required this.doctorId,
    required this.asyncProfile,
    required this.currentStartAt,
    required this.selectedDayId,
    required this.selectedSlotId,
    required this.submitError,
    required this.onDaySelected,
    required this.onSlotSelected,
  });

  final String doctorId;
  final AsyncValue<DoctorProfile> asyncProfile;
  final DateTime currentStartAt;
  final String? selectedDayId;
  final String? selectedSlotId;
  final Failure? submitError;
  final _SlotSelection onDaySelected;
  final _SlotSelection onSlotSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = context.locale.languageCode;

    return AsyncValueView(
      value: asyncProfile,
      onRetry: () => ref.invalidate(doctorProfileProvider(doctorId)),
      data: (profile) => ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          _CurrentSlotCard(currentStartAt: currentStartAt, locale: locale),
          const SizedBox(height: 20),
          _AvailabilitySection(
            profile: profile,
            selectedDayId: selectedDayId,
            selectedSlotId: selectedSlotId,
            onDaySelected: onDaySelected,
            onSlotSelected: onSlotSelected,
          ),
          if (submitError != null) ...[
            const SizedBox(height: 12),
            ErrorBanner(message: _errorMessage(submitError!)),
          ],
        ],
      ),
    );
  }

  /// Delegates to the app-wide Arabic mapper — see
  /// `core/error/failure_message.dart`. The old version matched the
  /// backend's English conflict sentences verbatim; the mapper keys on
  /// `error.code`, so rewording the API no longer silently drops this screen
  /// back to a raw server string.
  String _errorMessage(Failure failure) =>
      failureMessage(failure, screenFallback: 'errors.server');
}

class _AvailabilitySection extends ConsumerWidget {
  const _AvailabilitySection({
    required this.profile,
    required this.selectedDayId,
    required this.selectedSlotId,
    required this.onDaySelected,
    required this.onSlotSelected,
  });

  final DoctorProfile profile;
  final String? selectedDayId;
  final String? selectedSlotId;
  final _SlotSelection onDaySelected;
  final _SlotSelection onSlotSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final clinicBranchId = profile.clinicBranchId;
    if (clinicBranchId == null) {
      return _SlotsCard(
        days: profile.availableDays,
        selectedDayId: selectedDayId,
        selectedSlotId: selectedSlotId,
        onDaySelected: onDaySelected,
        onSlotSelected: onSlotSelected,
      );
    }

    final params = (
      doctorId: profile.id,
      clinicBranchId: clinicBranchId,
      ianaTimezone: profile.ianaTimezone,
    );
    final asyncDays = ref.watch(doctorAvailabilityProvider(params));

    return AsyncValueView(
      value: asyncDays,
      onRetry: () => ref.invalidate(doctorAvailabilityProvider(params)),
      loadingWidget: const SizedBox(
        height: 120,
        child: Center(child: CircularProgressIndicator()),
      ),
      data: (days) => days.isEmpty
          ? SizedBox(
              height: 64,
              child: Center(child: Text('doctor_profile.no_slots'.tr())),
            )
          : _SlotsCard(
              days: days,
              selectedDayId: selectedDayId,
              selectedSlotId: selectedSlotId,
              onDaySelected: onDaySelected,
              onSlotSelected: onSlotSelected,
            ),
    );
  }
}

class _SlotsCard extends StatelessWidget {
  const _SlotsCard({
    required this.days,
    required this.selectedDayId,
    required this.selectedSlotId,
    required this.onDaySelected,
    required this.onSlotSelected,
  });

  final List<AvailableDay> days;
  final String? selectedDayId;
  final String? selectedSlotId;
  final _SlotSelection onDaySelected;
  final _SlotSelection onSlotSelected;

  @override
  Widget build(BuildContext context) {
    final selected =
        days.where((d) => d.id == selectedDayId).firstOrNull ??
        days.firstOrNull;

    return AppSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'appointments.reschedule_pick_slot'.tr(),
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppPalette.ink,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 64,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: days.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final day = days[index];
                final isSelected = day.id == selectedDayId;
                return InkWell(
                  onTap: () =>
                      onDaySelected(day.id, '${day.label} ${day.dayNumber}'),
                  borderRadius: BorderRadius.circular(AppRadii.md),
                  child: Container(
                    width: 88,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppPalette.primary.withValues(alpha: 0.12)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(AppRadii.md),
                      border: Border.all(
                        color: isSelected
                            ? AppPalette.primary
                            : AppPalette.border,
                        width: isSelected ? 1.5 : 1,
                      ),
                    ),
                    child: Text(
                      '${day.label} ${day.dayNumber}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: isSelected
                            ? AppPalette.primary
                            : AppPalette.ink,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 14),
          if (selected != null)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: selected.slots.map((slot) {
                final isSelected = slot.id == selectedSlotId;
                final enabled = slot.available;
                return InkWell(
                  onTap: enabled
                      ? () {
                          // `selected` (above) may be the auto-defaulted
                          // first day rather than one the user explicitly
                          // tapped — record its label here too, so
                          // `BookingRequest.dayLabel` is never blank when a
                          // slot is picked without ever touching the day
                          // chips.
                          if (selectedDayId == null) {
                            onDaySelected(
                              selected.id,
                              '${selected.label} ${selected.dayNumber}',
                            );
                          }
                          onSlotSelected(slot.id, slot.label);
                        }
                      : null,
                  borderRadius: BorderRadius.circular(AppRadii.sm),
                  child: Container(
                    width: 84,
                    height: 40,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: !enabled
                          ? AppPalette.surfaceSunken
                          : isSelected
                          ? AppPalette.primary.withValues(alpha: 0.08)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(AppRadii.sm),
                      border: Border.all(
                        color: !enabled
                            ? AppPalette.border
                            : isSelected
                            ? AppPalette.primary
                            : AppPalette.border,
                      ),
                    ),
                    child: Text(
                      slot.label,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: !enabled
                            ? AppPalette.inkMuted
                            : isSelected
                            ? AppPalette.primary
                            : AppPalette.ink,
                        decoration: enabled ? null : TextDecoration.lineThrough,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }
}

class _SubmitBar extends StatelessWidget {
  const _SubmitBar({
    required this.canSubmit,
    required this.isBusy,
    required this.onSubmit,
  });

  final bool canSubmit;
  final bool isBusy;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 17, 16, 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppPalette.border)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: canSubmit ? onSubmit : null,
            style: FilledButton.styleFrom(
              backgroundColor: AppPalette.primary,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadii.pill),
              ),
            ),
            child: isBusy
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    'appointments.reschedule_submit'.tr(),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

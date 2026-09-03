import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:med_super/core/theme/app_colors.dart';
import 'package:med_super/core/widgets/app_button.dart';
import 'package:med_super/core/widgets/app_text_field.dart';
import 'package:med_super/core/widgets/async_value_view.dart';
import 'package:med_super/core/widgets/step_progress_header.dart';
import 'package:med_super/features/provider_registration/domain/entities/clinic_working_day.dart';
import 'package:med_super/features/provider_registration/domain/entities/region_codes.dart';
import 'package:med_super/features/provider_registration/presentation/controllers/clinic_location_provider.dart';
import 'package:med_super/features/provider_registration/presentation/controllers/registration_form_controller.dart';
import 'package:med_super/features/provider_registration/presentation/controllers/registration_lookups_providers.dart';
import 'package:med_super/features/provider_registration/presentation/widgets/clinic_location_map_view.dart';
import 'package:med_super/features/provider_registration/presentation/widgets/working_hours_day_row.dart';

/// Default map center when the clinic has no saved location yet (Cairo).
const _defaultClinicPosition = LatLng(30.0444, 31.2357);

class DoctorRegistrationClinicScheduleScreen extends ConsumerStatefulWidget {
  const DoctorRegistrationClinicScheduleScreen({super.key});

  @override
  ConsumerState<DoctorRegistrationClinicScheduleScreen> createState() =>
      _DoctorRegistrationClinicScheduleScreenState();
}

class _DoctorRegistrationClinicScheduleScreenState
    extends ConsumerState<DoctorRegistrationClinicScheduleScreen> {
  late final _nameController = TextEditingController();
  late final _addressController = TextEditingController();
  late final _cityController = TextEditingController();
  late final _feeController = TextEditingController();
  late final _locationService = const ClinicLocationService();
  String? _regionCode;

  @override
  void initState() {
    super.initState();
    final draft = ref.read(registrationFormControllerProvider);
    _nameController.text = draft.clinicName;
    _addressController.text = draft.clinicAddress;
    _cityController.text = draft.city ?? '';
    _feeController.text = draft.consultationFee == 0
        ? ''
        : '${draft.consultationFee}';
    _regionCode = draft.regionCode;
  }

  void _save({double? lat, double? lng}) {
    ref
        .read(registrationFormControllerProvider.notifier)
        .updateClinicInfo(
          clinicName: _nameController.text.trim(),
          clinicAddress: _addressController.text.trim(),
          city: _cityController.text.trim().isEmpty
              ? null
              : _cityController.text.trim(),
          regionCode: _regionCode,
          consultationFee: int.tryParse(_feeController.text) ?? 0,
          clinicLat: lat,
          clinicLng: lng,
        );
  }

  Future<void> _pickTime(Weekday day, {required bool isFrom}) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked == null) return;
    final time = ClinicTime(hour: picked.hour, minute: picked.minute);
    final notifier = ref.read(registrationFormControllerProvider.notifier);
    final current = ref
        .read(registrationFormControllerProvider)
        .workingDays
        .firstWhere((d) => d.day == day);
    notifier.setWorkingHours(
      day,
      from: isFrom ? time : current.from,
      to: isFrom ? current.to : time,
    );
  }

  void _continue() {
    _save();
    context.push('/provider/registration/review');
  }

  @override
  Widget build(BuildContext context) {
    final draft = ref.watch(registrationFormControllerProvider);
    final lookupsAsync = ref.watch(registrationLookupsProvider);
    final initialPosition = draft.clinicLat != null && draft.clinicLng != null
        ? LatLng(draft.clinicLat!, draft.clinicLng!)
        : _defaultClinicPosition;

    return Scaffold(
      backgroundColor: AppColors.surfaceApp,
      body: SafeArea(
        child: Column(
          children: [
            _Header(),
            Expanded(
              child: AsyncValueView(
                value: lookupsAsync,
                onRetry: () => ref.invalidate(registrationLookupsProvider),
                data: (lookups) => ListView(
                  padding: const EdgeInsets.fromLTRB(16, 32, 16, 26),
                  children: [
                    StepProgressHeader(
                      stepLabels: [
                        'provider_registration.step_basic_info'.tr(),
                        'provider_registration.step_verification'.tr(),
                        'provider_registration.step_clinic_schedule'.tr(),
                        'provider_registration.step_review'.tr(),
                      ],
                      currentStep: 2,
                      accentColor: AppColors.providerPrimary,
                    ),
                    const SizedBox(height: 4),
                    Center(
                      child: Text(
                        'provider_registration.clinic_schedule.step_caption'
                            .tr(),
                        style: const TextStyle(color: AppColors.bodyText),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'provider_registration.clinic_schedule.clinic_info_title'
                                .tr(),
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: AppColors.ink900,
                            ),
                          ),
                          const SizedBox(height: 16),
                          AppTextField(
                            label:
                                'provider_registration.clinic_schedule.clinic_name_label'
                                    .tr(),
                            controller: _nameController,
                            hint:
                                'provider_registration.clinic_schedule.clinic_name_hint'
                                    .tr(),
                            onChanged: (_) => _save(),
                          ),
                          const SizedBox(height: 16),
                          AppTextField(
                            label:
                                'provider_registration.clinic_schedule.clinic_address_label'
                                    .tr(),
                            controller: _addressController,
                            hint:
                                'provider_registration.clinic_schedule.clinic_address_hint'
                                    .tr(),
                            onChanged: (_) => _save(),
                          ),
                          const SizedBox(height: 8),
                          AppTextField(
                            label:
                                'provider_registration.clinic_schedule.city_label'
                                    .tr(),
                            controller: _cityController,
                            hint:
                                'provider_registration.clinic_schedule.city_hint'
                                    .tr(),
                            onChanged: (_) => _save(),
                          ),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<String>(
                            initialValue: _regionCode,
                            decoration: InputDecoration(
                              labelText:
                                  'provider_registration.clinic_schedule.region_label'
                                      .tr(),
                            ),
                            items: kRegionCodes
                                .map(
                                  (r) => DropdownMenuItem(
                                    value: r.id,
                                    child: Text(r.label),
                                  ),
                                )
                                .toList(),
                            onChanged: (v) {
                              setState(() => _regionCode = v);
                              _save();
                            },
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'provider_registration.clinic_schedule.map_label'
                                .tr(),
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppColors.ink900,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ClinicLocationMapView(
                            initialPosition: initialPosition,
                            onPositionChanged: (position) => _save(
                              lat: position.latitude,
                              lng: position.longitude,
                            ),
                            onLocateMe: _locationService.getCurrentPosition,
                          ),
                          const Divider(
                            height: 32,
                            color: AppColors.borderMedium,
                          ),
                          Text(
                            'provider_registration.clinic_schedule.fee_title'
                                .tr(),
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: AppColors.ink900,
                            ),
                          ),
                          const SizedBox(height: 16),
                          AppTextField(
                            label: '',
                            controller: _feeController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            onChanged: (_) => _save(),
                            suffix: Padding(
                              padding: const EdgeInsets.only(top: 14),
                              child: Text(
                                'provider_registration.clinic_schedule.fee_currency'
                                    .tr(),
                                style: const TextStyle(
                                  color: AppColors.bodyText,
                                ),
                              ),
                            ),
                          ),
                          const Divider(
                            height: 32,
                            color: AppColors.borderMedium,
                          ),
                          Text(
                            'provider_registration.clinic_schedule.working_hours_title'
                                .tr(),
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: AppColors.ink900,
                            ),
                          ),
                          const SizedBox(height: 16),
                          for (final day in draft.workingDays)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: WorkingHoursDayRow(
                                day: day,
                                onToggle: (v) => ref
                                    .read(
                                      registrationFormControllerProvider
                                          .notifier,
                                    )
                                    .toggleWorkingDay(day.day, v),
                                onPickFrom: () =>
                                    _pickTime(day.day, isFrom: true),
                                onPickTo: () =>
                                    _pickTime(day.day, isFrom: false),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: AppButton.filled(
                            label: 'provider_registration.continue_alt_cta'
                                .tr(),
                            onPressed: draft.clinicScheduleComplete
                                ? _continue
                                : null,
                            icon: const Icon(Icons.arrow_back, size: 18),
                            backgroundColor: AppColors.providerPrimary,
                            foregroundColor: Colors.white,
                            borderRadius: 16,
                          ),
                        ),
                        const SizedBox(width: 12),
                        AppButton.outlined(
                          label: 'provider_registration.previous_cta'.tr(),
                          onPressed: () => context.pop(),
                          foregroundColor: AppColors.providerPrimary,
                          borderRadius: 16,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppColors.borderMedium)),
      ),
      child: Row(
        children: [
          const SizedBox(width: 48),
          Expanded(
            child: Text(
              'provider_registration.title'.tr(),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppColors.providerPrimary,
              ),
            ),
          ),
          IconButton(
            onPressed: () => context.pop(),
            icon: const Icon(
              Icons.arrow_forward,
              color: AppColors.providerPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

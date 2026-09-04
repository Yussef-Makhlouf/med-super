import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:med_super/core/theme/app_colors.dart';
import 'package:med_super/features/provider_dashboard/domain/entities/doctor_clinic.dart';
import 'package:med_super/features/provider_dashboard/domain/entities/doctor_schedule_template.dart';

/// What the doctor filled in. Times are `"HH:mm"` local to the chosen
/// branch's timezone, matching the backend's own contract.
typedef ScheduleTemplateDraft = ({
  String affiliationId,
  int weekday,
  String startTime,
  String endTime,
  int slotDurationMinutes,
  int bufferMinutes,
});

/// Create/edit sheet for one weekly availability window. Pass [existing] to
/// edit; omit it to create.
Future<ScheduleTemplateDraft?> showScheduleTemplateEditor(
  BuildContext context, {
  required List<DoctorClinic> clinics,
  DoctorScheduleTemplate? existing,
}) {
  return showModalBottomSheet<ScheduleTemplateDraft>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: _ScheduleTemplateEditor(clinics: clinics, existing: existing),
    ),
  );
}

class _ScheduleTemplateEditor extends StatefulWidget {
  const _ScheduleTemplateEditor({required this.clinics, this.existing});

  final List<DoctorClinic> clinics;
  final DoctorScheduleTemplate? existing;

  @override
  State<_ScheduleTemplateEditor> createState() =>
      _ScheduleTemplateEditorState();
}

class _ScheduleTemplateEditorState extends State<_ScheduleTemplateEditor> {
  late String _affiliationId;
  late int _weekday;
  late TimeOfDay _start;
  late TimeOfDay _end;
  late int _slotDuration;
  late int _buffer;

  String? _windowError;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _affiliationId =
        existing?.doctorClinicAffiliationId ??
        widget.clinics.first.affiliationId;
    _weekday = existing?.weekday ?? DateTime.now().weekday;
    _start = _parse(existing?.startTime ?? '09:00');
    _end = _parse(existing?.endTime ?? '17:00');
    _slotDuration = existing?.slotDurationMinutes ?? 30;
    _buffer = existing?.bufferMinutes ?? 0;
  }

  static TimeOfDay _parse(String hhmm) {
    final parts = hhmm.split(':');
    return TimeOfDay(
      hour: int.tryParse(parts.first) ?? 9,
      minute: int.tryParse(parts.last) ?? 0,
    );
  }

  static String _format(TimeOfDay time) =>
      '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';

  String get _selectedTimezone => widget.clinics
      .firstWhere(
        (c) => c.affiliationId == _affiliationId,
        orElse: () => widget.clinics.first,
      )
      .ianaTimezone;

  Future<void> _pick({required bool isStart}) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isStart ? _start : _end,
    );
    if (picked == null) return;
    setState(() {
      if (isStart) {
        _start = picked;
      } else {
        _end = picked;
      }
      _windowError = null;
    });
  }

  void _submit() {
    // Mirrors the server's own `INVALID_SCHEDULE_WINDOW` rule so the common
    // mistake is caught before a round trip — the server still enforces it.
    final startMinutes = _start.hour * 60 + _start.minute;
    final endMinutes = _end.hour * 60 + _end.minute;
    if (endMinutes <= startMinutes) {
      setState(
        () => _windowError = 'provider_dashboard.schedule.invalid_window'.tr(),
      );
      return;
    }

    Navigator.of(context).pop((
      affiliationId: _affiliationId,
      weekday: _weekday,
      startTime: _format(_start),
      endTime: _format(_end),
      slotDurationMinutes: _slotDuration,
      bufferMinutes: _buffer,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.existing == null
                  ? 'provider_dashboard.schedule.add'.tr()
                  : 'provider_dashboard.schedule.edit'.tr(),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: AppColors.ink900,
              ),
            ),
            const SizedBox(height: 16),
            if (widget.clinics.length > 1) ...[
              DropdownButtonFormField<String>(
                initialValue: _affiliationId,
                decoration: InputDecoration(
                  labelText: 'provider_dashboard.schedule.branch'.tr(),
                  border: const OutlineInputBorder(),
                  isDense: true,
                ),
                items: [
                  for (final clinic in widget.clinics)
                    DropdownMenuItem(
                      value: clinic.affiliationId,
                      child: Text(
                        clinic.clinicName,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
                onChanged: (value) =>
                    setState(() => _affiliationId = value ?? _affiliationId),
              ),
              const SizedBox(height: 12),
            ],
            DropdownButtonFormField<int>(
              initialValue: _weekday,
              decoration: InputDecoration(
                labelText: 'provider_dashboard.schedule.weekday'.tr(),
                border: const OutlineInputBorder(),
                isDense: true,
              ),
              items: [
                for (var day = 1; day <= 7; day++)
                  DropdownMenuItem(
                    value: day,
                    child: Text('provider_dashboard.weekday.$day'.tr()),
                  ),
              ],
              onChanged: (value) => setState(() => _weekday = value ?? _weekday),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _timeField(
                    label: 'provider_dashboard.schedule.start'.tr(),
                    value: _format(_start),
                    onTap: () => _pick(isStart: true),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _timeField(
                    label: 'provider_dashboard.schedule.end'.tr(),
                    value: _format(_end),
                    onTap: () => _pick(isStart: false),
                  ),
                ),
              ],
            ),
            if (_windowError != null) ...[
              const SizedBox(height: 8),
              Text(
                _windowError!,
                style: const TextStyle(
                  color: AppColors.errorRed,
                  fontSize: 12,
                ),
              ),
            ],
            const SizedBox(height: 8),
            Text(
              'provider_dashboard.schedule.times_local_note'.tr(
                args: [_selectedTimezone],
              ),
              style: const TextStyle(fontSize: 11, color: AppColors.mutedText2),
            ),
            const SizedBox(height: 16),
            _numberField(
              label: 'provider_dashboard.schedule.slot_duration'.tr(),
              value: _slotDuration,
              min: 5,
              max: 240,
              step: 5,
              onChanged: (v) => setState(() => _slotDuration = v),
            ),
            const SizedBox(height: 12),
            _numberField(
              label: 'provider_dashboard.schedule.buffer'.tr(),
              value: _buffer,
              min: 0,
              max: 120,
              step: 5,
              onChanged: (v) => setState(() => _buffer = v),
            ),
            const SizedBox(height: 12),
            Text(
              'provider_dashboard.schedule.not_retroactive_note'.tr(),
              style: const TextStyle(fontSize: 11, color: AppColors.mutedText2),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 48,
              width: double.infinity,
              child: FilledButton(
                onPressed: _submit,
                child: Text('provider_dashboard.schedule.save'.tr()),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _timeField({
    required String label,
    required String value,
    required VoidCallback onTap,
  }) => InkWell(
    onTap: onTap,
    child: InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        isDense: true,
      ),
      child: Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
    ),
  );

  /// Stepper rather than a free-text field: the backend constrains both
  /// values to a range and a raw text box would just produce 400s.
  Widget _numberField({
    required String label,
    required int value,
    required int min,
    required int max,
    required int step,
    required ValueChanged<int> onChanged,
  }) => Row(
    children: [
      Expanded(
        child: Text(
          label,
          style: const TextStyle(fontSize: 13, color: AppColors.ink900),
        ),
      ),
      IconButton(
        icon: const Icon(Icons.remove_circle_outline),
        onPressed: value - step >= min ? () => onChanged(value - step) : null,
      ),
      SizedBox(
        width: 40,
        child: Text(
          '$value',
          textAlign: TextAlign.center,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      IconButton(
        icon: const Icon(Icons.add_circle_outline),
        onPressed: value + step <= max ? () => onChanged(value + step) : null,
      ),
    ],
  );
}

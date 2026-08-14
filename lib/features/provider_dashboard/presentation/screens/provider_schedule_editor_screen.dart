import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:med_super/core/theme/app_colors.dart';
import 'package:med_super/core/theme/color_schemes.dart';
import 'package:med_super/core/widgets/app_button.dart';
import 'package:med_super/core/widgets/async_value_view.dart';
import 'package:med_super/features/provider_registration/domain/entities/clinic_working_day.dart';
import 'package:med_super/features/provider_registration/presentation/widgets/working_hours_day_row.dart';
import '../controllers/provider_dashboard_providers.dart';

class ProviderScheduleEditorScreen extends ConsumerStatefulWidget {
  const ProviderScheduleEditorScreen({super.key});

  @override
  ConsumerState<ProviderScheduleEditorScreen> createState() =>
      _ProviderScheduleEditorScreenState();
}

class _ProviderScheduleEditorScreenState
    extends ConsumerState<ProviderScheduleEditorScreen> {
  List<ClinicWorkingDay>? _days;
  bool _isSaving = false;
  bool _isDirty = false;

  Future<void> _pickTime(Weekday day, {required bool isFrom}) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked == null || _days == null) return;

    final time = ClinicTime(hour: picked.hour, minute: picked.minute);
    setState(() {
      _days = _days!.map((d) {
        if (d.day != day) return d;
        return d.copyWith(
          from: isFrom ? time : d.from,
          to: isFrom ? d.to : time,
        );
      }).toList();
      _isDirty = true;
    });
  }

  void _toggleDay(Weekday day, bool enabled) {
    if (_days == null) return;
    setState(() {
      _days = _days!.map((d) {
        if (d.day != day) return d;
        return d.copyWith(isEnabled: enabled);
      }).toList();
      _isDirty = true;
    });
  }

  Future<void> _submit() async {
    if (_days == null) return;
    setState(() => _isSaving = true);

    final useCase = ref.read(updateDoctorScheduleUseCaseProvider);
    final result = await useCase.call(_days!);

    if (!mounted) return;
    setState(() => _isSaving = false);

    result.when(
      ok: (updated) {
        ref.invalidate(doctorScheduleProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم تحديث جدول المواعيد بنجاح')),
        );
        Navigator.of(context).pop();
      },
      err: (failure) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('حدث خطأ: ${failure.toString()}')),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheduleAsync = ref.watch(doctorScheduleProvider);

    return Scaffold(
      backgroundColor: AppColors.surfaceApp,
      appBar: AppBar(
        title: const Text('جدول المواعيد وساعات العمل'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.ink900,
        elevation: 0,
      ),
      body: AsyncValueView(
        value: scheduleAsync,
        onRetry: () => ref.invalidate(doctorScheduleProvider),
        data: (initialDays) {
          _days ??= List.from(initialDays);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'حدد أيام وساعات العمل المستمرة لاستقبال حجز المواعيد:',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.mutedText2,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _days!.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final day = _days![index];
                    return WorkingHoursDayRow(
                      day: day,
                      onToggle: (v) => _toggleDay(day.day, v),
                      onPickFrom: () => _pickTime(day.day, isFrom: true),
                      onPickTo: () => _pickTime(day.day, isFrom: false),
                    );
                  },
                ),
                const SizedBox(height: 24),
                AppButton.filled(
                  label: 'حفظ التغييرات',
                  isLoading: _isSaving,
                  backgroundColor: brandBlue,
                  foregroundColor: Colors.white,
                  fullWidth: true,
                  onPressed: _isDirty ? _submit : null,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

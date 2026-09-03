import 'package:flutter/material.dart';
import 'package:med_super/core/theme/color_schemes.dart';
import 'package:med_super/core/theme/app_colors.dart';
import 'package:med_super/core/widgets/app_button.dart';
import 'package:med_super/core/widgets/app_text_field.dart';

class AddAppointmentBottomSheet extends StatefulWidget {
  const AddAppointmentBottomSheet({required this.onAdd, super.key});

  final Function(String patientName, DateTime startTime, DateTime endTime)
  onAdd;

  @override
  State<AddAppointmentBottomSheet> createState() =>
      _AddAppointmentBottomSheetState();
}

class _AddAppointmentBottomSheetState extends State<AddAppointmentBottomSheet> {
  final _nameController = TextEditingController();
  TimeOfDay _selectedTime = TimeOfDay.now();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    final now = DateTime.now();
    final startTime = DateTime(
      now.year,
      now.month,
      now.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );
    final endTime = startTime.add(const Duration(minutes: 30));

    setState(() => _isSubmitting = true);
    widget.onAdd(name, startTime, endTime);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.borderLight,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'إضافة موعد جديد',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.ink900,
            ),
          ),
          const SizedBox(height: 20),
          AppTextField(
            controller: _nameController,
            label: 'اسم المريض',
            hint: 'اسم المريض',
          ),
          const SizedBox(height: 16),
          ListTile(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: AppColors.borderLight),
            ),
            leading: const Icon(Icons.access_time_rounded, color: brandBlue),
            title: Text(
              'وقت الموعد: ${_selectedTime.format(context)}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            trailing: TextButton(
              onPressed: () async {
                final time = await showTimePicker(
                  context: context,
                  initialTime: _selectedTime,
                );
                if (time != null) {
                  setState(() => _selectedTime = time);
                }
              },
              child: const Text('تغيير'),
            ),
          ),
          const SizedBox(height: 24),
          AppButton.filled(
            label: 'حفظ الموعد',
            isLoading: _isSubmitting,
            backgroundColor: brandBlue,
            foregroundColor: Colors.white,
            onPressed: _submit,
          ),
        ],
      ),
    );
  }
}

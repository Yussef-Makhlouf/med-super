import 'package:flutter/material.dart';
import 'package:med_super/core/theme/app_colors.dart';
import 'package:med_super/core/theme/color_schemes.dart';
import 'package:med_super/features/provider_dashboard/domain/entities/schedule_slot.dart';

/// Bottom sheet to book an available [ScheduleSlot] with a patient name.
/// Mock-only — writes straight into [ScheduleOverridesNotifier] via the
/// caller, no backend call.
class BookSlotBottomSheet extends StatefulWidget {
  const BookSlotBottomSheet({required this.slot, required this.onConfirm, super.key});

  final ScheduleSlot slot;
  final void Function(String patientName, String? note) onConfirm;

  @override
  State<BookSlotBottomSheet> createState() => _BookSlotBottomSheetState();
}

class _BookSlotBottomSheetState extends State<BookSlotBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _noteController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  String _formatTime(DateTime dt) {
    final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final minute = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour >= 12 ? 'م' : 'ص';
    return '${hour.toString().padLeft(2, '0')}:$minute $period';
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    widget.onConfirm(
      _nameController.text.trim(),
      _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(24, 20, 24, 24 + bottomInset),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.borderMedium,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'حجز موعد جديد',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppColors.ink900,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.access_time, size: 15, color: AppColors.mutedText2),
                const SizedBox(width: 6),
                Text(
                  '${_formatTime(widget.slot.start)} - ${_formatTime(widget.slot.end)}',
                  style: const TextStyle(fontSize: 13, color: AppColors.mutedText2),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text(
              'اسم المريض',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.ink900,
              ),
            ),
            const SizedBox(height: 6),
            TextFormField(
              controller: _nameController,
              textDirection: TextDirection.rtl,
              decoration: _inputDecoration(hint: 'مثال: أحمد محمود'),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'اسم المريض مطلوب';
                return null;
              },
            ),
            const SizedBox(height: 16),
            const Text(
              'ملاحظات (اختياري)',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.ink900,
              ),
            ),
            const SizedBox(height: 6),
            TextFormField(
              controller: _noteController,
              textDirection: TextDirection.rtl,
              maxLines: 2,
              decoration: _inputDecoration(hint: 'سبب الزيارة أو أي تفاصيل إضافية'),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: brandBlue,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text(
                  'تأكيد الحجز',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({required String hint}) => InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(color: AppColors.placeholderText),
    filled: true,
    fillColor: AppColors.surfaceCard,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: AppColors.borderLight),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: AppColors.borderLight),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: brandBlue, width: 1.5),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: AppColors.errorRed),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: AppColors.errorRed, width: 1.5),
    ),
  );
}

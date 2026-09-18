import 'dart:ui' as ui;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:med_super/core/theme/app_colors.dart';
import 'package:med_super/core/theme/app_radii.dart';
import 'package:med_super/core/theme/app_shadows.dart';
import 'package:med_super/core/widgets/app_text_field.dart';
import 'package:med_super/features/auth/presentation/controllers/session_provider.dart';

/// What the doctor filled in to add another branch under a clinic they
/// already practise at (`POST /v1/doctors/me/clinics/{clinicId}/branches`).
/// This never creates a brand-new clinic — `clinicId` is fixed to one the
/// doctor is already affiliated with.
typedef AddClinicBranchDraft = ({
  String clinicId,
  String phone,
  String ianaTimezone,
  String addressLine1,
  String addressCity,
  String regionCode,
  String countryCode,
  double consultFee,
});

Future<AddClinicBranchDraft?> showAddClinicBranchSheet(
  BuildContext context, {
  required String clinicId,
  required String clinicName,
  required String defaultCurrency,
}) {
  return showModalBottomSheet<AddClinicBranchDraft>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: _AddClinicBranchSheet(
        clinicId: clinicId,
        clinicName: clinicName,
        defaultCurrency: defaultCurrency,
      ),
    ),
  );
}

class _AddClinicBranchSheet extends StatefulWidget {
  const _AddClinicBranchSheet({
    required this.clinicId,
    required this.clinicName,
    required this.defaultCurrency,
  });

  final String clinicId;
  final String clinicName;
  final String defaultCurrency;

  @override
  State<_AddClinicBranchSheet> createState() => _AddClinicBranchSheetState();
}

class _AddClinicBranchSheetState extends State<_AddClinicBranchSheet> {
  final _formKey = GlobalKey<FormState>();
  final _phone = TextEditingController();
  final _timezone = TextEditingController(text: 'Africa/Cairo');
  final _line1 = TextEditingController();
  final _city = TextEditingController();
  final _regionCode = TextEditingController();
  final _countryCode = TextEditingController(text: 'EG');
  final _consultFee = TextEditingController();

  @override
  void dispose() {
    _phone.dispose();
    _timezone.dispose();
    _line1.dispose();
    _city.dispose();
    _regionCode.dispose();
    _countryCode.dispose();
    _consultFee.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    Navigator.of(context).pop((
      clinicId: widget.clinicId,
      phone: normalizeEgyptPhone(_phone.text.trim()),
      ianaTimezone: _timezone.text.trim(),
      addressLine1: _line1.text.trim(),
      addressCity: _city.text.trim(),
      regionCode: _regionCode.text.trim(),
      countryCode: _countryCode.text.trim(),
      consultFee: double.parse(_consultFee.text.trim()),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'provider_dashboard.clinics.add_branch'.tr(),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: AppColors.ink900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                widget.clinicName,
                style: const TextStyle(fontSize: 12, color: AppColors.mutedText2),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppRadii.lg),
                  boxShadow: AppShadows.resting,
                ),
                child: Column(
                  children: [
                    AppTextField(
                      controller: _phone,
                      label: 'provider_dashboard.clinics.phone'.tr(),
                      keyboardType: TextInputType.phone,
                      textDirection: ui.TextDirection.ltr,
                      textAlign: TextAlign.left,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(11),
                      ],
                      validator: (value) {
                        final trimmed = (value ?? '').trim();
                        if (trimmed.isEmpty) {
                          return 'provider_dashboard.clinics.phone'.tr();
                        }
                        if (!isValidEgyptPhone(trimmed)) {
                          return 'provider_dashboard.clinics.phone'.tr();
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    AppTextField(
                      controller: _line1,
                      label: 'provider_dashboard.clinics.address_line'.tr(),
                    ),
                    const SizedBox(height: 16),
                    AppTextField(
                      controller: _city,
                      label: 'provider_dashboard.clinics.city'.tr(),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: AppTextField(
                            controller: _regionCode,
                            label: 'provider_dashboard.clinics.region_code'.tr(),
                            textDirection: ui.TextDirection.ltr,
                            textAlign: TextAlign.left,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: AppTextField(
                            controller: _countryCode,
                            label: 'provider_dashboard.clinics.country_code'.tr(),
                            textDirection: ui.TextDirection.ltr,
                            textAlign: TextAlign.left,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    AppTextField(
                      controller: _timezone,
                      label: 'provider_dashboard.clinics.timezone'.tr(),
                      textDirection: ui.TextDirection.ltr,
                      textAlign: TextAlign.left,
                    ),
                    const SizedBox(height: 16),
                    AppTextField(
                      controller: _consultFee,
                      label:
                          '${'provider_dashboard.clinics.consult_fee'.tr()} (${widget.defaultCurrency})',
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      textDirection: ui.TextDirection.ltr,
                      textAlign: TextAlign.left,
                      validator: (value) {
                        final parsed = double.tryParse((value ?? '').trim());
                        if (parsed == null || parsed <= 0) {
                          return 'provider_dashboard.clinics.consult_fee'.tr();
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'provider_dashboard.clinics.new_branch_pending_note'.tr(),
                style: const TextStyle(fontSize: 11, color: AppColors.mutedText2),
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 56,
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(shape: const StadiumBorder()),
                  onPressed: _submit,
                  child: Text(
                    'provider_dashboard.clinics.add_branch'.tr(),
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

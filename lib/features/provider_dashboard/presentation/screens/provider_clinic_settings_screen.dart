import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:med_super/core/theme/app_colors.dart';
import 'package:med_super/core/theme/color_schemes.dart';
import 'package:med_super/core/widgets/async_value_view.dart';
import 'package:med_super/core/widgets/empty_state.dart';
import 'package:med_super/features/provider_dashboard/domain/entities/doctor_clinic.dart';
import 'package:med_super/features/provider_dashboard/presentation/controllers/provider_dashboard_providers.dart';
import 'package:med_super/features/provider_dashboard/presentation/controllers/provider_failure_message.dart';

/// The doctor's clinics and branches, backed by `GET /v1/doctors/me/clinics`
/// (File 12 Part 49.2).
///
/// Replaces the previous single-clinic "settings" form, which was mock-only
/// and modelled a clinic that could not exist: one hardcoded clinic with an
/// `email` field no clinic table has. A doctor can practise at several
/// branches, so this is a list, and only the **operational** fields are
/// editable — verification status and the consultation fee are Admin-owned
/// and shown read-only rather than silently dropped on save.
class ProviderClinicSettingsScreen extends ConsumerWidget {
  const ProviderClinicSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(myClinicsProvider);

    return Scaffold(
      backgroundColor: AppColors.surfaceApp,
      appBar: AppBar(title: Text('provider_dashboard.clinics.title'.tr())),
      body: AsyncValueView<List<DoctorClinic>>(
        value: async,
        onRetry: () => ref.invalidate(myClinicsProvider),
        data: (clinics) {
          if (clinics.isEmpty) {
            return EmptyState(
              title: 'provider_dashboard.clinics.empty_title'.tr(),
              subtitle: 'provider_dashboard.clinics.empty_subtitle'.tr(),
              icon: Icons.local_hospital_outlined,
            );
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(myClinicsProvider),
            child: ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: clinics.length,
              itemBuilder: (context, index) =>
                  _ClinicBranchCard(clinic: clinics[index]),
            ),
          );
        },
      ),
    );
  }
}

class _ClinicBranchCard extends ConsumerStatefulWidget {
  const _ClinicBranchCard({required this.clinic});

  final DoctorClinic clinic;

  @override
  ConsumerState<_ClinicBranchCard> createState() => _ClinicBranchCardState();
}

class _ClinicBranchCardState extends ConsumerState<_ClinicBranchCard> {
  late final TextEditingController _phone;
  late final TextEditingController _timezone;
  late final TextEditingController _line1;
  late final TextEditingController _city;
  final _formKey = GlobalKey<FormState>();

  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _phone = TextEditingController(text: widget.clinic.phone);
    _timezone = TextEditingController(text: widget.clinic.ianaTimezone);
    _line1 = TextEditingController(text: widget.clinic.address.line1);
    _city = TextEditingController(text: widget.clinic.address.city);
  }

  @override
  void dispose() {
    _phone.dispose();
    _timezone.dispose();
    _line1.dispose();
    _city.dispose();
    super.dispose();
  }

  /// Only actually-changed fields are sent, so a save never rewrites a field
  /// the doctor did not touch (and never bumps a version for nothing).
  Map<String, String?> get _changedFields {
    final clinic = widget.clinic;
    return {
      'phone': _phone.text.trim() == clinic.phone ? null : _phone.text.trim(),
      'ianaTimezone': _timezone.text.trim() == clinic.ianaTimezone
          ? null
          : _timezone.text.trim(),
      'line1': _line1.text.trim() == clinic.address.line1
          ? null
          : _line1.text.trim(),
      'city': _city.text.trim() == clinic.address.city
          ? null
          : _city.text.trim(),
    };
  }

  bool get _isDirty => _changedFields.values.any((v) => v != null);

  void _showSnack(String message, {bool success = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: success ? const Color(0xFF10B981) : null,
      ),
    );
  }

  Future<void> _save() async {
    if (_saving || !(_formKey.currentState?.validate() ?? false)) return;
    final changed = _changedFields;
    if (!_isDirty) return;

    setState(() => _saving = true);
    final result = await ref
        .read(updateMyClinicBranchUseCaseProvider)
        .call(
          branchId: widget.clinic.clinicBranchId,
          phone: changed['phone'],
          ianaTimezone: changed['ianaTimezone'],
          addressLine1: changed['line1'],
          addressCity: changed['city'],
        );
    if (!mounted) return;
    setState(() => _saving = false);

    result.when(
      ok: (_) {
        _showSnack('provider_dashboard.clinics.saved'.tr(), success: true);
        // Refetch rather than trusting the local copy — the response is the
        // server's own view of the row after the write.
        ref.invalidate(myClinicsProvider);
      },
      err: (failure) => _showSnack(providerFailureMessage(failure)),
    );
  }

  Future<void> _togglePaused() async {
    if (_saving) return;
    final wasActive =
        widget.clinic.affiliationStatus == AffiliationStatus.active;

    if (wasActive) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text('provider_dashboard.clinics.pause_title'.tr()),
          content: Text('provider_dashboard.clinics.pause_message'.tr()),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text('provider_dashboard.cancel.keep'.tr()),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text('provider_dashboard.clinics.pause'.tr()),
            ),
          ],
        ),
      );
      if (confirmed != true || !mounted) return;
    }

    setState(() => _saving = true);
    final result = await ref
        .read(setMyAffiliationActiveUseCaseProvider)
        .call(affiliationId: widget.clinic.affiliationId, active: !wasActive);
    if (!mounted) return;
    setState(() => _saving = false);

    result.when(
      ok: (_) {
        _showSnack('provider_dashboard.clinics.saved'.tr(), success: true);
        ref.invalidate(myClinicsProvider);
      },
      err: (failure) => _showSnack(providerFailureMessage(failure)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final clinic = widget.clinic;
    final isActive = clinic.affiliationStatus == AffiliationStatus.active;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    clinic.clinicName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: AppColors.ink900,
                    ),
                  ),
                ),
                _statusChip(clinic),
              ],
            ),
            const SizedBox(height: 10),
            if (!clinic.isAcceptingBookings)
              _notice(
                isActive
                    ? 'provider_dashboard.clinics.unverified_note'.tr()
                    : 'provider_dashboard.clinics.paused_note'.tr(),
              ),
            const SizedBox(height: 12),
            _field(
              controller: _phone,
              label: 'provider_dashboard.clinics.phone'.tr(),
              keyboardType: TextInputType.phone,
            ),
            _field(
              controller: _line1,
              label: 'provider_dashboard.clinics.address_line'.tr(),
            ),
            _field(
              controller: _city,
              label: 'provider_dashboard.clinics.city'.tr(),
            ),
            _field(
              controller: _timezone,
              label: 'provider_dashboard.clinics.timezone'.tr(),
            ),
            const SizedBox(height: 4),
            _readOnlyRow(
              'provider_dashboard.clinics.consult_fee'.tr(),
              '${clinic.consultFee} ${clinic.currency}',
            ),
            const SizedBox(height: 8),
            Text(
              'provider_dashboard.clinics.admin_only_note'.tr(),
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.mutedText2,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 46,
                    child: ElevatedButton(
                      onPressed: _saving ? null : _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: brandBlue,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _saving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text('provider_dashboard.clinics.save'.tr()),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SizedBox(
                    height: 46,
                    child: OutlinedButton(
                      onPressed: _saving ? null : _togglePaused,
                      child: Text(
                        isActive
                            ? 'provider_dashboard.clinics.pause'.tr()
                            : 'provider_dashboard.clinics.resume'.tr(),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusChip(DoctorClinic clinic) {
    final (label, color) = switch (clinic.affiliationStatus) {
      AffiliationStatus.active => (
        'provider_dashboard.clinics.affiliation_active'.tr(),
        const Color(0xFF10B981),
      ),
      _ => (
        'provider_dashboard.clinics.affiliation_paused'.tr(),
        Colors.orange,
      ),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _notice(String text) => Container(
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
      color: const Color(0xFFFFF7ED),
      borderRadius: BorderRadius.circular(10),
    ),
    child: Row(
      children: [
        const Icon(Icons.info_outline, size: 16, color: Colors.orange),
        const SizedBox(width: 8),
        Expanded(
          child: Text(text, style: const TextStyle(fontSize: 12)),
        ),
      ],
    ),
  );

  Widget _field({
    required TextEditingController controller,
    required String label,
    TextInputType? keyboardType,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        isDense: true,
      ),
      validator: (value) =>
          (value == null || value.trim().isEmpty) ? label : null,
    ),
  );

  Widget _readOnlyRow(String label, String value) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(
        label,
        style: const TextStyle(fontSize: 12, color: AppColors.mutedText2),
      ),
      Text(
        value,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w800,
          color: AppColors.ink900,
        ),
      ),
    ],
  );
}

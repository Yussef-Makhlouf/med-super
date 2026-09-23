import 'dart:ui' as ui;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:med_super/core/error/failure.dart';
import 'package:med_super/core/theme/app_colors.dart';
import 'package:med_super/core/theme/app_radii.dart';
import 'package:med_super/core/theme/app_shadows.dart';
import 'package:med_super/core/theme/color_schemes.dart';
import 'package:med_super/core/widgets/app_badge.dart';
import 'package:med_super/core/widgets/app_nav_icons.dart';
import 'package:med_super/core/widgets/app_text_field.dart';
import 'package:med_super/core/widgets/async_value_view.dart';
import 'package:med_super/core/widgets/empty_state.dart';
import 'package:med_super/features/auth/presentation/controllers/session_provider.dart';
import 'package:med_super/features/provider_dashboard/domain/entities/doctor_clinic.dart';
import 'package:med_super/features/provider_dashboard/presentation/controllers/provider_dashboard_providers.dart';
import 'package:med_super/features/provider_dashboard/presentation/controllers/provider_failure_message.dart';
import 'package:med_super/features/provider_dashboard/presentation/widgets/add_clinic_branch_sheet.dart';
import 'package:solar_icons/solar_icons.dart';

/// The doctor's clinics and branches, backed by `GET /v1/doctors/me/clinics`
/// (File 12 Part 49.2).
///
/// Renders as a plain list — one row per branch (name + status), tapping a
/// row opens the full edit form in a modal sheet ([_ClinicBranchEditSheet]).
/// Operational fields and the consultation fee are doctor-editable; only
/// verification/legal status stays Admin-owned.
class ProviderClinicSettingsScreen extends ConsumerWidget {
  const ProviderClinicSettingsScreen({super.key});

  Future<void> _addBranch(
    BuildContext context,
    WidgetRef ref,
    List<DoctorClinic> clinics,
  ) async {
    if (clinics.isEmpty) return;
    final draft = await showAddClinicBranchSheet(
      context,
      clinicId: clinics.first.clinicId,
      clinicName: clinics.first.clinicName,
      defaultCurrency: clinics.first.currency,
    );
    if (draft == null || !context.mounted) return;

    final result = await ref
        .read(createMyClinicBranchUseCaseProvider)
        .call(
          clinicId: draft.clinicId,
          phone: draft.phone,
          ianaTimezone: draft.ianaTimezone,
          addressLine1: draft.addressLine1,
          addressCity: draft.addressCity,
          regionCode: draft.regionCode,
          countryCode: draft.countryCode,
          consultFee: draft.consultFee,
        );
    if (!context.mounted) return;

    result.when(
      ok: (_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('provider_dashboard.clinics.branch_added'.tr()),
            backgroundColor: const Color(0xFF10B981),
          ),
        );
        ref.invalidate(myClinicsProvider);
      },
      err: (failure) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(providerFailureMessage(failure))),
      ),
    );
  }

  void _openBranch(BuildContext context, DoctorClinic clinic, {required bool isAssistant}) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      // A calmer, slightly slower slide-up than the modal-sheet default,
      // which otherwise feels abrupt for a form the doctor is about to
      // read carefully rather than dismiss quickly.
      transitionAnimationController: AnimationController(
        vsync: Navigator.of(context),
        duration: const Duration(milliseconds: 320),
        reverseDuration: const Duration(milliseconds: 220),
      ),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: _ClinicBranchEditSheet(clinic: clinic, isAssistant: isAssistant),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(myClinicsProvider);
    final session = ref.watch(sessionControllerProvider).asData?.value;
    // Assistants can edit a branch's operational details but cannot add a
    // new branch or delete one — those stay doctor-only per the doctor's
    // ownership of the clinic relationship, an assistant only manages the
    // branches they're already assigned to.
    final isAssistant = session?.user.isAssistant ?? false;

    return Scaffold(
      backgroundColor: AppColors.surfaceApp,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: AppColors.ink900,
        elevation: 0,
        // A doctor can be affiliated with several clinics, each with several
        // branches (`doctor_clinic_affiliations` only unique-constrains on
        // `[doctor_id, clinic_branch_id]` — no cap on distinct clinics). If
        // every branch belongs to the same clinic, name it directly; with
        // more than one, naming just the first would be misleading, so this
        // falls back to the generic "My clinics" title.
        title: Text(
          async.maybeWhen(
            data: (clinics) {
              if (clinics.isEmpty) return 'provider_dashboard.clinics.title'.tr();
              final distinctClinicIds = clinics.map((c) => c.clinicId).toSet();
              return distinctClinicIds.length == 1
                  ? clinics.first.clinicName
                  : 'provider_dashboard.clinics.title'.tr();
            },
            orElse: () => 'provider_dashboard.clinics.title'.tr(),
          ),
        ),
      ),
      floatingActionButton: isAssistant
          ? null
          : async.maybeWhen(
              data: (clinics) => clinics.isEmpty
                  ? null
                  : FloatingActionButton.extended(
                      heroTag: 'provider_clinics_fab',
                      backgroundColor: brandBlue,
                      foregroundColor: Colors.white,
                      shape: const StadiumBorder(),
                      onPressed: () => _addBranch(context, ref, clinics),
                      icon: const Icon(SolarIconsOutline.addCircle),
                      label: Text('provider_dashboard.clinics.add_branch'.tr()),
                    ),
              orElse: () => null,
            ),
      body: AsyncValueView<List<DoctorClinic>>(
        value: async,
        onRetry: () => ref.invalidate(myClinicsProvider),
        data: (clinics) {
          if (clinics.isEmpty) {
            return EmptyState(
              title: 'provider_dashboard.clinics.empty_title'.tr(),
              subtitle: 'provider_dashboard.clinics.empty_subtitle'.tr(),
              icon: SolarIconsOutline.hospital,
            );
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(myClinicsProvider),
            child: ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: clinics.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) =>
                  _ClinicBranchListTile(
                    clinic: clinics[index],
                    onTap: () => _openBranch(context, clinics[index], isAssistant: isAssistant),
                  ),
            ),
          );
        },
      ),
    );
  }
}

/// One row in the clinics list. Branches have no name of their own in the
/// data model, only an address, so the title is the branch's city — the
/// clinic name (shared by every branch of the same clinic, so not
/// distinguishing on its own) moves to the subtitle along with the street
/// address and phone. Tapping the row opens the full edit form.
class _ClinicBranchListTile extends StatelessWidget {
  const _ClinicBranchListTile({required this.clinic, required this.onTap});

  final DoctorClinic clinic;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (clinic.affiliationStatus) {
      AffiliationStatus.active => (
        'provider_dashboard.clinics.affiliation_active'.tr(),
        const Color(0xFF10B981),
      ),
      _ => ('provider_dashboard.clinics.affiliation_paused'.tr(), Colors.orange),
    };

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(AppRadii.xl),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadii.xl),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadii.xl),
            boxShadow: AppShadows.resting,
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      clinic.address.city,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: AppColors.ink900,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      clinic.address.line1,
                      style: const TextStyle(fontSize: 12, color: AppColors.mutedText2),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              AppBadge.soft(label: label, color: color),
              const SizedBox(width: 4),
              Icon(AppNavIcons.chevronForward(context), color: AppColors.mutedText2),
            ],
          ),
        ),
      ),
    );
  }
}

/// The full edit form for one branch, opened as a modal sheet from
/// [_ClinicBranchListTile]. Save stays disabled until a field actually
/// changes, so a tap-in-tap-out never fires a needless request.
class _ClinicBranchEditSheet extends ConsumerStatefulWidget {
  const _ClinicBranchEditSheet({required this.clinic, required this.isAssistant});

  final DoctorClinic clinic;

  /// An assistant can edit a branch's operational details (phone, address,
  /// timezone) but not its commercial/ownership-level fields: the consult
  /// fee, pausing/resuming the affiliation, or deleting the branch — all
  /// three stay doctor-only both here (hidden/disabled) and on the backend
  /// (`PATCH .../clinics/affiliations/:id` and the delete route are
  /// `@Roles(DOCTOR)`-only, so these would 403 for an assistant regardless).
  final bool isAssistant;

  @override
  ConsumerState<_ClinicBranchEditSheet> createState() =>
      _ClinicBranchEditSheetState();
}

class _ClinicBranchEditSheetState extends ConsumerState<_ClinicBranchEditSheet> {
  late final TextEditingController _phone;
  late final TextEditingController _timezone;
  late final TextEditingController _line1;
  late final TextEditingController _city;
  late final TextEditingController _consultFee;
  final _formKey = GlobalKey<FormState>();

  bool _saving = false;
  bool _isDirty = false;

  @override
  void initState() {
    super.initState();
    _phone = TextEditingController(text: _toLocalEgyptPhone(widget.clinic.phone));
    _timezone = TextEditingController(text: widget.clinic.ianaTimezone);
    _line1 = TextEditingController(text: widget.clinic.address.line1);
    _city = TextEditingController(text: widget.clinic.address.city);
    _consultFee = TextEditingController(text: widget.clinic.consultFee);
    for (final controller in [_phone, _timezone, _line1, _city, _consultFee]) {
      controller.addListener(_recomputeDirty);
    }
  }

  @override
  void dispose() {
    _phone.dispose();
    _timezone.dispose();
    _line1.dispose();
    _city.dispose();
    _consultFee.dispose();
    super.dispose();
  }

  void _recomputeDirty() {
    final dirty =
        _changedFields.values.any((v) => v != null) ||
        (!widget.isAssistant && _changedConsultFee != null);
    if (dirty != _isDirty) setState(() => _isDirty = dirty);
  }

  /// Only actually-changed fields are sent, so a save never rewrites a field
  /// the doctor did not touch (and never bumps a version for nothing).
  Map<String, String?> get _changedFields {
    final clinic = widget.clinic;
    return {
      'phone': _phone.text.trim() == _toLocalEgyptPhone(clinic.phone)
          ? null
          : normalizeEgyptPhone(_phone.text.trim()),
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

  double? get _changedConsultFee {
    final trimmed = _consultFee.text.trim();
    final parsed = double.tryParse(trimmed);
    if (parsed == null) return null;
    final current = double.tryParse(widget.clinic.consultFee);
    if (current != null && (parsed - current).abs() < 0.001) return null;
    return parsed;
  }

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
    if (_saving || !_isDirty || !(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    final changed = _changedFields;
    final changedFee = widget.isAssistant ? null : _changedConsultFee;

    setState(() => _saving = true);

    // Branch operational fields and the affiliation's consult fee live on
    // two different backend resources — send each only if it actually
    // changed, so an unrelated edit never triggers a needless second call.
    var ok = true;
    Failure? lastFailure;

    if (changed.values.any((v) => v != null)) {
      final result = await ref
          .read(updateMyClinicBranchUseCaseProvider)
          .call(
            branchId: widget.clinic.clinicBranchId,
            phone: changed['phone'],
            ianaTimezone: changed['ianaTimezone'],
            addressLine1: changed['line1'],
            addressCity: changed['city'],
          );
      result.when(ok: (_) {}, err: (failure) {
        ok = false;
        lastFailure = failure;
      });
    }

    if (ok && changedFee != null) {
      final result = await ref
          .read(setMyAffiliationActiveUseCaseProvider)
          .call(
            affiliationId: widget.clinic.affiliationId,
            active:
                widget.clinic.affiliationStatus == AffiliationStatus.active,
            consultFee: changedFee,
          );
      result.when(ok: (_) {}, err: (failure) {
        ok = false;
        lastFailure = failure;
      });
    }

    if (!mounted) return;
    setState(() => _saving = false);

    if (ok) {
      _showSnack('provider_dashboard.clinics.saved'.tr(), success: true);
      // Refetch rather than trusting the local copy — the response is the
      // server's own view of the row after the write.
      ref.invalidate(myClinicsProvider);
      Navigator.of(context).pop();
    } else if (lastFailure != null) {
      _showSnack(providerFailureMessage(lastFailure!));
    }
  }

  Future<void> _delete() async {
    if (_saving) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('provider_dashboard.clinics.delete_title'.tr()),
        content: Text('provider_dashboard.clinics.delete_message'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text('provider_dashboard.cancel.keep'.tr()),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.errorRed),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text('provider_dashboard.clinics.delete'.tr()),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _saving = true);
    final result = await ref
        .read(deleteMyClinicBranchUseCaseProvider)
        .call(branchId: widget.clinic.clinicBranchId);
    if (!mounted) return;
    setState(() => _saving = false);

    result.when(
      ok: (_) {
        _showSnack('provider_dashboard.clinics.deleted'.tr(), success: true);
        ref.invalidate(myClinicsProvider);
        Navigator.of(context).pop();
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

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          clinic.displayAddressLine,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: AppColors.ink900,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          clinic.displayTitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12, color: AppColors.mutedText2),
                        ),
                      ],
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
                          '${'provider_dashboard.clinics.consult_fee'.tr()} (${clinic.currency})',
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      textDirection: ui.TextDirection.ltr,
                      textAlign: TextAlign.left,
                      // Consult fee is doctor-only (commercial term of the
                      // affiliation, not a branch operational field) — an
                      // assistant sees it for context but cannot change it.
                      readOnly: widget.isAssistant,
                      validator: widget.isAssistant
                          ? null
                          : (value) {
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
                'provider_dashboard.clinics.verification_admin_note'.tr(),
                style: const TextStyle(fontSize: 11, color: AppColors.mutedText2),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 52,
                      child: ElevatedButton(
                        onPressed: (_saving || !_isDirty) ? null : _save,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: brandBlue,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: const Color(0xFFE2E8F0),
                          elevation: 0,
                          shape: const StadiumBorder(),
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
                            : Text(
                                'provider_dashboard.clinics.save'.tr(),
                                style: const TextStyle(fontWeight: FontWeight.w700),
                              ),
                      ),
                    ),
                  ),
                  // Pause/Resume changes the affiliation's commercial status —
                  // doctor-only, same as the consult fee (backend
                  // `PATCH .../clinics/affiliations/:id` is `@Roles(DOCTOR)`).
                  if (!widget.isAssistant) ...[
                    const SizedBox(width: 12),
                    Expanded(
                      child: SizedBox(
                        height: 52,
                        child: OutlinedButton(
                          onPressed: _saving ? null : _togglePaused,
                          style: const ButtonStyle(
                            shape: WidgetStatePropertyAll(StadiumBorder()),
                          ),
                          child: Text(
                            isActive
                                ? 'provider_dashboard.clinics.pause'.tr()
                                : 'provider_dashboard.clinics.resume'.tr(),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              if (!widget.isAssistant) ...[
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: OutlinedButton.icon(
                    onPressed: _saving ? null : _delete,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.errorRed,
                      side: const BorderSide(color: AppColors.errorRed),
                      shape: const StadiumBorder(),
                    ),
                    icon: const Icon(SolarIconsOutline.trashBinTrash, size: 18),
                    label: Text('provider_dashboard.clinics.delete'.tr()),
                  ),
                ),
              ],
            ],
          ),
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
    return AppBadge.soft(label: label, color: color);
  }

  Widget _notice(String text) => Container(
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
      color: const Color(0xFFFFF7ED),
      borderRadius: BorderRadius.circular(AppRadii.md),
    ),
    child: Row(
      children: [
        const Icon(SolarIconsOutline.infoCircle, size: 16, color: Colors.orange),
        const SizedBox(width: 8),
        Expanded(child: Text(text, style: const TextStyle(fontSize: 12))),
      ],
    ),
  );
}

/// Displays a stored `+20…` E.164 phone as the local `01…` form the doctor
/// expects to see and re-type.
String _toLocalEgyptPhone(String e164) {
  final digits = e164.replaceAll(RegExp(r'\D'), '');
  if (digits.startsWith('20') && digits.length >= 12) {
    return '0${digits.substring(2)}';
  }
  return e164;
}

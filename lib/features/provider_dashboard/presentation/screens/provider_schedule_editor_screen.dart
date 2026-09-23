import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:med_super/core/theme/app_colors.dart';
import 'package:med_super/core/theme/app_radii.dart';
import 'package:med_super/core/theme/app_shadows.dart';
import 'package:med_super/core/theme/color_schemes.dart';
import 'package:med_super/core/widgets/app_badge.dart';
import 'package:med_super/core/widgets/async_value_view.dart';
import 'package:med_super/core/widgets/empty_state.dart';
import 'package:solar_icons/solar_icons.dart';
import 'package:med_super/features/provider_dashboard/domain/entities/doctor_clinic.dart';
import 'package:med_super/features/provider_dashboard/domain/entities/doctor_schedule_template.dart';
import 'package:med_super/features/provider_dashboard/presentation/controllers/provider_dashboard_providers.dart';
import 'package:med_super/features/provider_dashboard/presentation/controllers/provider_failure_message.dart';
import 'package:med_super/features/provider_dashboard/presentation/widgets/branch_tab.dart';
import 'package:med_super/features/provider_dashboard/presentation/widgets/schedule_template_editor_sheet.dart';

/// The doctor's weekly availability, backed by
/// `/v1/doctors/me/schedule-templates` (File 12 Part 49.5).
///
/// Replaces the previous mock-only day toggles. Three real differences the
/// old UI could not express: a template belongs to one **branch**, it carries
/// a slot length and a buffer, and its times are local to that branch's
/// timezone. All three are now visible and editable.
///
/// Branch tabs mirror the Home screen's `_BranchTimelineTabs` convention
/// (an "All" tab plus one tab per branch, city as title / street as
/// subtitle) — only shown when the caller has more than one branch, so a
/// single-branch doctor or assistant sees a plain list with no redundant
/// tab bar.
///
/// Changes affect **future** slot generation only — the banner says so,
/// because a doctor deleting Monday hours must not believe Monday's already
/// booked appointments just vanished. They did not.
class ProviderScheduleEditorScreen extends ConsumerStatefulWidget {
  const ProviderScheduleEditorScreen({super.key});

  @override
  ConsumerState<ProviderScheduleEditorScreen> createState() =>
      _ProviderScheduleEditorScreenState();
}

class _ProviderScheduleEditorScreenState
    extends ConsumerState<ProviderScheduleEditorScreen>
    with TickerProviderStateMixin {
  TabController? _tabController;
  List<String> _tabAffiliationIds = const [];

  bool get _showAllTab => _tabAffiliationIds.length > 1;

  void _syncTabController(List<DoctorClinic> clinics) {
    final affiliationIds = clinics.map((c) => c.affiliationId).toList();
    if (listEquals(affiliationIds, _tabAffiliationIds)) return;

    _tabAffiliationIds = affiliationIds;
    final length = affiliationIds.length + (affiliationIds.length > 1 ? 1 : 0);
    _tabController?.dispose();
    _tabController = length > 1 ? TabController(length: length, vsync: this) : null;
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  void _showSnack(BuildContext context, String message, {bool success = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: success ? const Color(0xFF10B981) : null,
      ),
    );
  }

  Future<void> _create(BuildContext context, WidgetRef ref, List<DoctorClinic> clinics) async {
    if (clinics.isEmpty) return;
    final draft = await showScheduleTemplateEditor(context, clinics: clinics);
    if (draft == null || !context.mounted) return;

    final result = await ref
        .read(createMyScheduleTemplateUseCaseProvider)
        .call(
          NewDoctorScheduleTemplate(
            doctorClinicAffiliationId: draft.affiliationId,
            weekday: draft.weekday,
            startTime: draft.startTime,
            endTime: draft.endTime,
            slotDurationMinutes: draft.slotDurationMinutes,
            bufferMinutes: draft.bufferMinutes,
          ),
        );
    if (!context.mounted) return;

    result.when(
      ok: (_) {
        _showSnack(context, 'provider_dashboard.schedule.created'.tr(), success: true);
        ref.invalidate(myScheduleTemplatesProvider);
      },
      err: (failure) => _showSnack(context, providerFailureMessage(failure)),
    );
  }

  Future<void> _edit(
    BuildContext context,
    WidgetRef ref,
    List<DoctorClinic> clinics,
    DoctorScheduleTemplate template,
  ) async {
    final draft = await showScheduleTemplateEditor(
      context,
      clinics: clinics,
      existing: template,
    );
    if (draft == null || !context.mounted) return;

    final result = await ref
        .read(updateMyScheduleTemplateUseCaseProvider)
        .call(
          templateId: template.id,
          patch: DoctorScheduleTemplatePatch(
            weekday: draft.weekday,
            startTime: draft.startTime,
            endTime: draft.endTime,
            slotDurationMinutes: draft.slotDurationMinutes,
            bufferMinutes: draft.bufferMinutes,
            // Round-tripping the version is what turns a concurrent edit into
            // a 409 instead of a silent overwrite (File 12 Part 49.6).
            version: template.version,
          ),
        );
    if (!context.mounted) return;

    result.when(
      ok: (_) {
        _showSnack(context, 'provider_dashboard.schedule.updated'.tr(), success: true);
        ref.invalidate(myScheduleTemplatesProvider);
      },
      err: (failure) {
        _showSnack(context, providerFailureMessage(failure));
        // On a 409 our copy is stale; refetch so the next attempt carries the
        // current version rather than repeating the same losing one.
        ref.invalidate(myScheduleTemplatesProvider);
      },
    );
  }

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    DoctorScheduleTemplate template,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('provider_dashboard.schedule.delete_title'.tr()),
        content: Text('provider_dashboard.schedule.delete_message'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text('provider_dashboard.cancel.keep'.tr()),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.errorRed),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text('provider_dashboard.schedule.delete'.tr()),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    final result = await ref
        .read(deleteMyScheduleTemplateUseCaseProvider)
        .call(templateId: template.id, version: template.version);
    if (!context.mounted) return;

    result.when(
      ok: (_) {
        _showSnack(context, 'provider_dashboard.schedule.deleted'.tr(), success: true);
        ref.invalidate(myScheduleTemplatesProvider);
      },
      err: (failure) {
        _showSnack(context, providerFailureMessage(failure));
        ref.invalidate(myScheduleTemplatesProvider);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final templatesAsync = ref.watch(myScheduleTemplatesProvider());
    final clinics = ref
        .watch(myClinicsProvider)
        .maybeWhen(data: (list) => list, orElse: () => const <DoctorClinic>[]);
    _syncTabController(clinics);
    final tabController = _tabController;

    return Scaffold(
      backgroundColor: AppColors.surfaceApp,
      appBar: AppBar(
        title: Text('provider_dashboard.schedule.title'.tr()),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.ink900,
        elevation: 0,
        bottom: tabController == null
            ? null
            : TabBar(
                controller: tabController,
                isScrollable: true,
                tabs: [
                  if (_showAllTab) Tab(text: 'provider_dashboard.home.tab_all'.tr()),
                  for (final clinic in clinics) BranchTab(branch: clinic),
                ],
              ),
      ),
      floatingActionButton: clinics.isEmpty
          ? null
          : FloatingActionButton.extended(
              heroTag: 'provider_schedule_fab',
              backgroundColor: brandBlue,
              foregroundColor: Colors.white,
              onPressed: () => _create(context, ref, clinics),
              shape: const StadiumBorder(),
              icon: const Icon(SolarIconsOutline.addCircle),
              label: Text('provider_dashboard.schedule.add'.tr()),
            ),
      body: AsyncValueView<List<DoctorScheduleTemplate>>(
        value: templatesAsync,
        onRetry: () => ref.invalidate(myScheduleTemplatesProvider),
        data: (templates) {
          if (templates.isEmpty) {
            return EmptyState(
              title: 'provider_dashboard.schedule.empty_title'.tr(),
              subtitle: 'provider_dashboard.schedule.empty_subtitle'.tr(),
              icon: SolarIconsOutline.calendarMinimalistic,
            );
          }

          if (tabController == null) {
            return _templateList(context, templates, clinics);
          }

          return TabBarView(
            controller: tabController,
            children: [
              if (_showAllTab) _templateList(context, templates, clinics),
              for (final clinic in clinics)
                _templateList(
                  context,
                  templates.where((t) => t.doctorClinicAffiliationId == clinic.affiliationId).toList(),
                  clinics,
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _templateList(
    BuildContext context,
    List<DoctorScheduleTemplate> templates,
    List<DoctorClinic> clinics,
  ) {
    if (templates.isEmpty) {
      return EmptyState(
        title: 'provider_dashboard.schedule.empty_title'.tr(),
        subtitle: 'provider_dashboard.schedule.empty_subtitle'.tr(),
        icon: SolarIconsOutline.calendarMinimalistic,
      );
    }

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(myScheduleTemplatesProvider),
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _notRetroactiveBanner(),
          const SizedBox(height: 16),
          for (final template in templates)
            _templateCard(
              context,
              template,
              onEdit: () => _edit(context, ref, clinics, template),
              onDelete: () => _delete(context, ref, template),
            ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _notRetroactiveBanner() => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: const Color(0xFFEFF6FF),
      borderRadius: BorderRadius.circular(AppRadii.md),
    ),
    child: Row(
      children: [
        const Icon(SolarIconsOutline.infoCircle, size: 18, color: brandBlue),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            'provider_dashboard.schedule.not_retroactive_note'.tr(),
            style: const TextStyle(fontSize: 12, color: AppColors.ink900),
          ),
        ),
      ],
    ),
  );

  Widget _templateCard(
    BuildContext context,
    DoctorScheduleTemplate template, {
    required VoidCallback onEdit,
    required VoidCallback onDelete,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadii.xl),
        boxShadow: AppShadows.resting,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'provider_dashboard.weekday.${template.weekday}'.tr(),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: AppColors.ink900,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(SolarIconsOutline.pen, size: 20),
                color: AppColors.mutedText,
                tooltip: 'common.edit'.tr(),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                onPressed: onEdit,
              ),
              IconButton(
                icon: const Icon(
                  SolarIconsOutline.trashBinTrash,
                  size: 20,
                  color: AppColors.errorRed,
                ),
                tooltip: 'common.delete'.tr(),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                onPressed: onDelete,
              ),
            ],
          ),
          Text(
            '${template.startTime} — ${template.endTime}',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.ink900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${template.clinicName} · ${'provider_dashboard.schedule.times_local_note'.tr(args: [template.ianaTimezone])}',
            style: const TextStyle(fontSize: 12, color: AppColors.mutedText2),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              AppBadge.soft(
                label:
                    '${'provider_dashboard.schedule.slot_duration'.tr()}: ${template.slotDurationMinutes}',
                color: AppColors.mutedText2,
              ),
              AppBadge.soft(
                label:
                    '${'provider_dashboard.schedule.buffer'.tr()}: ${template.bufferMinutes}',
                color: AppColors.mutedText2,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

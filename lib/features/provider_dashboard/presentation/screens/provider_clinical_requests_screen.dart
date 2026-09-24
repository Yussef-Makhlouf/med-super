import 'dart:ui' as ui;

import 'package:easy_localization/easy_localization.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:med_super/core/theme/app_colors.dart';
import 'package:med_super/core/theme/app_radii.dart';
import 'package:med_super/core/widgets/async_value_view.dart';
import 'package:med_super/core/widgets/empty_state.dart';
import 'package:med_super/features/auth/presentation/controllers/session_provider.dart';
import 'package:med_super/features/lab_booking/domain/entities/lab_branch.dart';
import 'package:med_super/features/lab_booking/domain/entities/lab_order_detail.dart';
import 'package:med_super/features/lab_booking/presentation/controllers/lab_branch_search_providers.dart';
import 'package:med_super/features/lab_booking/presentation/widgets/lab_order_status_pill.dart';
import 'package:med_super/features/pharmacy_booking/presentation/controllers/pharmacy_search_providers.dart';
import 'package:med_super/features/pharmacy_booking/domain/entities/pharmacy.dart';
import 'package:med_super/features/pharmacy_booking/domain/entities/pharmacy_order_detail.dart';
import 'package:med_super/features/pharmacy_booking/domain/entities/prescription_image.dart';
import 'package:med_super/features/provider_dashboard/domain/entities/provider_clinical_request.dart';
import 'package:med_super/features/provider_dashboard/presentation/controllers/provider_clinical_request_providers.dart';
import 'package:med_super/features/provider_dashboard/presentation/controllers/provider_dashboard_providers.dart';

class ProviderClinicalRequestsScreen extends ConsumerWidget {
  const ProviderClinicalRequestsScreen({
    required this.patientId,
    required this.patientName,
    this.appointmentId,
    super.key,
  });

  final String patientId;
  final String patientName;
  final String? appointmentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) => DefaultTabController(
    length: 2,
    child: Scaffold(
      backgroundColor: AppColors.surfaceApp,
      appBar: AppBar(
        title: Text('provider_dashboard.clinical_requests.title'.tr()),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.ink900,
        bottom: TabBar(
          tabs: [
            Tab(
              text: 'provider_dashboard.clinical_requests.prescriptions'.tr(),
            ),
            Tab(text: 'provider_dashboard.clinical_requests.labs'.tr()),
          ],
        ),
      ),
      body: TabBarView(
        children: [
          _PrescriptionHistory(
            patientId: patientId,
            patientName: patientName,
            appointmentId: appointmentId,
          ),
          _LabHistory(
            patientId: patientId,
            patientName: patientName,
            appointmentId: appointmentId,
          ),
        ],
      ),
    ),
  );
}

class _PrescriptionHistory extends ConsumerWidget {
  const _PrescriptionHistory({
    required this.patientId,
    required this.patientName,
    this.appointmentId,
  });
  final String patientId;
  final String patientName;
  final String? appointmentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(sessionControllerProvider).asData?.value?.user;
    final isDoctor = user?.isDoctor ?? false;
    final canCreate = user?.isDoctor == true || user?.isAssistant == true;
    final async = ref.watch(providerPrescriptionsProvider);
    final pharmacyOrders =
        ref.watch(providerPharmacyOrdersProvider).asData?.value ??
        const <PharmacyOrderDetail>[];
    return Column(
      children: [
        if (canCreate)
          _CreateAction(
            label: 'provider_dashboard.clinical_requests.create_prescription'
                .tr(),
            onPressed: () async {
              final values = await showModalBottomSheet<_PrescriptionDraft>(
                context: context,
                isScrollControlled: true,
                builder: (_) => _PrescriptionForm(
                  patientName: patientName,
                  collectPharmacySubmission: isDoctor,
                ),
              );
              if (values == null || !context.mounted) return;
              try {
                final result = await ref
                    .read(providerClinicalUseCasesProvider)
                    .uploadClinicalDocument(
                      patientId: patientId,
                      appointmentId: appointmentId,
                      documentType: 'PRESCRIPTION',
                      images: values.images,
                      notes: values.notes,
                    );
                if (!context.mounted) return;
                ref.invalidate(providerPrescriptionsProvider);
                if (values.pharmacySubmission != null &&
                    result.status == 'ACCEPTED') {
                  try {
                    await ref
                        .read(providerClinicalUseCasesProvider)
                        .createPharmacyOrder(
                          patientId: patientId,
                          prescriptionId: result.prescriptionId,
                          fulfillmentType:
                              values.pharmacySubmission!.fulfillment,
                          pharmacyBranchId:
                              values.pharmacySubmission!.branchId,
                        );
                    ref.invalidate(providerPharmacyOrdersProvider);
                    if (context.mounted) {
                      _snack(
                        context,
                        'provider_dashboard.clinical_requests.pharmacy_sent'
                            .tr(),
                        success: true,
                      );
                    }
                    return;
                  } catch (_) {
                    if (context.mounted) {
                      _snack(
                        context,
                        'provider_dashboard.clinical_requests.prescription_saved_order_not_sent'
                            .tr(),
                      );
                    }
                    return;
                  }
                }
                final message = result.status == 'PENDING_DOCTOR_APPROVAL'
                    ? 'provider_dashboard.clinical_requests.submitted_for_approval'
                          .tr()
                    : 'provider_dashboard.clinical_requests.created'.tr();
                _snack(context, message, success: true);
              } catch (error) {
                if (!context.mounted) return;
                _snack(context, _requestFailureMessage(error));
              }
            },
          ),
        if (canCreate)
          _BatchAction(
            type: _BatchRequestType.prescription,
            initialPatientId: patientId,
          ),
        Expanded(
          child: AsyncValueView<List<ProviderPrescription>>(
            value: async,
            onRetry: () => ref.invalidate(providerPrescriptionsProvider),
            data: (all) {
              final records = all
                  .where((r) => r.patientId == patientId)
                  .toList(growable: false);
              if (records.isEmpty) {
                return EmptyState(
                  title:
                      'provider_dashboard.clinical_requests.empty_prescriptions'
                          .tr(),
                  icon: Icons.medication_outlined,
                );
              }
              return RefreshIndicator(
                onRefresh: () async =>
                    ref.invalidate(providerPrescriptionsProvider),
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                  itemCount: records.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) => _PrescriptionCard(
                    record: records[index],
                    patientId: patientId,
                    canApprove: isDoctor,
                    pharmacyOrders: pharmacyOrders
                        .where(
                          (order) =>
                              order.patientId == patientId &&
                              order.prescriptionId == records[index].id,
                        )
                        .toList(growable: false),
                    onRefresh: () =>
                        ref.invalidate(providerPrescriptionsProvider),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _PrescriptionCard extends ConsumerWidget {
  const _PrescriptionCard({
    required this.record,
    required this.patientId,
    required this.canApprove,
    required this.pharmacyOrders,
    required this.onRefresh,
  });
  final ProviderPrescription record;
  final String patientId;
  final bool canApprove;
  final List<PharmacyOrderDetail> pharmacyOrders;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fullRecord =
        ref
            .watch(providerPrescriptionDetailProvider(record.id))
            .asData
            ?.value ??
        record;
    final label = switch (record.status) {
      'PENDING_DOCTOR_APPROVAL' =>
        'provider_dashboard.clinical_requests.status_pending_approval'.tr(),
      'ACCEPTED' => 'provider_dashboard.clinical_requests.status_active'.tr(),
      'REJECTED' => 'provider_dashboard.clinical_requests.status_rejected'.tr(),
      'QUALITY_CHECK_PASSED' =>
        'provider_dashboard.clinical_requests.status_pharmacy_review'.tr(),
      _ => record.status,
    };
    return Card(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.lg),
        side: const BorderSide(color: AppColors.borderLight),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    _prescriptionTitle(fullRecord),
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      color: AppColors.ink900,
                    ),
                  ),
                ),
                Chip(label: Text(label), visualDensity: VisualDensity.compact),
              ],
            ),
            if (fullRecord.notes?.isNotEmpty ?? false)
              Text(
                fullRecord.notes!,
                style: const TextStyle(color: AppColors.mutedText2),
              ),
            if (fullRecord.images.isNotEmpty) ...[
              const SizedBox(height: 8),
              _RequestImagesRow(
                urls: fullRecord.images.map((image) => image.url).toList(),
              ),
            ],
            if (fullRecord.rejectionReason?.isNotEmpty ?? false)
              Text(
                fullRecord.rejectionReason!,
                style: const TextStyle(color: AppColors.errorRed),
              ),
            if (record.createdAt != null)
              Text(
                DateFormat.yMMMd().add_jm().format(record.createdAt!.toLocal()),
                style: const TextStyle(
                  color: AppColors.mutedText2,
                  fontSize: 12,
                ),
              ),
            for (final order in pharmacyOrders)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: _PharmacyOrderProgressCard(order: order),
              ),
            if (canApprove && record.pendingApproval) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _decide(context, ref, approve: false),
                      child: Text(
                        'provider_dashboard.clinical_requests.reject'.tr(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _decide(context, ref, approve: true),
                      child: Text(
                        'provider_dashboard.clinical_requests.approve'.tr(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => _approveAndCreatePharmacyOrder(context, ref),
                  icon: const Icon(Icons.local_pharmacy_outlined),
                  label: Text(
                    'provider_dashboard.clinical_requests.approve_and_send'
                        .tr(),
                  ),
                ),
              ),
            ],
            if (canApprove && record.signed && pharmacyOrders.isEmpty)
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: TextButton.icon(
                  onPressed: () => _createPharmacyOrder(context, ref),
                  icon: const Icon(Icons.local_pharmacy_outlined),
                  label: Text(
                    'provider_dashboard.clinical_requests.send_to_pharmacy'
                        .tr(),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _decide(
    BuildContext context,
    WidgetRef ref, {
    required bool approve,
  }) async {
    String? reason;
    if (!approve) {
      reason = await showDialog<String>(
        context: context,
        builder: (context) {
          final controller = TextEditingController();
          return AlertDialog(
            title: Text(
              'provider_dashboard.clinical_requests.reject_title'.tr(),
            ),
            content: TextField(
              controller: controller,
              maxLength: 500,
              decoration: InputDecoration(
                labelText: 'provider_dashboard.clinical_requests.reject_reason'
                    .tr(),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('provider_dashboard.clinical_requests.cancel'.tr()),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, controller.text.trim()),
                child: Text('provider_dashboard.clinical_requests.reject'.tr()),
              ),
            ],
          );
        },
      );
      if (reason == null || reason.trim().isEmpty) return;
    }
    try {
      await ref
          .read(providerClinicalUseCasesProvider)
          .decidePrescription(
            id: record.id,
            version: record.version,
            approve: approve,
            reason: reason,
          );
      ref.invalidate(providerPrescriptionDetailProvider(record.id));
      onRefresh();
      if (context.mounted) {
        _snack(
          context,
          approve
              ? 'provider_dashboard.clinical_requests.approved'.tr()
              : 'provider_dashboard.clinical_requests.rejected'.tr(),
          success: true,
        );
      }
    } catch (error) {
      onRefresh();
      if (context.mounted) {
        _snack(
          context,
          _isConflict(error)
              ? 'provider_dashboard.clinical_requests.conflict'.tr()
              : 'provider_dashboard.clinical_requests.save_error'.tr(),
        );
      }
    }
  }

  Future<void> _createPharmacyOrder(BuildContext context, WidgetRef ref) async {
    late final List<Pharmacy> branches;
    try {
      branches = await ref.read(pharmaciesProvider.future);
    } catch (_) {
      if (context.mounted) {
        _snack(context, 'provider_dashboard.clinical_requests.save_error'.tr());
      }
      return;
    }
    if (!context.mounted) return;
    if (branches.isEmpty) {
      _snack(
        context,
        'provider_dashboard.clinical_requests.no_pharmacies'.tr(),
      );
      return;
    }
    final selection = await showModalBottomSheet<_PharmacySubmission>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => _PharmacySubmissionSheet(
        branches: branches,
        titleKey: 'provider_dashboard.clinical_requests.pharmacy_title',
        actionKey: 'provider_dashboard.clinical_requests.send',
      ),
    );
    if (selection == null) return;
    try {
      await ref
          .read(providerClinicalUseCasesProvider)
          .createPharmacyOrder(
            patientId: patientId,
            prescriptionId: record.id,
            fulfillmentType: selection.fulfillment,
            pharmacyBranchId: selection.branchId,
          );
      if (context.mounted) {
        _snack(
          context,
          'provider_dashboard.clinical_requests.pharmacy_sent'.tr(),
          success: true,
        );
        ref.invalidate(providerPharmacyOrdersProvider);
      }
    } catch (error) {
      if (context.mounted) {
        _snack(
          context,
          _isConflict(error)
              ? 'provider_dashboard.clinical_requests.conflict'.tr()
              : 'provider_dashboard.clinical_requests.save_error'.tr(),
        );
      }
    }
  }

  Future<void> _approveAndCreatePharmacyOrder(
    BuildContext context,
    WidgetRef ref,
  ) async {
    late final List<Pharmacy> branches;
    try {
      branches = await ref.read(pharmaciesProvider.future);
    } catch (_) {
      if (context.mounted) {
        _snack(context, 'provider_dashboard.clinical_requests.save_error'.tr());
      }
      return;
    }
    if (!context.mounted) return;
    if (branches.isEmpty) {
      _snack(context, 'provider_dashboard.clinical_requests.no_pharmacies'.tr());
      return;
    }
    final selection = await showModalBottomSheet<_PharmacySubmission>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => _PharmacySubmissionSheet(
        branches: branches,
        titleKey: 'provider_dashboard.clinical_requests.approve_and_send_title',
        actionKey: 'provider_dashboard.clinical_requests.approve_and_send',
      ),
    );
    if (selection == null) return;

    try {
      await ref
          .read(providerClinicalUseCasesProvider)
          .decidePrescription(
            id: record.id,
            version: record.version,
            approve: true,
          );
      ref.invalidate(providerPrescriptionDetailProvider(record.id));
      onRefresh();
    } catch (error) {
      onRefresh();
      if (context.mounted) {
        _snack(
          context,
          _isConflict(error)
              ? 'provider_dashboard.clinical_requests.conflict'.tr()
              : 'provider_dashboard.clinical_requests.save_error'.tr(),
        );
      }
      return;
    }

    try {
      await ref
          .read(providerClinicalUseCasesProvider)
          .createPharmacyOrder(
            patientId: patientId,
            prescriptionId: record.id,
            fulfillmentType: selection.fulfillment,
            pharmacyBranchId: selection.branchId,
          );
      ref.invalidate(providerPharmacyOrdersProvider);
      if (context.mounted) {
        _snack(
          context,
          'provider_dashboard.clinical_requests.pharmacy_sent'.tr(),
          success: true,
        );
      }
    } catch (_) {
      if (context.mounted) {
        _snack(
          context,
          'provider_dashboard.clinical_requests.approval_saved_order_not_sent'
              .tr(),
        );
      }
    }
  }
}

class _PharmacySubmission {
  const _PharmacySubmission({
    required this.branchId,
    required this.fulfillment,
  });

  final String branchId;
  final String fulfillment;
}

class _PharmacySubmissionSheet extends StatefulWidget {
  const _PharmacySubmissionSheet({
    required this.branches,
    required this.titleKey,
    required this.actionKey,
  });

  final List<Pharmacy> branches;
  final String titleKey;
  final String actionKey;

  @override
  State<_PharmacySubmissionSheet> createState() =>
      _PharmacySubmissionSheetState();
}

class _PharmacySubmissionSheetState extends State<_PharmacySubmissionSheet> {
  String? _branchId;
  String _fulfillment = 'PICKUP';

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        8,
        20,
        MediaQuery.viewInsetsOf(context).bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.titleKey.tr(),
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20),
            ),
            const SizedBox(height: 4),
            Text(
              'provider_dashboard.clinical_requests.pharmacy_form_hint'.tr(),
              style: const TextStyle(color: AppColors.mutedText2),
            ),
            const SizedBox(height: 16),
            _PharmacySubmissionFields(
              branches: widget.branches,
              branchId: _branchId,
              fulfillment: _fulfillment,
              onBranchChanged: (value) => setState(() => _branchId = value),
              onFulfillmentChanged: (value) => setState(() {
                _fulfillment = value;
                _branchId = null;
              }),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _branchId == null
                    ? null
                    : () => Navigator.pop(
                        context,
                        _PharmacySubmission(
                          branchId: _branchId!,
                          fulfillment: _fulfillment,
                        ),
                      ),
                child: Text(widget.actionKey.tr()),
              ),
            ),
            Center(
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('provider_dashboard.clinical_requests.cancel'.tr()),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _PharmacySubmissionFields extends StatelessWidget {
  const _PharmacySubmissionFields({
    required this.branches,
    required this.branchId,
    required this.fulfillment,
    required this.onBranchChanged,
    required this.onFulfillmentChanged,
  });

  final List<Pharmacy> branches;
  final String? branchId;
  final String fulfillment;
  final ValueChanged<String?> onBranchChanged;
  final ValueChanged<String> onFulfillmentChanged;

  @override
  Widget build(BuildContext context) {
    final eligibleBranches = branches
        .where((branch) => fulfillment == 'PICKUP' || branch.deliveryCapable)
        .toList(growable: false);
    final selectedBranchId = eligibleBranches.any(
      (branch) => branch.id == branchId,
    )
        ? branchId
        : null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'provider_dashboard.clinical_requests.fulfillment'.tr(),
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 6),
        ...const ['PICKUP', 'CLINIC_HANDOVER', 'DELIVERY'].map(
          (value) => Card(
            margin: const EdgeInsets.only(bottom: 6),
            elevation: 0,
            color: value == fulfillment
                ? AppColors.tealBg
                : AppColors.surfaceCard,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadii.md),
              side: BorderSide(
                color: value == fulfillment
                    ? AppColors.tealAccent
                    : AppColors.borderLight,
              ),
            ),
            child: RadioListTile<String>(
              value: value,
              groupValue: fulfillment,
              contentPadding: const EdgeInsetsDirectional.fromSTEB(8, 2, 12, 2),
              title: Text(
                'provider_dashboard.clinical_requests.fulfillment_$value'.tr(),
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              onChanged: (selected) {
                if (selected != null) onFulfillmentChanged(selected);
              },
            ),
          ),
        ),
        const SizedBox(height: 10),
        DropdownButtonFormField<String>(
          initialValue: selectedBranchId,
          isExpanded: true,
          decoration: InputDecoration(
            labelText: 'provider_dashboard.clinical_requests.pharmacy_branch'
                .tr(),
          ),
          items: eligibleBranches
              .map(
                (branch) => DropdownMenuItem<String>(
                  value: branch.id,
                  child: Text(
                    '${branch.name} — ${branch.address}',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              )
              .toList(),
          onChanged: onBranchChanged,
        ),
        if (eligibleBranches.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'provider_dashboard.clinical_requests.no_pharmacies'.tr(),
              style: const TextStyle(color: AppColors.errorRed),
            ),
          ),
      ],
    );
  }
}

class _PharmacyOrderProgressCard extends StatelessWidget {
  const _PharmacyOrderProgressCard({required this.order});

  final PharmacyOrderDetail order;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: AppColors.surfaceCard,
      borderRadius: BorderRadius.circular(AppRadii.md),
      border: Border.all(color: AppColors.borderLight),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.local_pharmacy_outlined,
              size: 18,
              color: AppColors.tealAccent,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                'provider_dashboard.clinical_requests.pharmacy_status'.tr(),
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: Chip(
            label: Text(
              'provider_dashboard.clinical_requests.pharmacy_status_${order.status}'
                  .tr(),
            ),
            visualDensity: VisualDensity.compact,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${'provider_dashboard.clinical_requests.fulfillment'.tr()}: ${'provider_dashboard.clinical_requests.fulfillment_${order.fulfillmentType}'.tr()}',
          style: const TextStyle(color: AppColors.mutedText2, fontSize: 12),
        ),
        if (order.quote != null) ...[
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.warningAmberBg,
              borderRadius: BorderRadius.circular(AppRadii.md),
              border: Border.all(color: AppColors.warningAmberBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'provider_dashboard.clinical_requests.price_section'.tr(),
                  style: const TextStyle(
                    color: AppColors.warningAmberText,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'provider_dashboard.clinical_requests.quoted_total'.tr(),
                  style: const TextStyle(color: AppColors.mutedText2),
                ),
                Directionality(
                  textDirection: ui.TextDirection.ltr,
                  child: Text(
                    '${order.quote!.totalPrice} ${order.quote!.currency}',
                    style: const TextStyle(
                      color: AppColors.ink900,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                Text(
                  'provider_dashboard.clinical_requests.price_preparation_hint'
                      .tr(),
                  style: const TextStyle(color: AppColors.warningAmberText),
                ),
                if (order.quote!.note?.isNotEmpty ?? false) ...[
                  const SizedBox(height: 8),
                  Text(
                    'provider_dashboard.clinical_requests.quote_note'.tr(),
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  Text(order.quote!.note!),
                ],
              ],
            ),
          ),
        ],
        const SizedBox(height: 8),
        Text(
          'provider_dashboard.clinical_requests.status_updated_by_pharmacy'
              .tr(),
          style: const TextStyle(color: AppColors.mutedText2, fontSize: 12),
        ),
      ],
    ),
  );
}

class _LabHistory extends ConsumerWidget {
  const _LabHistory({
    required this.patientId,
    required this.patientName,
    this.appointmentId,
  });
  final String patientId;
  final String patientName;
  final String? appointmentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Column(
    children: [
      if ((ref.watch(sessionControllerProvider).asData?.value?.user.isDoctor ??
              false) ||
          (ref
                  .watch(sessionControllerProvider)
                  .asData
                  ?.value
                  ?.user
                  .isAssistant ??
              false))
        _CreateAction(
          label: 'provider_dashboard.clinical_requests.create_lab'.tr(),
          onPressed: () async {
            final created = await showModalBottomSheet<bool>(
              context: context,
              isScrollControlled: true,
              builder: (_) => _LabRequestForm(
                patientId: patientId,
                appointmentId: appointmentId,
              ),
            );
            if (created == true) ref.invalidate(providerLabOrdersProvider);
          },
        ),
      if ((ref.watch(sessionControllerProvider).asData?.value?.user.isDoctor ??
              false) ||
          (ref
                  .watch(sessionControllerProvider)
                  .asData
                  ?.value
                  ?.user
                  .isAssistant ??
              false))
        _BatchAction(type: _BatchRequestType.lab, initialPatientId: patientId),
      Expanded(
        child: AsyncValueView<List<LabOrderDetail>>(
          value: ref.watch(providerLabOrdersProvider),
          onRetry: () => ref.invalidate(providerLabOrdersProvider),
          data: (all) {
            final records = all
                .where((r) => r.patientId == patientId)
                .toList(growable: false);
            if (records.isEmpty) {
              return EmptyState(
                title: 'provider_dashboard.clinical_requests.empty_labs'.tr(),
                icon: Icons.biotech_outlined,
              );
            }
            return RefreshIndicator(
              onRefresh: () async => ref.invalidate(providerLabOrdersProvider),
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                itemCount: records.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (_, i) => _LabCard(order: records[i]),
              ),
            );
          },
        ),
      ),
    ],
  );
}

class _LabCard extends StatelessWidget {
  const _LabCard({required this.order});
  final LabOrderDetail order;
  @override
  Widget build(BuildContext context) => Card(
    color: Colors.white,
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadii.lg),
      side: const BorderSide(color: AppColors.borderLight),
    ),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  order.items.isEmpty
                      ? 'provider_dashboard.clinical_requests.lab_request'.tr()
                      : order.items.map((e) => e.displayName).join(', '),
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
              LabOrderStatusPill(status: order.status),
            ],
          ),
          Text(
            '${'provider_dashboard.clinical_requests.collection'.tr()}: ${order.collectionType == 'HOME_COLLECTION' ? 'provider_dashboard.clinical_requests.home_collection'.tr() : 'provider_dashboard.clinical_requests.branch_visit'.tr()}',
            style: const TextStyle(color: AppColors.mutedText2, fontSize: 12),
          ),
          if (order.requestImages.isNotEmpty) ...[
            const SizedBox(height: 8),
            _RequestImagesRow(
              urls: order.requestImages.map((image) => image.fileUrl).toList(),
            ),
          ],
          if (order.results.isNotEmpty)
            Text(
              'provider_dashboard.clinical_requests.results_count'.tr(
                args: ['${order.results.length}'],
              ),
              style: const TextStyle(color: AppColors.mutedText2, fontSize: 12),
            ),
        ],
      ),
    ),
  );
}

class _RequestImagesRow extends StatelessWidget {
  const _RequestImagesRow({required this.urls});
  final List<String> urls;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 76,
    child: ListView.separated(
      scrollDirection: Axis.horizontal,
      itemCount: urls.length,
      separatorBuilder: (_, _) => const SizedBox(width: 8),
      itemBuilder: (context, index) => InkWell(
        onTap: () => showDialog<void>(
          context: context,
          builder: (context) => Dialog(
            child: InteractiveViewer(
              child: Image.network(urls[index], fit: BoxFit.contain),
            ),
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppRadii.md),
          child: Image.network(
            urls[index],
            width: 76,
            height: 76,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => const SizedBox(
              width: 76,
              height: 76,
              child: Icon(Icons.broken_image_outlined),
            ),
          ),
        ),
      ),
    ),
  );
}

class _PrescriptionDraft {
  const _PrescriptionDraft({
    required this.images,
    required this.notes,
    this.pharmacySubmission,
  });

  final List<PrescriptionImage> images;
  final String? notes;
  final _PharmacySubmission? pharmacySubmission;
}

class _PrescriptionForm extends ConsumerStatefulWidget {
  const _PrescriptionForm({
    required this.patientName,
    required this.collectPharmacySubmission,
  });

  final String patientName;
  final bool collectPharmacySubmission;

  @override
  ConsumerState<_PrescriptionForm> createState() => _PrescriptionFormState();
}

class _PrescriptionFormState extends ConsumerState<_PrescriptionForm> {
  final _notes = TextEditingController();
  List<PrescriptionImage> _images = const [];
  String? _branchId;
  String _fulfillment = 'PICKUP';

  @override
  void dispose() {
    _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final branches = widget.collectPharmacySubmission
        ? ref.watch(pharmaciesProvider)
        : null;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          20,
          20,
          MediaQuery.viewInsetsOf(context).bottom + 20,
        ),
        child: ListView(
          shrinkWrap: true,
          children: [
            Text(
              'provider_dashboard.clinical_requests.create_prescription'.tr(),
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20),
            ),
            Text(
              widget.patientName,
              style: const TextStyle(color: AppColors.mutedText2),
            ),
            const SizedBox(height: 16),
            _ClinicalImagePicker(
              onChanged: (images) => setState(() => _images = images),
            ),
            TextField(
              controller: _notes,
              maxLength: 500,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: 'provider_dashboard.clinical_requests.notes'.tr(),
              ),
            ),
            if (widget.collectPharmacySubmission) ...[
              const SizedBox(height: 8),
              Text(
                'provider_dashboard.clinical_requests.pharmacy_submission_title'
                    .tr(),
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'provider_dashboard.clinical_requests.pharmacy_form_hint'.tr(),
                style: const TextStyle(color: AppColors.mutedText2),
              ),
              const SizedBox(height: 8),
              branches!.when(
                loading: () => const LinearProgressIndicator(),
                error: (_, _) => _RetryPanel(
                  onRetry: () => ref.invalidate(pharmaciesProvider),
                ),
                data: (items) => items.isEmpty
                    ? Text(
                        'provider_dashboard.clinical_requests.no_pharmacies'
                            .tr(),
                        style: const TextStyle(color: AppColors.errorRed),
                      )
                    : _PharmacySubmissionFields(
                        branches: items,
                        branchId: _branchId,
                        fulfillment: _fulfillment,
                        onBranchChanged: (value) =>
                            setState(() => _branchId = value),
                        onFulfillmentChanged: (value) => setState(() {
                          _fulfillment = value;
                          _branchId = null;
                        }),
                      ),
              ),
            ],
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () {
                if (_images.isEmpty) {
                  _snack(
                    context,
                    'provider_dashboard.clinical_requests.image_required'.tr(),
                  );
                  return;
                }
                if (widget.collectPharmacySubmission && _branchId == null) {
                  _snack(
                    context,
                    'provider_dashboard.clinical_requests.branch_required'.tr(),
                  );
                  return;
                }
                Navigator.pop(
                  context,
                  _PrescriptionDraft(
                    images: _images,
                    notes: _notes.text.trim().isEmpty
                        ? null
                        : _notes.text.trim(),
                    pharmacySubmission: widget.collectPharmacySubmission
                        ? _PharmacySubmission(
                            branchId: _branchId!,
                            fulfillment: _fulfillment,
                          )
                        : null,
                  ),
                );
              },
              child: Text(
                (widget.collectPharmacySubmission
                        ? 'provider_dashboard.clinical_requests.submit_and_send'
                        : 'provider_dashboard.clinical_requests.submit')
                    .tr(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ClinicalImagePicker extends StatefulWidget {
  const _ClinicalImagePicker({required this.onChanged, super.key});
  final ValueChanged<List<PrescriptionImage>> onChanged;

  @override
  State<_ClinicalImagePicker> createState() => _ClinicalImagePickerState();
}

class _ClinicalImagePickerState extends State<_ClinicalImagePicker> {
  static const _maxImages = 5;
  final List<PrescriptionImage> _images = [];

  Future<void> _pickImages() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: true,
      withData: true,
    );
    if (!mounted || result == null) return;
    for (final file in result.files) {
      if (_images.length >= _maxImages) break;
      if (file.bytes == null) continue;
      _images.add(
        PrescriptionImage(
          id: '${DateTime.now().microsecondsSinceEpoch}-${file.name}',
          path: file.name,
          bytes: file.bytes,
        ),
      );
    }
    setState(() {});
    widget.onChanged(List.unmodifiable(_images));
  }

  void _remove(PrescriptionImage image) {
    setState(() => _images.removeWhere((item) => item.id == image.id));
    widget.onChanged(List.unmodifiable(_images));
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      OutlinedButton.icon(
        onPressed: _images.length >= _maxImages ? null : _pickImages,
        icon: const Icon(Icons.add_a_photo_outlined),
        label: Text('provider_dashboard.clinical_requests.attach_images'.tr()),
      ),
      if (_images.isNotEmpty)
        SizedBox(
          height: 92,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _images.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (_, index) {
              final image = _images[index];
              return Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadii.md),
                    child: Image.memory(
                      image.bytes!,
                      width: 84,
                      height: 84,
                      fit: BoxFit.cover,
                    ),
                  ),
                  PositionedDirectional(
                    top: 2,
                    end: 2,
                    child: IconButton.filledTonal(
                      visualDensity: VisualDensity.compact,
                      onPressed: () => _remove(image),
                      icon: const Icon(Icons.close, size: 16),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      const SizedBox(height: 8),
    ],
  );
}

class _LabRequestForm extends ConsumerStatefulWidget {
  const _LabRequestForm({required this.patientId, this.appointmentId});
  final String patientId;
  final String? appointmentId;
  @override
  ConsumerState<_LabRequestForm> createState() => _LabRequestFormState();
}

class _LabRequestFormState extends ConsumerState<_LabRequestForm> {
  final _notes = TextEditingController();
  List<PrescriptionImage> _images = const [];
  String? _branchId;
  String _collectionType = 'VISIT';
  bool _saving = false;
  String? _submitError;
  @override
  void dispose() {
    _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final labs = ref.watch(labBranchesProvider);
    final canSubmit = !_saving && _branchId != null && _images.isNotEmpty;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          20,
          20,
          MediaQuery.viewInsetsOf(context).bottom + 20,
        ),
        child: ListView(
          shrinkWrap: true,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.biotech_outlined,
                  color: AppColors.tealAccent,
                ),
                const SizedBox(width: 8),
                Text(
                  'provider_dashboard.clinical_requests.create_lab'.tr(),
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 20,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.tealBg,
                borderRadius: BorderRadius.circular(AppRadii.md),
              ),
              child: Text(
                'provider_dashboard.clinical_requests.lab_form_hint'.tr(),
                style: const TextStyle(color: AppColors.infoTealText),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'provider_dashboard.clinical_requests.collection'.tr(),
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                color: AppColors.ink900,
              ),
            ),
            const SizedBox(height: 8),
            _LabCollectionChoices(
              collectionType: _collectionType,
              onChanged: (value) => setState(() {
                _collectionType = value;
                _branchId = null;
              }),
            ),
            if (_collectionType == 'HOME_COLLECTION') ...[
              const SizedBox(height: 4),
              Text(
                'provider_dashboard.clinical_requests.home_collection_helper'
                    .tr(),
                style: const TextStyle(color: AppColors.mutedText2),
              ),
            ],
            const SizedBox(height: 20),
            labs.when(
              data: (branches) => _LabBranchField(
                branches: branches,
                branchId: _branchId,
                collectionType: _collectionType,
                onChanged: (value) => setState(() => _branchId = value),
              ),
              error: (_, _) => _RetryPanel(
                onRetry: () => ref.invalidate(labBranchesProvider),
              ),
              loading: () => const LinearProgressIndicator(),
            ),
            const SizedBox(height: 20),
            Text(
              'provider_dashboard.clinical_requests.lab_attachments_title'.tr(),
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                color: AppColors.ink900,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'provider_dashboard.clinical_requests.lab_attachments_hint'.tr(),
              style: const TextStyle(color: AppColors.mutedText2),
            ),
            const SizedBox(height: 8),
            _ClinicalImagePicker(
              onChanged: (images) => setState(() => _images = images),
            ),
            TextField(
              controller: _notes,
              maxLength: 500,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: 'provider_dashboard.clinical_requests.notes'.tr(),
              ),
            ),
            if (_submitError != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.warningAmberBg,
                  borderRadius: BorderRadius.circular(AppRadii.md),
                  border: Border.all(color: AppColors.warningAmberBorder),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: AppColors.warningAmberText,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _submitError!,
                        style: const TextStyle(
                          color: AppColors.warningAmberText,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 8),
            if (!canSubmit)
              Text(
                'provider_dashboard.clinical_requests.lab_submit_requirements'
                    .tr(),
                style: const TextStyle(color: AppColors.mutedText2),
              ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: canSubmit ? _submit : null,
                icon: _saving
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.send_outlined),
                label: Text('provider_dashboard.clinical_requests.submit'.tr()),
              ),
            ),
            Center(
              child: TextButton(
                onPressed: _saving ? null : () => Navigator.pop(context),
                child: Text('provider_dashboard.clinical_requests.cancel'.tr()),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (_saving || _branchId == null || _images.isEmpty) return;
    setState(() {
      _saving = true;
      _submitError = null;
    });
    try {
      final uploaded = await ref
          .read(providerClinicalUseCasesProvider)
          .uploadClinicalDocument(
            patientId: widget.patientId,
            documentType: 'LAB_REFERRAL',
            images: _images,
            appointmentId: widget.appointmentId,
            notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
          );
      if (uploaded.status == 'QUALITY_CHECK_FAILED') {
        throw StateError('quality check failed');
      }
      await ref
          .read(providerClinicalUseCasesProvider)
          .createLabOrder(
            patientId: widget.patientId,
            labBranchId: _branchId!,
            collectionType: _collectionType,
            testCodes: const [],
            prescriptionId: uploaded.prescriptionId,
            appointmentId: widget.appointmentId,
          );
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (mounted) {
        setState(() {
          _saving = false;
          _submitError = _requestFailureMessage(error);
        });
        _snack(context, _requestFailureMessage(error));
      }
    }
  }
}

class _LabCollectionChoices extends StatelessWidget {
  const _LabCollectionChoices({
    required this.collectionType,
    required this.onChanged,
  });

  final String collectionType;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      for (final value in const ['VISIT', 'HOME_COLLECTION'])
        Card(
          margin: const EdgeInsets.only(bottom: 8),
          elevation: 0,
          color: value == collectionType
              ? AppColors.tealBg
              : AppColors.surfaceCard,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.md),
            side: BorderSide(
              color: value == collectionType
                  ? AppColors.tealAccent
                  : AppColors.borderLight,
            ),
          ),
          child: RadioListTile<String>(
            value: value,
            groupValue: collectionType,
            contentPadding: const EdgeInsetsDirectional.fromSTEB(8, 4, 12, 4),
            title: Text(
              (value == 'VISIT'
                      ? 'provider_dashboard.clinical_requests.branch_visit'
                      : 'provider_dashboard.clinical_requests.home_collection')
                  .tr(),
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            onChanged: (selected) {
              if (selected != null) onChanged(selected);
            },
          ),
        ),
    ],
  );
}

class _LabBranchField extends StatelessWidget {
  const _LabBranchField({
    required this.branches,
    required this.branchId,
    required this.collectionType,
    required this.onChanged,
  });

  final List<LabBranch> branches;
  final String? branchId;
  final String collectionType;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final eligibleBranches = collectionType == 'HOME_COLLECTION'
        ? branches.where((branch) => branch.homeCollectionCapable).toList()
        : branches;
    final selectedBranchId = eligibleBranches.any(
      (branch) => branch.id == branchId,
    )
        ? branchId
        : null;
    if (eligibleBranches.isEmpty) {
      return Text(
        'provider_dashboard.clinical_requests.no_lab_branches'.tr(),
        style: const TextStyle(color: AppColors.errorRed),
      );
    }
    return DropdownButtonFormField<String>(
      initialValue: selectedBranchId,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: 'provider_dashboard.clinical_requests.lab_branch'.tr(),
        helperText: 'provider_dashboard.clinical_requests.lab_branch_hint'
            .tr(),
      ),
      items: eligibleBranches
          .map(
            (branch) => DropdownMenuItem<String>(
              value: branch.id,
              child: Text(
                '${branch.name} — ${branch.address}',
                overflow: TextOverflow.ellipsis,
              ),
            ),
          )
          .toList(),
      onChanged: onChanged,
    );
  }
}

enum _BatchRequestType { prescription, lab }

/// A deliberately separate mode rather than a hidden multi-select in the
/// single-patient form. The backend remains the authorization boundary and
/// creates one independent clinical record for every reviewed patient.
class _BatchAction extends StatelessWidget {
  const _BatchAction({required this.type, required this.initialPatientId});

  final _BatchRequestType type;
  final String initialPatientId;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
    child: SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () => showModalBottomSheet<void>(
          context: context,
          isScrollControlled: true,
          builder: (_) => _BatchRequestSheet(
            type: type,
            initialPatientId: initialPatientId,
          ),
        ),
        icon: const Icon(Icons.groups_outlined),
        label: Text('provider_dashboard.clinical_requests.create_batch'.tr()),
      ),
    ),
  );
}

class _BatchRequestSheet extends ConsumerStatefulWidget {
  const _BatchRequestSheet({
    required this.type,
    required this.initialPatientId,
  });

  final _BatchRequestType type;
  final String initialPatientId;

  @override
  ConsumerState<_BatchRequestSheet> createState() => _BatchRequestSheetState();
}

class _BatchRequestSheetState extends ConsumerState<_BatchRequestSheet> {
  final _selectedPatientIds = <String>{};
  final _imagesByPatient = <String, List<PrescriptionImage>>{};
  String? _labBranchId;
  String _collectionType = 'VISIT';
  int _step = 0;
  bool _submitting = false;
  String? _error;
  List<String> _results = const [];

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final patients = ref.watch(providerPatientsProvider);
    final isPrescription = widget.type == _BatchRequestType.prescription;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.viewInsetsOf(context).bottom + 20,
        ),
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * .86,
          child: patients.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, _) => _RetryPanel(
              onRetry: () => ref.invalidate(providerPatientsProvider),
            ),
            data: (items) {
              if (_selectedPatientIds.isEmpty && items.isNotEmpty) {
                _selectedPatientIds.add(widget.initialPatientId);
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'provider_dashboard.clinical_requests.batch_title'.tr(),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isPrescription
                        ? 'provider_dashboard.clinical_requests.batch_prescription_hint'
                              .tr()
                        : 'provider_dashboard.clinical_requests.batch_lab_hint'
                              .tr(),
                    style: const TextStyle(color: AppColors.mutedText2),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      _error!,
                      style: const TextStyle(color: AppColors.errorRed),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Expanded(
                    child: _step == 0
                        ? _editStep(items, isPrescription)
                        : _reviewStep(items, isPrescription),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _submitting
                          ? null
                          : _step == 0
                          ? () => _review(items, isPrescription)
                          : () => _submit(items, isPrescription),
                      child: _submitting
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(
                              _step == 0
                                  ? 'provider_dashboard.clinical_requests.review_batch'
                                        .tr()
                                  : 'provider_dashboard.clinical_requests.submit_batch'
                                        .tr(),
                            ),
                    ),
                  ),
                  if (_step == 1)
                    TextButton(
                      onPressed: () => setState(() => _step = 0),
                      child: Text(
                        'provider_dashboard.clinical_requests.edit_batch'.tr(),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _editStep(List<dynamic> patients, bool isPrescription) => ListView(
    children: [
      Text(
        'provider_dashboard.clinical_requests.select_patients'.tr(),
        style: const TextStyle(fontWeight: FontWeight.w800),
      ),
      const SizedBox(height: 4),
      ...patients.map((patient) {
        final patientId = patient.patientId as String;
        return CheckboxListTile(
          value: _selectedPatientIds.contains(patientId),
          title: Text(patient.patientName),
          subtitle: Text(
            patient.patientPhone,
            textDirection: ui.TextDirection.ltr,
          ),
          onChanged: (selected) => setState(() {
            if (selected == true) {
              _selectedPatientIds.add(patientId);
            } else {
              _selectedPatientIds.remove(patientId);
              _imagesByPatient.remove(patientId);
            }
          }),
        );
      }),
      const Divider(height: 28),
      if (!isPrescription) _labFields(),
      for (final patient in patients.where(
        (patient) => _selectedPatientIds.contains(patient.patientId),
      ))
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  patient.patientName,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                _ClinicalImagePicker(
                  key: ValueKey('batch-images-${patient.patientId}'),
                  onChanged: (images) => setState(() {
                    _imagesByPatient[patient.patientId as String] = images;
                  }),
                ),
              ],
            ),
          ),
        ),
    ],
  );

  Widget _labFields() {
    final branches = ref.watch(labBranchesProvider);
    return Column(
      children: [
        branches.when(
          loading: () => const LinearProgressIndicator(),
          error: (_, _) =>
              _RetryPanel(onRetry: () => ref.invalidate(labBranchesProvider)),
          data: (all) {
            final eligible = _collectionType == 'HOME_COLLECTION'
                ? all.where((branch) => branch.homeCollectionCapable).toList()
                : all;
            return DropdownButtonFormField<String>(
              initialValue: eligible.any((branch) => branch.id == _labBranchId)
                  ? _labBranchId
                  : null,
              decoration: InputDecoration(
                labelText: 'provider_dashboard.clinical_requests.lab_branch'
                    .tr(),
              ),
              items: eligible
                  .map(
                    (branch) => DropdownMenuItem(
                      value: branch.id,
                      child: Text(branch.name),
                    ),
                  )
                  .toList(),
              onChanged: (value) => setState(() => _labBranchId = value),
            );
          },
        ),
        DropdownButtonFormField<String>(
          initialValue: _collectionType,
          decoration: InputDecoration(
            labelText: 'provider_dashboard.clinical_requests.collection'.tr(),
          ),
          items: const ['VISIT', 'HOME_COLLECTION']
              .map(
                (value) => DropdownMenuItem(value: value, child: Text(value)),
              )
              .toList(),
          selectedItemBuilder: (context) => [
            Text('provider_dashboard.clinical_requests.branch_visit'.tr()),
            Text('provider_dashboard.clinical_requests.home_collection'.tr()),
          ],
          onChanged: (value) => setState(() {
            _collectionType = value ?? 'VISIT';
            _labBranchId = null;
          }),
        ),
      ],
    );
  }

  Widget _reviewStep(List<dynamic> patients, bool isPrescription) => ListView(
    children: [
      Text(
        'provider_dashboard.clinical_requests.review_per_patient'.tr(),
        style: const TextStyle(fontWeight: FontWeight.w800),
      ),
      const SizedBox(height: 8),
      ...patients
          .where((patient) => _selectedPatientIds.contains(patient.patientId))
          .map(
            (patient) => Card(
              child: ListTile(
                title: Text(patient.patientName),
                subtitle: Text(
                  '${_imagesByPatient[patient.patientId]?.length ?? 0} ${'provider_dashboard.clinical_requests.attachments_count'.tr()}',
                ),
              ),
            ),
          ),
      if (_results.isNotEmpty) ...[
        const SizedBox(height: 12),
        Text(
          'provider_dashboard.clinical_requests.batch_results'.tr(),
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        ..._results.map(
          (result) => ListTile(
            leading: const Icon(Icons.check_circle_outline),
            title: Text(result),
          ),
        ),
      ],
    ],
  );

  void _review(List<dynamic> patients, bool isPrescription) {
    final everyPatientHasOwnImage = _selectedPatientIds.every(
      (id) => _imagesByPatient[id]?.isNotEmpty == true,
    );
    final invalid =
        _selectedPatientIds.isEmpty ||
        !everyPatientHasOwnImage ||
        (!isPrescription && _labBranchId == null);
    if (invalid) {
      setState(
        () => _error = 'provider_dashboard.clinical_requests.batch_validation'
            .tr(),
      );
      return;
    }
    setState(() {
      _error = null;
      _step = 1;
    });
  }

  Future<void> _submit(List<dynamic> patients, bool isPrescription) async {
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final patientNames = {
        for (final patient in patients)
          patient.patientId as String: patient.patientName as String,
      };
      final useCases = ref.read(providerClinicalUseCasesProvider);
      final results = <String>[];
      for (final id in _selectedPatientIds) {
        final patientName = patientNames[id] ?? id;
        try {
          final upload = await useCases.uploadClinicalDocument(
            patientId: id,
            documentType: isPrescription ? 'PRESCRIPTION' : 'LAB_REFERRAL',
            images: _imagesByPatient[id]!,
          );
          if (!isPrescription && upload.status == 'QUALITY_CHECK_FAILED') {
            throw StateError(
              'Uploaded lab referral did not pass quality checks.',
            );
          }
          if (isPrescription) {
            results.add(
              '$patientName: ${upload.status} (${upload.prescriptionId})',
            );
          } else {
            final order = await useCases.createLabOrder(
              patientId: id,
              labBranchId: _labBranchId!,
              collectionType: _collectionType,
              testCodes: const [],
              prescriptionId: upload.prescriptionId,
            );
            results.add('$patientName: ${order.status} (${order.labOrderId})');
          }
        } catch (error) {
          results.add('$patientName: ${_requestFailureMessage(error)}');
        }
      }
      _results = results;
      if (isPrescription) {
        ref.invalidate(providerPrescriptionsProvider);
      } else {
        ref.invalidate(providerLabOrdersProvider);
      }
      if (mounted) setState(() => _submitting = false);
    } catch (error) {
      if (mounted) {
        setState(() {
          _submitting = false;
          _error = _requestFailureMessage(error);
        });
      }
    }
  }
}

class _RetryPanel extends StatelessWidget {
  const _RetryPanel({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => TextButton.icon(
    onPressed: onRetry,
    icon: const Icon(Icons.refresh),
    label: Text('provider_dashboard.clinical_requests.retry'.tr()),
  );
}

class _CreateAction extends StatelessWidget {
  const _CreateAction({required this.label, required this.onPressed});
  final String label;
  final VoidCallback onPressed;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(16),
    child: SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: onPressed,
        icon: const Icon(Icons.add),
        label: Text(label),
      ),
    ),
  );
}

bool _isConflict(Object error) =>
    error.toString().contains('409') ||
    error.toString().contains('OPTIMISTIC_LOCK_CONFLICT') ||
    error.toString().contains('VERSION_CONFLICT');

String _requestFailureMessage(Object error) {
  final value = error.toString();
  if (_isConflict(error)) {
    return 'provider_dashboard.clinical_requests.conflict'.tr();
  }
  if (value.contains('401') ||
      value.contains('403') ||
      value.contains('FORBIDDEN')) {
    return 'provider_dashboard.clinical_requests.unauthorized'.tr();
  }
  return 'provider_dashboard.clinical_requests.save_error'.tr();
}

void _snack(BuildContext context, String text, {bool success = false}) =>
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
        backgroundColor: success ? const Color(0xFF059669) : null,
      ),
    );

String _prescriptionTitle(ProviderPrescription prescription) {
  final names = prescription.items
      .map((item) => item.drugName)
      .where(
        (name) =>
            name.isNotEmpty && !name.trimLeft().startsWith('[DEV PLACEHOLDER]'),
      )
      .join(', ');
  return names.isEmpty
      ? 'provider_dashboard.clinical_requests.prescription'.tr()
      : names;
}

import 'dart:ui' as ui;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:med_super/core/theme/app_colors.dart';
import 'package:med_super/core/theme/app_radii.dart';
import 'package:med_super/core/widgets/async_value_view.dart';
import 'package:med_super/core/widgets/empty_state.dart';
import 'package:med_super/features/auth/presentation/controllers/session_provider.dart';
import 'package:med_super/features/lab_booking/domain/entities/lab_order_detail.dart';
import 'package:med_super/features/lab_booking/presentation/controllers/lab_branch_search_providers.dart';
import 'package:med_super/features/lab_booking/presentation/widgets/lab_order_status_pill.dart';
import 'package:med_super/features/pharmacy_booking/presentation/controllers/pharmacy_search_providers.dart';
import 'package:med_super/features/pharmacy_booking/domain/entities/pharmacy.dart';
import 'package:med_super/features/pharmacy_booking/domain/entities/pharmacy_order_detail.dart';
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
              final values = await showModalBottomSheet<Map<String, dynamic>>(
                context: context,
                isScrollControlled: true,
                builder: (_) => _PrescriptionForm(patientName: patientName),
              );
              if (values == null || !context.mounted) return;
              try {
                final result = await ref
                    .read(providerClinicalUseCasesProvider)
                    .createPrescription(
                      patientId: patientId,
                      appointmentId: appointmentId,
                      items: [values['item'] as ProviderPrescriptionItem],
                      notes: values['notes'] as String?,
                    );
                if (!context.mounted) return;
                ref.invalidate(providerPrescriptionsProvider);
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
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'provider_dashboard.clinical_requests.pharmacy_status'
                            .tr(),
                        style: const TextStyle(color: AppColors.mutedText2),
                      ),
                    ),
                    Chip(
                      label: Text(
                        'provider_dashboard.clinical_requests.pharmacy_status_${order.status}'
                            .tr(),
                      ),
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
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
                    child: FilledButton(
                      onPressed: () => _decide(context, ref, approve: true),
                      child: Text(
                        'provider_dashboard.clinical_requests.approve'.tr(),
                      ),
                    ),
                  ),
                ],
              ),
            ],
            if (canApprove && record.signed)
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
    final selection = await showDialog<({String branchId, String fulfillment})>(
      context: context,
      builder: (context) => _PharmacyOrderDialog(branches: branches),
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
}

class _PharmacyOrderDialog extends StatefulWidget {
  const _PharmacyOrderDialog({required this.branches});
  final List<Pharmacy> branches;
  @override
  State<_PharmacyOrderDialog> createState() => _PharmacyOrderDialogState();
}

class _PharmacyOrderDialogState extends State<_PharmacyOrderDialog> {
  String? branchId;
  String fulfillment = 'PICKUP';
  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text('provider_dashboard.clinical_requests.pharmacy_title'.tr()),
    content: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        DropdownButtonFormField<String>(
          initialValue:
              widget.branches
                  .where((b) => fulfillment != 'DELIVERY' || b.deliveryCapable)
                  .any((b) => b.id == branchId)
              ? branchId
              : null,
          decoration: InputDecoration(
            labelText: 'provider_dashboard.clinical_requests.pharmacy_branch'
                .tr(),
          ),
          items: widget.branches
              .where((b) => fulfillment != 'DELIVERY' || b.deliveryCapable)
              .map(
                (b) => DropdownMenuItem<String>(
                  value: b.id,
                  child: Text(b.name, overflow: TextOverflow.ellipsis),
                ),
              )
              .toList(),
          onChanged: (value) => setState(() => branchId = value),
        ),
        DropdownButtonFormField<String>(
          initialValue: fulfillment,
          decoration: InputDecoration(
            labelText: 'provider_dashboard.clinical_requests.fulfillment'.tr(),
          ),
          items: ['PICKUP', 'DELIVERY', 'CLINIC_HANDOVER']
              .map(
                (value) => DropdownMenuItem(
                  value: value,
                  child: Text(
                    'provider_dashboard.clinical_requests.fulfillment_$value'
                        .tr(),
                  ),
                ),
              )
              .toList(),
          onChanged: (value) => setState(() => fulfillment = value ?? 'PICKUP'),
        ),
      ],
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: Text('provider_dashboard.clinical_requests.cancel'.tr()),
      ),
      FilledButton(
        onPressed: branchId == null
            ? null
            : () => Navigator.pop(context, (
                branchId: branchId!,
                fulfillment: fulfillment,
              )),
        child: Text('provider_dashboard.clinical_requests.send'.tr()),
      ),
    ],
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

class _PrescriptionForm extends StatefulWidget {
  const _PrescriptionForm({required this.patientName});
  final String patientName;
  @override
  State<_PrescriptionForm> createState() => _PrescriptionFormState();
}

class _PrescriptionFormState extends State<_PrescriptionForm> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _dose = TextEditingController();
  final _frequency = TextEditingController();
  final _days = TextEditingController();
  final _quantity = TextEditingController(text: '1');
  final _notes = TextEditingController();
  @override
  void dispose() {
    _name.dispose();
    _dose.dispose();
    _frequency.dispose();
    _days.dispose();
    _quantity.dispose();
    _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(
      left: 20,
      right: 20,
      top: 20,
      bottom: MediaQuery.viewInsetsOf(context).bottom + 20,
    ),
    child: Form(
      key: _formKey,
      child: ListView(
        shrinkWrap: true,
        children: [
          Text(
            'provider_dashboard.clinical_requests.create_prescription'.tr(),
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
          ),
          Text(
            widget.patientName,
            style: const TextStyle(color: AppColors.mutedText2),
          ),
          const SizedBox(height: 12),
          _field(
            _name,
            'provider_dashboard.clinical_requests.drug_name'.tr(),
            required: true,
          ),
          _field(_dose, 'provider_dashboard.clinical_requests.dose'.tr()),
          _field(
            _frequency,
            'provider_dashboard.clinical_requests.frequency'.tr(),
          ),
          Row(
            children: [
              Expanded(
                child: _field(
                  _days,
                  'provider_dashboard.clinical_requests.duration_days'.tr(),
                  numeric: true,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _field(
                  _quantity,
                  'provider_dashboard.clinical_requests.quantity'.tr(),
                  numeric: true,
                  required: true,
                ),
              ),
            ],
          ),
          _field(
            _notes,
            'provider_dashboard.clinical_requests.notes'.tr(),
            maxLines: 2,
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: () {
              if (!_formKey.currentState!.validate()) return;
              Navigator.pop(context, {
                'item': ProviderPrescriptionItem(
                  drugName: _name.text.trim(),
                  quantity: int.parse(_quantity.text),
                  dose: _dose.text.trim().isEmpty ? null : _dose.text.trim(),
                  frequency: _frequency.text.trim().isEmpty
                      ? null
                      : _frequency.text.trim(),
                  durationDays: _days.text.trim().isEmpty
                      ? null
                      : int.parse(_days.text),
                ),
                'notes': _notes.text.trim(),
              });
            },
            child: Text('provider_dashboard.clinical_requests.submit'.tr()),
          ),
        ],
      ),
    ),
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
  final _search = TextEditingController();
  final _selectedCodes = <String>{};
  String? _branchId;
  String _collectionType = 'VISIT';
  bool _saving = false;
  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final labs = ref.watch(labBranchesProvider);
    final catalog = ref.watch(providerLabCatalogProvider(_search.text));
    return Padding(
      padding: EdgeInsets.only(
        left: 18,
        right: 18,
        top: 18,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 18,
      ),
      child: ListView(
        shrinkWrap: true,
        children: [
          Text(
            'provider_dashboard.clinical_requests.create_lab'.tr(),
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
          ),
          const SizedBox(height: 12),
          labs.when(
            data: (branches) {
              final eligible = _collectionType == 'HOME_COLLECTION'
                  ? branches.where((b) => b.homeCollectionCapable).toList()
                  : branches;
              return DropdownButtonFormField<String>(
                initialValue: eligible.any((b) => b.id == _branchId)
                    ? _branchId
                    : null,
                decoration: InputDecoration(
                  labelText: 'provider_dashboard.clinical_requests.lab_branch'
                      .tr(),
                ),
                items: eligible
                    .map(
                      (b) => DropdownMenuItem(
                        value: b.id,
                        child: Text(b.name, overflow: TextOverflow.ellipsis),
                      ),
                    )
                    .toList(),
                onChanged: (value) => setState(() => _branchId = value),
              );
            },
            error: (_, _) => TextButton(
              onPressed: () => ref.invalidate(labBranchesProvider),
              child: Text('provider_dashboard.clinical_requests.retry'.tr()),
            ),
            loading: () => const LinearProgressIndicator(),
          ),
          DropdownButtonFormField<String>(
            initialValue: _collectionType,
            decoration: InputDecoration(
              labelText: 'provider_dashboard.clinical_requests.collection'.tr(),
            ),
            items: ['VISIT', 'HOME_COLLECTION']
                .map(
                  (v) => DropdownMenuItem(
                    value: v,
                    child: Text(
                      v == 'VISIT'
                          ? 'provider_dashboard.clinical_requests.branch_visit'
                                .tr()
                          : 'provider_dashboard.clinical_requests.home_collection'
                                .tr(),
                    ),
                  ),
                )
                .toList(),
            onChanged: (v) => setState(() {
              _collectionType = v ?? 'VISIT';
              _branchId = null;
            }),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _search,
            decoration: InputDecoration(
              labelText: 'provider_dashboard.clinical_requests.search_test'
                  .tr(),
              suffixIcon: IconButton(
                onPressed: () => setState(() {}),
                icon: const Icon(Icons.search),
              ),
            ),
            onSubmitted: (_) => setState(() {}),
            onChanged: (_) => setState(() {}),
          ),
          catalog.when(
            data: (tests) => tests.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(
                      'provider_dashboard.clinical_requests.no_tests'.tr(),
                    ),
                  )
                : ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 260),
                    child: ListView(
                      shrinkWrap: true,
                      children: tests
                          .map(
                            (test) => CheckboxListTile(
                              value: _selectedCodes.contains(test.code),
                              title: Text(test.displayName),
                              subtitle: Text(test.code),
                              onChanged: (value) => setState(() {
                                value == true
                                    ? _selectedCodes.add(test.code)
                                    : _selectedCodes.remove(test.code);
                              }),
                              dense: true,
                            ),
                          )
                          .toList(),
                    ),
                  ),
            error: (_, _) => TextButton(
              onPressed: () =>
                  ref.invalidate(providerLabCatalogProvider(_search.text)),
              child: Text('provider_dashboard.clinical_requests.retry'.tr()),
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
          ),
          if (_selectedCodes.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'provider_dashboard.clinical_requests.tests_selected'.tr(
                  args: ['${_selectedCodes.length}'],
                ),
              ),
            ),
          const SizedBox(height: 8),
          FilledButton(
            onPressed: _saving || _branchId == null || _selectedCodes.isEmpty
                ? null
                : _submit,
            child: _saving
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text('provider_dashboard.clinical_requests.submit'.tr()),
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    setState(() => _saving = true);
    try {
      await ref
          .read(providerClinicalUseCasesProvider)
          .createLabOrder(
            patientId: widget.patientId,
            labBranchId: _branchId!,
            collectionType: _collectionType,
            testCodes: _selectedCodes.toList(growable: false),
            appointmentId: widget.appointmentId,
          );
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (mounted) {
        setState(() => _saving = false);
        _snack(context, _requestFailureMessage(error));
      }
    }
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
  final _drugName = TextEditingController();
  final _dose = TextEditingController();
  final _frequency = TextEditingController();
  final _quantity = TextEditingController(text: '1');
  final _notes = TextEditingController();
  final _testSearch = TextEditingController();
  final _selectedPatientIds = <String>{};
  final _selectedTestCodes = <String>{};
  String? _labBranchId;
  String _collectionType = 'VISIT';
  int _step = 0;
  bool _submitting = false;
  String? _error;
  List<String> _results = const [];

  @override
  void dispose() {
    _drugName.dispose();
    _dose.dispose();
    _frequency.dispose();
    _quantity.dispose();
    _notes.dispose();
    _testSearch.dispose();
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
      ...patients.map(
        (patient) => CheckboxListTile(
          value: _selectedPatientIds.contains(patient.patientId),
          title: Text(patient.patientName),
          subtitle: Text(
            patient.patientPhone,
            textDirection: ui.TextDirection.ltr,
          ),
          onChanged: (selected) => setState(() {
            selected == true
                ? _selectedPatientIds.add(patient.patientId as String)
                : _selectedPatientIds.remove(patient.patientId);
          }),
        ),
      ),
      const Divider(height: 28),
      if (isPrescription) ...[
        _field(
          _drugName,
          'provider_dashboard.clinical_requests.drug_name'.tr(),
          required: true,
        ),
        _field(_dose, 'provider_dashboard.clinical_requests.dose'.tr()),
        _field(
          _frequency,
          'provider_dashboard.clinical_requests.frequency'.tr(),
        ),
        _field(
          _quantity,
          'provider_dashboard.clinical_requests.quantity'.tr(),
          numeric: true,
          required: true,
        ),
        _field(
          _notes,
          'provider_dashboard.clinical_requests.notes'.tr(),
          maxLines: 2,
        ),
      ] else ...[
        _labFields(),
      ],
    ],
  );

  Widget _labFields() {
    final branches = ref.watch(labBranchesProvider);
    final catalog = ref.watch(providerLabCatalogProvider(_testSearch.text));
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
              value: eligible.any((branch) => branch.id == _labBranchId)
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
          value: _collectionType,
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
        TextField(
          controller: _testSearch,
          decoration: InputDecoration(
            labelText: 'provider_dashboard.clinical_requests.search_test'.tr(),
          ),
          onChanged: (_) => setState(() {}),
        ),
        catalog.when(
          loading: () => const Padding(
            padding: EdgeInsets.all(12),
            child: CircularProgressIndicator(),
          ),
          error: (_, _) => _RetryPanel(
            onRetry: () =>
                ref.invalidate(providerLabCatalogProvider(_testSearch.text)),
          ),
          data: (tests) => Column(
            children: tests
                .map(
                  (test) => CheckboxListTile(
                    value: _selectedTestCodes.contains(test.code),
                    title: Text(test.displayName),
                    subtitle: Text(
                      test.code,
                      textDirection: ui.TextDirection.ltr,
                    ),
                    onChanged: (selected) => setState(() {
                      selected == true
                          ? _selectedTestCodes.add(test.code)
                          : _selectedTestCodes.remove(test.code);
                    }),
                  ),
                )
                .toList(),
          ),
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
                  isPrescription
                      ? _drugName.text.trim()
                      : _selectedTestCodes.join(', '),
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
    final invalid =
        _selectedPatientIds.isEmpty ||
        (isPrescription &&
            (_drugName.text.trim().isEmpty ||
                int.tryParse(_quantity.text) == null ||
                int.parse(_quantity.text) < 1)) ||
        (!isPrescription &&
            (_labBranchId == null || _selectedTestCodes.isEmpty));
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
      if (isPrescription) {
        final item = ProviderPrescriptionItem(
          drugName: _drugName.text.trim(),
          quantity: int.parse(_quantity.text),
          dose: _dose.text.trim().isEmpty ? null : _dose.text.trim(),
          frequency: _frequency.text.trim().isEmpty
              ? null
              : _frequency.text.trim(),
        );
        final batch = await ref
            .read(providerClinicalUseCasesProvider)
            .createPrescriptionBatch(
              _selectedPatientIds
                  .map(
                    (id) => ProviderPrescriptionRequest(
                      patientId: id,
                      items: [item],
                      notes: _notes.text.trim().isEmpty
                          ? null
                          : _notes.text.trim(),
                    ),
                  )
                  .toList(growable: false),
            );
        _results = batch.results
            .map(
              (result) =>
                  '${patientNames[result.patientId] ?? result.patientId}: ${result.status} (${result.prescriptionId})',
            )
            .toList(growable: false);
        ref.invalidate(providerPrescriptionsProvider);
      } else {
        final batch = await ref
            .read(providerClinicalUseCasesProvider)
            .createLabOrderBatch(
              _selectedPatientIds
                  .map(
                    (id) => ProviderLabRequest(
                      patientId: id,
                      labBranchId: _labBranchId!,
                      collectionType: _collectionType,
                      testCodes: _selectedTestCodes.toList(growable: false),
                    ),
                  )
                  .toList(growable: false),
            );
        _results = batch.results
            .map(
              (result) =>
                  '${patientNames[result.patientId] ?? result.patientId}: ${result.status} (${result.labOrderId})',
            )
            .toList(growable: false);
        ref.invalidate(providerLabOrdersProvider);
      }
      if (mounted) setState(() => _submitting = false);
    } catch (error) {
      if (mounted)
        setState(() {
          _submitting = false;
          _error = _requestFailureMessage(error);
        });
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

Widget _field(
  TextEditingController controller,
  String label, {
  bool numeric = false,
  bool required = false,
  int maxLines = 1,
}) => Padding(
  padding: const EdgeInsets.only(bottom: 10),
  child: TextFormField(
    controller: controller,
    keyboardType: numeric ? TextInputType.number : TextInputType.text,
    maxLines: maxLines,
    decoration: InputDecoration(labelText: label),
    validator: (value) {
      final text = value?.trim() ?? '';
      if (required && text.isEmpty) {
        return 'provider_dashboard.clinical_requests.required'.tr();
      }
      if (numeric && text.isNotEmpty && int.tryParse(text) == null) {
        return 'provider_dashboard.clinical_requests.number_required'.tr();
      }
      return null;
    },
  ),
);

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
      .where((name) => name.isNotEmpty)
      .join(', ');
  return names.isEmpty
      ? 'provider_dashboard.clinical_requests.prescription'.tr()
      : names;
}

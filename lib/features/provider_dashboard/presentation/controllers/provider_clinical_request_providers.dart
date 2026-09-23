import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:med_super/core/di/core_providers.dart';
import 'package:med_super/features/lab_booking/domain/entities/lab_order_detail.dart';
import 'package:med_super/features/pharmacy_booking/domain/entities/pharmacy_order_detail.dart';
import '../../data/datasources/remote/provider_clinical_requests_remote_datasource.dart';
import '../../data/repositories/provider_clinical_requests_repository_impl.dart';
import '../../domain/entities/provider_clinical_request.dart';
import '../../domain/repositories/provider_clinical_requests_repository.dart';
import '../../domain/usecases/provider_clinical_request_usecases.dart';

final providerClinicalRemoteProvider = Provider(
  (ref) => ProviderClinicalRequestsRemoteDatasource(ref.watch(dioProvider)),
);
final providerClinicalRepositoryProvider =
    Provider<ProviderClinicalRequestsRepository>(
      (ref) => ProviderClinicalRequestsRepositoryImpl(
        ref.watch(providerClinicalRemoteProvider),
      ),
    );
final providerClinicalUseCasesProvider = Provider(
  (ref) => ProviderClinicalRequestUseCases(
    ref.watch(providerClinicalRepositoryProvider),
  ),
);

final providerPrescriptionsProvider =
    FutureProvider<List<ProviderPrescription>>(
      (ref) => ref.watch(providerClinicalUseCasesProvider).prescriptions(),
    );
final providerPrescriptionDetailProvider =
    FutureProvider.family<ProviderPrescription, String>(
      (ref, id) => ref.watch(providerClinicalUseCasesProvider).prescription(id),
    );
final providerLabOrdersProvider = FutureProvider<List<LabOrderDetail>>(
  (ref) => ref.watch(providerClinicalUseCasesProvider).labOrders(),
);
final providerPharmacyOrdersProvider =
    FutureProvider<List<PharmacyOrderDetail>>(
      (ref) => ref.watch(providerClinicalUseCasesProvider).pharmacyOrders(),
    );
final providerLabCatalogProvider =
    FutureProvider.family<List<ProviderLabTest>, String>(
      (ref, query) =>
          ref.watch(providerClinicalUseCasesProvider).searchLabCatalog(query),
    );

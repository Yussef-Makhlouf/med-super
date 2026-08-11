import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:med_super/core/di/core_providers.dart';
import 'package:med_super/features/lab_booking/data/datasources/remote/lab_catalog_remote_datasource.dart';
import 'package:med_super/features/lab_booking/data/repositories/lab_catalog_repository_impl.dart';
import 'package:med_super/features/lab_booking/domain/entities/lab_catalog.dart';
import 'package:med_super/features/lab_booking/domain/repositories/lab_catalog_repository.dart';
import 'package:med_super/features/lab_booking/domain/usecases/get_lab_catalog_usecase.dart';

part 'lab_booking_providers.g.dart';

@riverpod
LabCatalogRemoteDatasource labCatalogRemoteDatasource(Ref ref) =>
    LabCatalogRemoteDatasource(ref.watch(dioProvider));

@riverpod
LabCatalogRepository labCatalogRepository(Ref ref) => LabCatalogRepositoryImpl(
  remote: ref.watch(labCatalogRemoteDatasourceProvider),
);

@riverpod
GetLabCatalogUseCase getLabCatalogUseCase(Ref ref) =>
    GetLabCatalogUseCase(ref.watch(labCatalogRepositoryProvider));

@riverpod
Future<LabCatalog> labCatalog(Ref ref) async {
  final categoryId = ref.watch(activeLabCategoryProvider);
  final query = ref.watch(labSearchQueryProvider);
  final result = await ref
      .watch(getLabCatalogUseCaseProvider)
      .call(query: query, categoryId: categoryId);
  return result.when(ok: (value) => value, err: (failure) => throw failure);
}

/// Active category chip filter ('all' package chip is pre-selected by design).
@riverpod
class ActiveLabCategory extends _$ActiveLabCategory {
  @override
  String? build() => 'packages';

  void select(String? categoryId) => state = categoryId;
}

/// Free-text search query typed into the lab-tests search box.
@riverpod
class LabSearchQuery extends _$LabSearchQuery {
  @override
  String build() => '';

  void setQuery(String query) => state = query;
}

/// Test/package selection state — Set of selected [LabTest.id].
@riverpod
class SelectedLabTests extends _$SelectedLabTests {
  @override
  Set<String> build() => <String>{'vitamin-d'};

  void toggle(String testId) {
    final next = {...state};
    if (!next.remove(testId)) next.add(testId);
    state = next;
  }
}

/// Live total price of the current selection.
@riverpod
Future<int> selectedLabTestsTotal(Ref ref) async {
  final catalog = await ref.watch(labCatalogProvider.future);
  final selectedIds = ref.watch(selectedLabTestsProvider);
  return catalog.tests
      .where((t) => selectedIds.contains(t.id))
      .fold<int>(0, (sum, t) => sum + t.price);
}

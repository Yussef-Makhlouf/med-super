import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:med_super/core/di/core_providers.dart';
import 'package:med_super/features/lab_booking/data/datasources/remote/lab_booking_remote_datasource.dart';
import 'package:med_super/features/lab_booking/data/repositories/lab_booking_repository_impl.dart';
import 'package:med_super/features/lab_booking/domain/entities/lab_partner.dart';
import 'package:med_super/features/lab_booking/domain/entities/lab_partner_status.dart';
import 'package:med_super/features/lab_booking/domain/entities/lab_sort_option.dart';
import 'package:med_super/features/lab_booking/domain/repositories/lab_booking_repository.dart';
import 'package:med_super/features/lab_booking/domain/usecases/confirm_lab_booking_usecase.dart';
import 'package:med_super/features/lab_booking/domain/usecases/get_lab_partners_usecase.dart';

part 'lab_partner_providers.g.dart';

@riverpod
LabBookingRemoteDatasource labBookingRemoteDatasource(Ref ref) =>
    LabBookingRemoteDatasource(ref.watch(dioProvider));

@riverpod
LabBookingRepository labBookingRepository(Ref ref) => LabBookingRepositoryImpl(
  remote: ref.watch(labBookingRemoteDatasourceProvider),
);

@riverpod
GetLabPartnersUseCase getLabPartnersUseCase(Ref ref) =>
    GetLabPartnersUseCase(ref.watch(labBookingRepositoryProvider));

@riverpod
ConfirmLabBookingUseCase confirmLabBookingUseCase(Ref ref) =>
    ConfirmLabBookingUseCase(ref.watch(labBookingRepositoryProvider));

/// Sort order for the lab-partner list — defaults to "nearest" per Figma.
@riverpod
class LabSortController extends _$LabSortController {
  @override
  LabSortOption build() => LabSortOption.nearest;

  void select(LabSortOption sort) => state = sort;
}

@riverpod
Future<List<LabPartner>> labPartners(Ref ref) async {
  final sort = ref.watch(labSortControllerProvider);
  // The booking flow no longer starts from a searchable test catalog (see
  // LAB_BOOKING_FLOW_TODO_AR.md) — partners are no longer filtered by a
  // patient-selected set of test ids, so an empty list is passed through.
  final result = await ref
      .watch(getLabPartnersUseCaseProvider)
      .call(testIds: const [], sort: sort);
  return result.when(ok: (value) => value, err: (failure) => throw failure);
}

/// Explicitly chosen lab id — null means "not chosen yet, default to the
/// first (nearest) result", matching the Figma state where the top card is
/// pre-selected without any tap.
@riverpod
class SelectedLabPartner extends _$SelectedLabPartner {
  @override
  String? build() => null;

  void select(String labId) => state = labId;
}

/// Free-text search query typed into the "ابحث عن مختبر..." box.
@riverpod
class LabSearchQuery extends _$LabSearchQuery {
  @override
  String build() => '';

  void setQuery(String query) => state = query;
}

/// "مفتوح الآن" filter chip — when true, only labs currently open are shown.
@riverpod
class LabOpenNowOnlyFilter extends _$LabOpenNowOnlyFilter {
  @override
  bool build() => false;

  void toggle() => state = !state;
}

/// [labPartnersProvider] narrowed by the search query and the "مفتوح الآن"
/// filter — both are client-side (no backend query params exist for them),
/// applied on top of whatever the backend already sorted.
@riverpod
Future<List<LabPartner>> filteredLabPartners(Ref ref) async {
  final partners = await ref.watch(labPartnersProvider.future);
  final query = ref.watch(labSearchQueryProvider).trim().toLowerCase();
  final openNowOnly = ref.watch(labOpenNowOnlyFilterProvider);
  return partners.where((partner) {
    if (openNowOnly && partner.status != LabPartnerStatus.openNow) {
      return false;
    }
    if (query.isEmpty) return true;
    return partner.name.toLowerCase().contains(query);
  }).toList();
}

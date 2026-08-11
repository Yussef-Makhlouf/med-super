import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:med_super/core/di/core_providers.dart';
import 'package:med_super/features/lab_booking/data/datasources/remote/lab_booking_remote_datasource.dart';
import 'package:med_super/features/lab_booking/data/repositories/lab_booking_repository_impl.dart';
import 'package:med_super/features/lab_booking/domain/entities/lab_partner.dart';
import 'package:med_super/features/lab_booking/domain/entities/lab_sort_option.dart';
import 'package:med_super/features/lab_booking/domain/repositories/lab_booking_repository.dart';
import 'package:med_super/features/lab_booking/domain/usecases/confirm_lab_booking_usecase.dart';
import 'package:med_super/features/lab_booking/domain/usecases/get_lab_partners_usecase.dart';
import 'package:med_super/features/lab_booking/presentation/controllers/lab_booking_providers.dart';

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
  final selectedTestIds = ref.watch(selectedLabTestsProvider);
  final sort = ref.watch(labSortControllerProvider);
  final result = await ref
      .watch(getLabPartnersUseCaseProvider)
      .call(testIds: selectedTestIds.toList(), sort: sort);
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

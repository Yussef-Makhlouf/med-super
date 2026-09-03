import 'package:med_super/core/error/result.dart';
import 'package:med_super/features/lab_booking/domain/entities/lab_partner.dart';
import 'package:med_super/features/lab_booking/domain/entities/lab_sort_option.dart';
import 'package:med_super/features/lab_booking/domain/repositories/lab_booking_repository.dart';

class GetLabPartnersUseCase {
  const GetLabPartnersUseCase(this._repository);

  final LabBookingRepository _repository;

  Future<Result<List<LabPartner>>> call({
    required List<String> testIds,
    LabSortOption sort = LabSortOption.nearest,
  }) => _repository.getLabPartners(testIds: testIds, sort: sort);
}

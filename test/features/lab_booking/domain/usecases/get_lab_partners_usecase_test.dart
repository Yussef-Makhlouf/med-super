import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:med_super/core/error/failure.dart';
import 'package:med_super/core/error/result.dart';
import 'package:med_super/features/lab_booking/domain/entities/lab_partner.dart';
import 'package:med_super/features/lab_booking/domain/entities/lab_partner_status.dart';
import 'package:med_super/features/lab_booking/domain/entities/lab_sort_option.dart';
import 'package:med_super/features/lab_booking/domain/repositories/lab_booking_repository.dart';
import 'package:med_super/features/lab_booking/domain/usecases/get_lab_partners_usecase.dart';

class _MockLabBookingRepository extends Mock implements LabBookingRepository {}

void main() {
  late _MockLabBookingRepository repository;
  late GetLabPartnersUseCase useCase;

  setUpAll(() {
    registerFallbackValue(LabSortOption.nearest);
  });

  setUp(() {
    repository = _MockLabBookingRepository();
    useCase = GetLabPartnersUseCase(repository);
  });

  const partner = LabPartner(
    id: 'p1',
    name: 'Alpha',
    address: '1 Tahrir St, Cairo',
    distanceKm: 1,
    rating: 4.5,
    ratingCount: 10,
    startingPrice: 300,
    latitude: 1,
    longitude: 1,
    status: LabPartnerStatus.openNow,
  );

  test(
    'delegates to repository.getLabPartners with given testIds/sort',
    () async {
      when(
        () => repository.getLabPartners(
          testIds: ['t1', 't2'],
          sort: LabSortOption.priceAsc,
        ),
      ).thenAnswer((_) async => const Result.ok([partner]));

      final result = await useCase.call(
        testIds: ['t1', 't2'],
        sort: LabSortOption.priceAsc,
      );

      expect(result.valueOrNull, [partner]);
      verify(
        () => repository.getLabPartners(
          testIds: ['t1', 't2'],
          sort: LabSortOption.priceAsc,
        ),
      ).called(1);
    },
  );

  test('defaults sort to nearest when not specified', () async {
    when(
      () => repository.getLabPartners(
        testIds: any(named: 'testIds'),
        sort: LabSortOption.nearest,
      ),
    ).thenAnswer((_) async => const Result.ok([]));

    await useCase.call(testIds: const []);

    verify(
      () => repository.getLabPartners(
        testIds: const [],
        sort: LabSortOption.nearest,
      ),
    ).called(1);
  });

  test('propagates a failure result unchanged', () async {
    const failure = Failure.auth();
    when(
      () => repository.getLabPartners(
        testIds: any(named: 'testIds'),
        sort: any(named: 'sort'),
      ),
    ).thenAnswer((_) async => const Result.err(failure));

    final result = await useCase.call(testIds: const ['t1']);

    expect(result.failureOrNull, failure);
  });
}

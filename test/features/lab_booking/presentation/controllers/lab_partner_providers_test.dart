import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:med_super/core/error/failure.dart';
import 'package:med_super/core/error/result.dart';
import 'package:med_super/features/lab_booking/domain/entities/lab_partner.dart';
import 'package:med_super/features/lab_booking/domain/entities/lab_partner_status.dart';
import 'package:med_super/features/lab_booking/domain/entities/lab_sort_option.dart';
import 'package:med_super/features/lab_booking/domain/repositories/lab_booking_repository.dart';
import 'package:med_super/features/lab_booking/presentation/controllers/lab_partner_providers.dart';

class _MockLabBookingRepository extends Mock implements LabBookingRepository {}

void main() {
  late _MockLabBookingRepository repository;
  late ProviderContainer container;

  const partnerA = LabPartner(
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
  const partnerB = LabPartner(
    id: 'p2',
    name: 'Beta',
    address: '2 Nile St, Cairo',
    distanceKm: 2,
    rating: 4.9,
    ratingCount: 20,
    startingPrice: 200,
    latitude: 2,
    longitude: 2,
    status: LabPartnerStatus.openNow,
  );

  setUpAll(() {
    registerFallbackValue(LabSortOption.nearest);
  });

  setUp(() {
    repository = _MockLabBookingRepository();
    container = ProviderContainer(
      overrides: [labBookingRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
  });

  group('labSortControllerProvider', () {
    test('defaults to nearest', () {
      expect(container.read(labSortControllerProvider), LabSortOption.nearest);
    });

    test('select updates the state', () {
      container
          .read(labSortControllerProvider.notifier)
          .select(LabSortOption.priceAsc);
      expect(container.read(labSortControllerProvider), LabSortOption.priceAsc);
    });
  });

  group('selectedLabPartnerProvider', () {
    test('defaults to null (no explicit choice yet)', () {
      expect(container.read(selectedLabPartnerProvider), isNull);
    });

    test('select stores the chosen lab id', () {
      container.read(selectedLabPartnerProvider.notifier).select('p2');
      expect(container.read(selectedLabPartnerProvider), 'p2');
    });
  });

  group('labPartnersProvider', () {
    test('resolves to the repository partners on success', () async {
      when(
        () => repository.getLabPartners(
          testIds: any(named: 'testIds'),
          sort: any(named: 'sort'),
        ),
      ).thenAnswer((_) async => const Result.ok([partnerA, partnerB]));

      final result = await container.read(labPartnersProvider.future);

      expect(result, [partnerA, partnerB]);
    });

    test(
      'forwards the selected sort option with an empty test id list',
      () async {
        when(
          () => repository.getLabPartners(
            testIds: any(named: 'testIds'),
            sort: any(named: 'sort'),
          ),
        ).thenAnswer((_) async => const Result.ok([]));

        container
            .read(labSortControllerProvider.notifier)
            .select(LabSortOption.ratingDesc);

        await container.read(labPartnersProvider.future);

        verify(
          () => repository.getLabPartners(
            testIds: const [],
            sort: LabSortOption.ratingDesc,
          ),
        ).called(1);
      },
    );

    test('throws the Failure when the repository returns Result.err', () async {
      when(
        () => repository.getLabPartners(
          testIds: any(named: 'testIds'),
          sort: any(named: 'sort'),
        ),
      ).thenAnswer((_) async => const Result.err(Failure.auth()));

      // `container.read(provider.future)` raced with autoDispose in this
      // riverpod version (the provider could be torn down before the mocked
      // Future settled, surfacing a disposal StateError instead of our
      // Failure). Listening directly and capturing the AsyncError via the
      // listener callback avoids that race entirely.
      final errorCompleter = Completer<Object>();
      final sub = container.listen(labPartnersProvider, (previous, next) {
        if (next.hasError && !errorCompleter.isCompleted) {
          errorCompleter.complete(next.error);
        }
      }, fireImmediately: true);
      addTearDown(sub.close);

      final error = await errorCompleter.future.timeout(
        const Duration(seconds: 5),
      );
      expect(error, const Failure.auth());
    });
  });
}

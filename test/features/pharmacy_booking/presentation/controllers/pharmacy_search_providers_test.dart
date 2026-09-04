import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:med_super/features/pharmacy_booking/data/datasources/remote/pharmacy_branch_search_remote_datasource.dart'
    show PharmacyBranchSearchPage, PharmacyBranchSearchRemoteDatasource;
import 'package:med_super/features/pharmacy_booking/domain/entities/pharmacy.dart';
import 'package:med_super/features/pharmacy_booking/presentation/controllers/pharmacy_search_providers.dart';
import 'package:med_super/features/provider_registration/presentation/controllers/clinic_location_provider.dart';
import 'package:mocktail/mocktail.dart';

class _MockRemoteDatasource extends Mock
    implements PharmacyBranchSearchRemoteDatasource {}

class _FakeLocationService implements ClinicLocationService {
  const _FakeLocationService([this.position]);

  final LatLng? position;

  @override
  Future<LatLng?> getCurrentPosition() async => position;
}

const _branches = [
  Pharmacy(
    id: '00000000-0000-0000-0000-000000000111',
    name: 'صيدلية النهدي',
    address: 'شارع التحلية، الرياض',
    latitude: 24.7136,
    longitude: 46.6753,
    deliveryCapable: true,
    distanceKm: 1.2,
  ),
  Pharmacy(
    id: '00000000-0000-0000-0000-000000000112',
    name: 'صيدلية الدواء',
    address: 'طريق الملك فهد، الرياض',
    latitude: 24.7255,
    longitude: 46.6851,
    deliveryCapable: true,
    distanceKm: 2.5,
  ),
  Pharmacy(
    id: '00000000-0000-0000-0000-000000000113',
    name: 'صيدلية المجتمع',
    address: 'حي العليا، الرياض',
    latitude: 24.6944,
    longitude: 46.6892,
    deliveryCapable: false,
    distanceKm: null,
  ),
];

void main() {
  late _MockRemoteDatasource remoteDatasource;
  late ProviderContainer container;

  setUp(() {
    remoteDatasource = _MockRemoteDatasource();
    when(
      () => remoteDatasource.search(
        query: any(named: 'query'),
        latitude: any(named: 'latitude'),
        longitude: any(named: 'longitude'),
        radiusKm: any(named: 'radiusKm'),
        cursor: any(named: 'cursor'),
      ),
    ).thenAnswer(
      (_) async =>
          const PharmacyBranchSearchPage(items: _branches, nextCursor: null),
    );

    container = ProviderContainer(
      overrides: [
        pharmacyBranchSearchRemoteDatasourceProvider.overrideWithValue(
          remoteDatasource,
        ),
        pharmacyLocationServiceProvider.overrideWithValue(
          const _FakeLocationService(),
        ),
      ],
    );
    addTearDown(container.dispose);
  });

  group('pharmaciesProvider', () {
    test('resolves to the branches the remote datasource returns', () async {
      final result = await container.read(pharmaciesProvider.future);

      expect(result, hasLength(3));
      expect(result.map((p) => p.id), _branches.map((p) => p.id));
    });

    test('passes the device location through when available', () async {
      container.dispose();
      container = ProviderContainer(
        overrides: [
          pharmacyBranchSearchRemoteDatasourceProvider.overrideWithValue(
            remoteDatasource,
          ),
          pharmacyLocationServiceProvider.overrideWithValue(
            const _FakeLocationService(LatLng(30.04, 31.23)),
          ),
        ],
      );

      await container.read(pharmaciesProvider.future);

      verify(
        () => remoteDatasource.search(
          query: any(named: 'query'),
          latitude: 30.04,
          longitude: 31.23,
          radiusKm: any(named: 'radiusKm'),
          cursor: any(named: 'cursor'),
        ),
      ).called(1);
    });

    test('sends the entered pharmacy name to the remote search', () async {
      container.read(pharmacySearchQueryProvider.notifier).setQuery('الدواء');

      await container.read(pharmaciesProvider.future);

      verify(
        () => remoteDatasource.search(
          query: 'الدواء',
          latitude: null,
          longitude: null,
          radiusKm: any(named: 'radiusKm'),
          cursor: any(named: 'cursor'),
        ),
      ).called(1);
    });

    test(
      'falls back to an unfiltered catalogue when the nearby result is empty',
      () async {
        container.dispose();
        container = ProviderContainer(
          overrides: [
            pharmacyBranchSearchRemoteDatasourceProvider.overrideWithValue(
              remoteDatasource,
            ),
            pharmacyLocationServiceProvider.overrideWithValue(
              const _FakeLocationService(LatLng(0, 0)),
            ),
          ],
        );
        var callCount = 0;
        when(
          () => remoteDatasource.search(
            query: any(named: 'query'),
            latitude: any(named: 'latitude'),
            longitude: any(named: 'longitude'),
            radiusKm: any(named: 'radiusKm'),
            cursor: any(named: 'cursor'),
          ),
        ).thenAnswer((invocation) async {
          callCount++;
          if (callCount == 1) {
            return const PharmacyBranchSearchPage(items: [], nextCursor: null);
          }
          return const PharmacyBranchSearchPage(
            items: _branches,
            nextCursor: null,
          );
        });

        final result = await container.read(pharmaciesProvider.future);

        expect(result, hasLength(3));
        verify(
          () => remoteDatasource.search(
            query: any(named: 'query'),
            latitude: 0,
            longitude: 0,
            radiusKm: any(named: 'radiusKm'),
            cursor: any(named: 'cursor'),
          ),
        ).called(1);
        verify(
          () => remoteDatasource.search(
            query: any(named: 'query'),
            latitude: null,
            longitude: null,
            radiusKm: any(named: 'radiusKm'),
            cursor: any(named: 'cursor'),
          ),
        ).called(1);
      },
    );

    test('keeps branches whose address has no map coordinates', () async {
      when(
        () => remoteDatasource.search(
          query: any(named: 'query'),
          latitude: any(named: 'latitude'),
          longitude: any(named: 'longitude'),
          radiusKm: any(named: 'radiusKm'),
          cursor: any(named: 'cursor'),
        ),
      ).thenAnswer(
        (_) async => const PharmacyBranchSearchPage(
          items: [
            Pharmacy(
              id: 'branch-without-coordinates',
              name: 'صيدلية بلا إحداثيات',
              address: 'عنوان مسجل',
              deliveryCapable: true,
            ),
          ],
          nextCursor: null,
        ),
      );

      final result = await container.read(pharmaciesProvider.future);

      expect(result, hasLength(1));
      expect(result.single.latitude, isNull);
    });

    test(
      'searches with no location when the device position is unknown',
      () async {
        await container.read(pharmaciesProvider.future);

        verify(
          () => remoteDatasource.search(
            query: any(named: 'query'),
            latitude: null,
            longitude: null,
            radiusKm: any(named: 'radiusKm'),
            cursor: any(named: 'cursor'),
          ),
        ).called(1);
      },
    );
  });

  group('selectedPharmacyProvider', () {
    test('defaults to null (no explicit choice yet)', () {
      expect(container.read(selectedPharmacyProvider), isNull);
    });

    test('select stores the chosen branch id', () {
      container.read(selectedPharmacyProvider.notifier).select('112');
      expect(container.read(selectedPharmacyProvider), '112');
    });
  });

  group('pharmacySearchQueryProvider', () {
    test('defaults to empty string', () {
      expect(container.read(pharmacySearchQueryProvider), '');
    });

    test('setQuery updates the state', () {
      container.read(pharmacySearchQueryProvider.notifier).setQuery('نهدي');
      expect(container.read(pharmacySearchQueryProvider), 'نهدي');
    });
  });

  group('filteredPharmaciesProvider', () {
    test('sorts by nearest first, unknown-distance results last', () async {
      final result = await container.read(filteredPharmaciesProvider.future);
      expect(result.map((p) => p.id), [
        '00000000-0000-0000-0000-000000000111',
        '00000000-0000-0000-0000-000000000112',
        '00000000-0000-0000-0000-000000000113',
      ]);
    });

    test('filters by name matching the search query', () async {
      container.read(pharmacySearchQueryProvider.notifier).setQuery('الدواء');

      final result = await container.read(filteredPharmaciesProvider.future);
      expect(result.map((p) => p.id), ['00000000-0000-0000-0000-000000000112']);
    });

    test('filters by address matching the search query', () async {
      container.read(pharmacySearchQueryProvider.notifier).setQuery('العليا');

      final result = await container.read(filteredPharmaciesProvider.future);
      expect(result.map((p) => p.id), ['00000000-0000-0000-0000-000000000113']);
    });

    test('returns an empty list when nothing matches the query', () async {
      container
          .read(pharmacySearchQueryProvider.notifier)
          .setQuery('nonexistent');

      final result = await container.read(filteredPharmaciesProvider.future);
      expect(result, isEmpty);
    });
  });
}

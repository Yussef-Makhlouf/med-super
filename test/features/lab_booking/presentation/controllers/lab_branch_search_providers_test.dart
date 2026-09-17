import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:med_super/features/lab_booking/data/datasources/remote/lab_branch_search_remote_datasource.dart'
    show LabBranchSearchPage, LabBranchSearchRemoteDatasource;
import 'package:med_super/features/lab_booking/domain/entities/lab_branch.dart';
import 'package:med_super/features/lab_booking/presentation/controllers/lab_branch_search_providers.dart';
import 'package:med_super/features/provider_registration/presentation/controllers/clinic_location_provider.dart';
import 'package:mocktail/mocktail.dart';

class _MockRemoteDatasource extends Mock
    implements LabBranchSearchRemoteDatasource {}

class _FakeLocationService implements ClinicLocationService {
  const _FakeLocationService([this.position]);

  final LatLng? position;

  @override
  Future<LatLng?> getCurrentPosition() async => position;
}

const _branches = [
  LabBranch(
    id: '00000000-0000-0000-0000-000000000211',
    name: 'مختبرات نايل',
    address: '9 شارع قصر النيل',
    latitude: 30.044420,
    longitude: 31.235712,
    homeCollectionCapable: true,
    distanceKm: 1.2,
  ),
  LabBranch(
    id: '00000000-0000-0000-0000-000000000231',
    name: 'مختبرات البرج',
    address: 'كورنيش النيل، المعادي',
    latitude: 29.9602,
    longitude: 31.2569,
    homeCollectionCapable: true,
    distanceKm: 2.5,
  ),
  LabBranch(
    id: '00000000-0000-0000-0000-000000000251',
    name: 'مختبرات ألفا',
    address: 'شارع الميرغني، مصر الجديدة',
    latitude: 30.0808,
    longitude: 31.3231,
    homeCollectionCapable: false,
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
      (_) async => const LabBranchSearchPage(items: _branches, nextCursor: null),
    );

    container = ProviderContainer(
      overrides: [
        labBranchSearchRemoteDatasourceProvider.overrideWithValue(
          remoteDatasource,
        ),
        labBranchLocationServiceProvider.overrideWithValue(
          const _FakeLocationService(),
        ),
      ],
    );
    addTearDown(container.dispose);
  });

  group('labBranchesProvider', () {
    test('resolves to the branches the remote datasource returns', () async {
      final result = await container.read(labBranchesProvider.future);

      expect(result, hasLength(3));
      expect(result.map((b) => b.id), _branches.map((b) => b.id));
    });

    test('passes the device location through when available', () async {
      container.dispose();
      container = ProviderContainer(
        overrides: [
          labBranchSearchRemoteDatasourceProvider.overrideWithValue(
            remoteDatasource,
          ),
          labBranchLocationServiceProvider.overrideWithValue(
            const _FakeLocationService(LatLng(30.04, 31.23)),
          ),
        ],
      );

      await container.read(labBranchesProvider.future);

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

    test('sends the entered lab name to the remote search', () async {
      container.read(labBranchSearchQueryProvider.notifier).setQuery('البرج');

      await container.read(labBranchesProvider.future);

      verify(
        () => remoteDatasource.search(
          query: 'البرج',
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
            labBranchSearchRemoteDatasourceProvider.overrideWithValue(
              remoteDatasource,
            ),
            labBranchLocationServiceProvider.overrideWithValue(
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
            return const LabBranchSearchPage(items: [], nextCursor: null);
          }
          return const LabBranchSearchPage(items: _branches, nextCursor: null);
        });

        final result = await container.read(labBranchesProvider.future);

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
        (_) async => const LabBranchSearchPage(
          items: [
            LabBranch(
              id: 'branch-without-coordinates',
              name: 'مختبر بلا إحداثيات',
              address: 'عنوان مسجل',
              homeCollectionCapable: false,
            ),
          ],
          nextCursor: null,
        ),
      );

      final result = await container.read(labBranchesProvider.future);

      expect(result, hasLength(1));
      expect(result.single.latitude, isNull);
    });

    test(
      'searches with no location when the device position is unknown',
      () async {
        await container.read(labBranchesProvider.future);

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

  group('selectedLabBranchProvider', () {
    test('defaults to null (no explicit choice yet)', () {
      expect(container.read(selectedLabBranchProvider), isNull);
    });

    test('select stores the chosen branch id', () {
      container.read(selectedLabBranchProvider.notifier).select('231');
      expect(container.read(selectedLabBranchProvider), '231');
    });
  });

  group('labBranchSearchQueryProvider', () {
    test('defaults to empty string', () {
      expect(container.read(labBranchSearchQueryProvider), '');
    });

    test('setQuery updates the state', () {
      container.read(labBranchSearchQueryProvider.notifier).setQuery('نايل');
      expect(container.read(labBranchSearchQueryProvider), 'نايل');
    });
  });

  group('filteredLabBranchesProvider', () {
    test('sorts by nearest first, unknown-distance results last', () async {
      final result = await container.read(filteredLabBranchesProvider.future);
      expect(result.map((b) => b.id), [
        '00000000-0000-0000-0000-000000000211',
        '00000000-0000-0000-0000-000000000231',
        '00000000-0000-0000-0000-000000000251',
      ]);
    });

    test('filters by name matching the search query', () async {
      container.read(labBranchSearchQueryProvider.notifier).setQuery('البرج');

      final result = await container.read(filteredLabBranchesProvider.future);
      expect(result.map((b) => b.id), ['00000000-0000-0000-0000-000000000231']);
    });

    test('filters by address matching the search query', () async {
      container.read(labBranchSearchQueryProvider.notifier).setQuery('المعادي');

      final result = await container.read(filteredLabBranchesProvider.future);
      expect(result.map((b) => b.id), ['00000000-0000-0000-0000-000000000231']);
    });

    test('returns an empty list when nothing matches the query', () async {
      container
          .read(labBranchSearchQueryProvider.notifier)
          .setQuery('nonexistent');

      final result = await container.read(filteredLabBranchesProvider.future);
      expect(result, isEmpty);
    });
  });
}

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:med_super/core/error/failure.dart';
import 'package:med_super/core/error/result.dart';
import 'package:med_super/features/provider_registration/presentation/controllers/clinic_location_provider.dart';
import 'package:med_super/features/search_discovery/domain/entities/doctor_search_result.dart';
import 'package:med_super/features/search_discovery/domain/entities/doctor_sort.dart';
import 'package:med_super/features/search_discovery/domain/entities/doctor_summary.dart';
import 'package:med_super/features/search_discovery/domain/repositories/doctor_search_repository.dart';
import 'package:med_super/features/search_discovery/domain/usecases/search_doctors_usecase.dart';
import 'package:med_super/features/search_discovery/presentation/controllers/search_providers.dart';

const _doctorOne = DoctorSummary(
  id: 'doctor-1',
  name: 'Doctor One',
  specialty: 'Cardiology',
  locationLabel: 'Cairo',
  consultationFee: 500,
  currency: 'EGP',
);

const _doctorTwo = DoctorSummary(
  id: 'doctor-2',
  name: 'Doctor Two',
  specialty: 'Cardiology',
  locationLabel: 'Cairo',
  consultationFee: 600,
  currency: 'EGP',
);

class _NoLocation implements ClinicLocationService {
  const _NoLocation();

  @override
  Future<LatLng?> getCurrentPosition() async => null;
}

class _SequenceDoctorSearchRepository implements DoctorSearchRepository {
  _SequenceDoctorSearchRepository(this._responses);

  final List<Result<DoctorSearchResult>> _responses;
  final List<String?> requestedCursors = [];

  @override
  Future<Result<DoctorSearchResult>> searchDoctors({
    String? query,
    String? specialty,
    DoctorSort sort = DoctorSort.topRated,
    double? latitude,
    double? longitude,
    double? radiusKm,
    DateTime? date,
    String? cursor,
    int limit = 20,
  }) async {
    requestedCursors.add(cursor);
    return _responses.removeAt(0);
  }
}

ProviderContainer _createContainer(_SequenceDoctorSearchRepository repository) {
  return ProviderContainer(
    overrides: [
      searchDoctorsUseCaseProvider.overrideWithValue(
        SearchDoctorsUseCase(repository),
      ),
      doctorSearchLocationServiceProvider.overrideWithValue(
        const _NoLocation(),
      ),
    ],
  );
}

void main() {
  group('DoctorSearchResultsNotifier.loadMore', () {
    test(
      'appends only new doctors and requests the opaque next cursor',
      () async {
        final repository = _SequenceDoctorSearchRepository([
          const Result.ok(
            DoctorSearchResult(
              doctors: [_doctorOne],
              totalCount: 3,
              nextCursor: 'cursor-1',
            ),
          ),
          const Result.ok(
            DoctorSearchResult(
              doctors: [_doctorOne, _doctorTwo],
              totalCount: 3,
              nextCursor: null,
            ),
          ),
        ]);
        final container = _createContainer(repository);
        addTearDown(container.dispose);

        await container.read(doctorSearchResultsProvider.future);
        await container.read(doctorSearchResultsProvider.notifier).loadMore();

        final state = container.read(doctorSearchResultsProvider).requireValue;
        expect(state.doctors.map((doctor) => doctor.id), [
          'doctor-1',
          'doctor-2',
        ]);
        expect(state.hasMore, isFalse);
        expect(state.loadMoreFailed, isFalse);
        expect(repository.requestedCursors, [null, 'cursor-1']);
      },
    );

    test(
      'retains visible results and cursor, then clears the error on retry',
      () async {
        final repository = _SequenceDoctorSearchRepository([
          const Result.ok(
            DoctorSearchResult(
              doctors: [_doctorOne],
              totalCount: 2,
              nextCursor: 'cursor-1',
            ),
          ),
          const Result.err(Failure.network()),
          const Result.ok(
            DoctorSearchResult(
              doctors: [_doctorTwo],
              totalCount: 2,
              nextCursor: null,
            ),
          ),
        ]);
        final container = _createContainer(repository);
        addTearDown(container.dispose);

        await container.read(doctorSearchResultsProvider.future);
        final notifier = container.read(doctorSearchResultsProvider.notifier);
        await notifier.loadMore();

        final failedState = container
            .read(doctorSearchResultsProvider)
            .requireValue;
        expect(failedState.doctors, [_doctorOne]);
        expect(failedState.nextCursor, 'cursor-1');
        expect(failedState.loadMoreFailed, isTrue);

        await notifier.loadMore();

        final retriedState = container
            .read(doctorSearchResultsProvider)
            .requireValue;
        expect(retriedState.doctors, [_doctorOne, _doctorTwo]);
        expect(retriedState.hasMore, isFalse);
        expect(retriedState.loadMoreFailed, isFalse);
        expect(repository.requestedCursors, [null, 'cursor-1', 'cursor-1']);
      },
    );

    test('stops when the backend repeats the cursor', () async {
      final repository = _SequenceDoctorSearchRepository([
        const Result.ok(
          DoctorSearchResult(
            doctors: [_doctorOne],
            totalCount: 2,
            nextCursor: 'cursor-1',
          ),
        ),
        const Result.ok(
          DoctorSearchResult(
            doctors: [_doctorOne, _doctorTwo],
            totalCount: 2,
            nextCursor: 'cursor-1',
          ),
        ),
      ]);
      final container = _createContainer(repository);
      addTearDown(container.dispose);

      await container.read(doctorSearchResultsProvider.future);
      await container.read(doctorSearchResultsProvider.notifier).loadMore();

      final state = container.read(doctorSearchResultsProvider).requireValue;
      expect(state.doctors.map((doctor) => doctor.id), [
        'doctor-1',
        'doctor-2',
      ]);
      expect(state.hasMore, isFalse);
    });
  });
}

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:med_super/core/error/failure.dart';
import 'package:med_super/core/error/result.dart';
import 'package:med_super/core/specialties/domain/entities/specialty.dart';
import 'package:med_super/core/specialties/domain/repositories/specialties_repository.dart';
import 'package:med_super/core/specialties/presentation/controllers/specialties_providers.dart';

class _FakeSpecialtiesRepository implements SpecialtiesRepository {
  _FakeSpecialtiesRepository(this._result);

  final Result<List<Specialty>> _result;

  @override
  Future<Result<List<Specialty>>> getSpecialties() async => _result;
}

void main() {
  test('specialtiesProvider resolves to the backend list on success', () async {
    const specialties = [
      Specialty(code: 'CARDIOLOGY', nameEn: 'Cardiology', nameAr: 'قلب'),
      Specialty(code: 'DENTAL', nameEn: 'Dental', nameAr: 'أسنان'),
    ];
    final container = ProviderContainer(
      overrides: [
        specialtiesRepositoryProvider.overrideWithValue(
          _FakeSpecialtiesRepository(const Result.ok(specialties)),
        ),
      ],
    );
    addTearDown(container.dispose);

    final result = await container.read(specialtiesProvider.future);

    expect(result, specialties);
  });

  test(
    'specialtiesProvider resolves to an empty list without throwing when '
    'the backend has no seed data yet',
    () async {
      final container = ProviderContainer(
        overrides: [
          specialtiesRepositoryProvider.overrideWithValue(
            _FakeSpecialtiesRepository(const Result.ok(<Specialty>[])),
          ),
        ],
      );
      addTearDown(container.dispose);

      final result = await container.read(specialtiesProvider.future);

      expect(result, isEmpty);
    },
  );

  test('specialtiesProvider surfaces a repository failure as an AsyncError', () async {
    final container = ProviderContainer(
      overrides: [
        specialtiesRepositoryProvider.overrideWithValue(
          _FakeSpecialtiesRepository(const Result.err(Failure.network())),
        ),
      ],
    );
    addTearDown(container.dispose);

    await expectLater(
      container.read(specialtiesProvider.future),
      throwsA(isA<NetworkFailure>()),
    );
  });
}

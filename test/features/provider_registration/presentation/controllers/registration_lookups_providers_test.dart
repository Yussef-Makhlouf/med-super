import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:med_super/core/constants/api_paths.dart';
import 'package:med_super/core/di/core_providers.dart';
import 'package:med_super/features/provider_registration/presentation/controllers/registration_lookups_providers.dart';
import 'package:mocktail/mocktail.dart';

class _MockDio extends Mock implements Dio {}

void main() {
  late _MockDio dio;
  late ProviderContainer container;

  setUp(() {
    dio = _MockDio();
    container = ProviderContainer(
      overrides: [dioProvider.overrideWithValue(dio)],
    );
  });

  tearDown(() => container.dispose());

  test('parses specialties and cities from the lookups response', () async {
    when(
      () => dio.get<Map<String, dynamic>>(ApiPaths.providerRegistrationLookups),
    ).thenAnswer(
      (_) async => Response(
        requestOptions: RequestOptions(
          path: ApiPaths.providerRegistrationLookups,
        ),
        data: {
          'specialties': [
            {'id': 'cardio', 'label': 'Cardiology'},
            {'id': 'derma', 'label': 'Dermatology'},
          ],
          'cities': [
            {'id': 'cairo', 'label': 'Cairo'},
          ],
        },
      ),
    );

    final result = await container.read(registrationLookupsProvider.future);

    expect(result.specialties, hasLength(2));
    expect(result.specialties.first.id, 'cardio');
    expect(result.specialties.first.label, 'Cardiology');
    expect(result.cities, hasLength(1));
    expect(result.cities.first.id, 'cairo');
  });

  test(
    'returns empty lists when the response has no specialties/cities keys',
    () async {
      when(
        () =>
            dio.get<Map<String, dynamic>>(ApiPaths.providerRegistrationLookups),
      ).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(
            path: ApiPaths.providerRegistrationLookups,
          ),
          data: <String, dynamic>{},
        ),
      );

      final result = await container.read(registrationLookupsProvider.future);

      expect(result.specialties, isEmpty);
      expect(result.cities, isEmpty);
    },
  );

  test('returns empty lists when response.data itself is null', () async {
    when(
      () => dio.get<Map<String, dynamic>>(ApiPaths.providerRegistrationLookups),
    ).thenAnswer(
      (_) async => Response<Map<String, dynamic>>(
        requestOptions: RequestOptions(
          path: ApiPaths.providerRegistrationLookups,
        ),
        data: null,
      ),
    );

    final result = await container.read(registrationLookupsProvider.future);

    expect(result.specialties, isEmpty);
    expect(result.cities, isEmpty);
  });

  test('ignores malformed entries that are not maps', () async {
    when(
      () => dio.get<Map<String, dynamic>>(ApiPaths.providerRegistrationLookups),
    ).thenAnswer(
      (_) async => Response(
        requestOptions: RequestOptions(
          path: ApiPaths.providerRegistrationLookups,
        ),
        data: {
          'specialties': ['not-a-map', 42, null],
          'cities': [
            {'id': 'giza', 'label': 'Giza'},
          ],
        },
      ),
    );

    final result = await container.read(registrationLookupsProvider.future);

    expect(result.specialties, isEmpty);
    expect(result.cities, hasLength(1));
  });

  // Note: an error-path test (dio.get throwing) was deliberately left out.
  // registrationLookupsProvider is a generated Riverpod FutureProvider with
  // its default retry policy active (`retry: null` in the generated code
  // means "use riverpod's default", not "no retries") — on error it
  // schedules several delayed retries with real (non-fake-clock) Duration
  // backoff before settling into AsyncError. That makes the error path only
  // observable after tens of seconds of real wall-clock time in a plain
  // `flutter test`, which would make this suite slow and flaky rather than
  // exercising anything specific to this provider's own parsing logic
  // (already covered by the tests above).
}

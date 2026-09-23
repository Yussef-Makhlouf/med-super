import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:med_super/core/constants/api_paths.dart';
import 'package:med_super/core/specialties/data/datasources/remote/specialties_remote_datasource.dart';
import 'package:mocktail/mocktail.dart';

class _MockDio extends Mock implements Dio {}

void main() {
  late _MockDio dio;
  late SpecialtiesRemoteDatasource datasource;

  setUp(() {
    dio = _MockDio();
    datasource = SpecialtiesRemoteDatasource(dio);
  });

  test(
    'parses a raw array response.data (the real backend shape, after '
    'ResponseEnvelopeInterceptor unwraps the envelope)',
    () async {
      when(() => dio.get<dynamic>(ApiPaths.specialties)).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: ApiPaths.specialties),
          statusCode: 200,
          data: [
            {'code': 'CARDIOLOGY', 'name_ar': 'قلب'},
            {'code': 'DENTAL', 'name_ar': 'أسنان'},
          ],
        ),
      );

      final result = await datasource.getSpecialties();

      expect(result, hasLength(2));
      expect(result[0].code, 'CARDIOLOGY');
      expect(result[1].code, 'DENTAL');
    },
  );

  test(
    'parses the mock-only {specialties: [...]} wrapper shape',
    () async {
      when(() => dio.get<dynamic>(ApiPaths.specialties)).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: ApiPaths.specialties),
          statusCode: 200,
          data: {
            'specialties': [
              {'code': 'DERMATOLOGY', 'name_ar': 'جلدية'},
            ],
          },
        ),
      );

      final result = await datasource.getSpecialties();

      expect(result, hasLength(1));
      expect(result.single.code, 'DERMATOLOGY');
    },
  );

  test('returns an empty list when the backend responds with []', () async {
    when(() => dio.get<dynamic>(ApiPaths.specialties)).thenAnswer(
      (_) async => Response(
        requestOptions: RequestOptions(path: ApiPaths.specialties),
        statusCode: 200,
        data: <dynamic>[],
      ),
    );

    final result = await datasource.getSpecialties();

    expect(result, isEmpty);
  });

  test('returns an empty list for an unrecognized response.data shape', () async {
    when(() => dio.get<dynamic>(ApiPaths.specialties)).thenAnswer(
      (_) async => Response(
        requestOptions: RequestOptions(path: ApiPaths.specialties),
        statusCode: 200,
        data: 'unexpected',
      ),
    );

    final result = await datasource.getSpecialties();

    expect(result, isEmpty);
  });
}

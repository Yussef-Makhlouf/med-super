import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:med_super/core/constants/api_paths.dart';
import 'package:med_super/features/lab_booking/data/datasources/remote/lab_catalog_remote_datasource.dart';

class _MockDio extends Mock implements Dio {}

RequestOptions _reqOptions() => RequestOptions(path: ApiPaths.labTests);

Response<Map<String, dynamic>> _response(Map<String, dynamic>? data) =>
    Response<Map<String, dynamic>>(requestOptions: _reqOptions(), data: data);

void main() {
  late _MockDio dio;
  late LabCatalogRemoteDatasource datasource;

  setUp(() {
    dio = _MockDio();
    datasource = LabCatalogRemoteDatasource(dio);
  });

  test('getCatalog calls the lab-tests endpoint and maps the response', () async {
    when(
      () => dio.get<Map<String, dynamic>>(
        ApiPaths.labTests,
        queryParameters: any(named: 'queryParameters'),
      ),
    ).thenAnswer(
      (_) async => _response({
        'categories': [
          {'id': 'blood', 'label_key': 'k'},
        ],
        'tests': [
          {'id': 't1', 'name': 'CBC', 'price': 100, 'category_id': 'blood'},
        ],
        'suggested_labs': <Map<String, dynamic>>[],
      }),
    );

    final catalog = await datasource.getCatalog();

    expect(catalog.categories, hasLength(1));
    expect(catalog.tests, hasLength(1));
    expect(catalog.tests.single.name, 'CBC');
  });

  test('passes trimmed query and categoryId as query parameters', () async {
    when(
      () => dio.get<Map<String, dynamic>>(
        ApiPaths.labTests,
        queryParameters: any(named: 'queryParameters'),
      ),
    ).thenAnswer((_) async => _response(const {}));

    await datasource.getCatalog(query: '  cbc  ', categoryId: 'blood');

    final captured = verify(
      () => dio.get<Map<String, dynamic>>(
        ApiPaths.labTests,
        queryParameters: captureAny(named: 'queryParameters'),
      ),
    ).captured.single as Map<String, dynamic>;

    expect(captured['q'], 'cbc');
    expect(captured['category'], 'blood');
  });

  test('omits q/category query params when null or empty', () async {
    when(
      () => dio.get<Map<String, dynamic>>(
        ApiPaths.labTests,
        queryParameters: any(named: 'queryParameters'),
      ),
    ).thenAnswer((_) async => _response(const {}));

    await datasource.getCatalog(query: '   ', categoryId: '');

    final captured = verify(
      () => dio.get<Map<String, dynamic>>(
        ApiPaths.labTests,
        queryParameters: captureAny(named: 'queryParameters'),
      ),
    ).captured.single as Map<String, dynamic>;

    expect(captured.containsKey('q'), isFalse);
    expect(captured.containsKey('category'), isFalse);
  });

  test('treats a null response body as an empty catalog', () async {
    when(
      () => dio.get<Map<String, dynamic>>(
        ApiPaths.labTests,
        queryParameters: any(named: 'queryParameters'),
      ),
    ).thenAnswer((_) async => _response(null));

    final catalog = await datasource.getCatalog();

    expect(catalog.categories, isEmpty);
    expect(catalog.tests, isEmpty);
    expect(catalog.suggestedLabs, isEmpty);
  });

  test('propagates a DioException thrown by the client', () async {
    when(
      () => dio.get<Map<String, dynamic>>(
        ApiPaths.labTests,
        queryParameters: any(named: 'queryParameters'),
      ),
    ).thenThrow(DioException(requestOptions: _reqOptions()));

    expect(() => datasource.getCatalog(), throwsA(isA<DioException>()));
  });
}

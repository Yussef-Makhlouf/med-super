import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:med_super/features/pharmacy_booking/data/datasources/remote/prescription_remote_datasource.dart';
import 'package:med_super/features/pharmacy_booking/domain/entities/prescription_image.dart';

/// Captures the multipart parts the datasource sends.
class _CapturingAdapter implements HttpClientAdapter {
  FormData? sent;

  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async {
    sent = options.data as FormData;
    return ResponseBody.fromString(
      jsonEncode({'prescriptionId': 'rx-1', 'status': 'QUALITY_CHECK_PASSED'}),
      201,
      headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  test('labels each prescription file by its content, not its file name', () async {
    final adapter = _CapturingAdapter();
    final dio = Dio(BaseOptions(baseUrl: 'https://api.invalid'))..httpClientAdapter = adapter;

    await PrescriptionRemoteDatasource(dio).upload(images: [
      PrescriptionImage(id: '1', path: 'IMG_0001.jpg', bytes: Uint8List.fromList([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a])),
      PrescriptionImage(id: '2', path: 'scan', bytes: Uint8List.fromList([0xff, 0xd8, 0xff, 0xe0])),
    ]);

    final types = adapter.sent!.files.map((entry) => entry.value.contentType.toString()).toList();
    expect(types, ['image/png', 'image/jpeg']);
  });
}

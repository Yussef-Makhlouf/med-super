import 'package:flutter_test/flutter_test.dart';
import 'package:med_super/features/lab_booking/domain/entities/lab_request_image.dart';

void main() {
  test('LabRequestImage stores id and path', () {
    const image = LabRequestImage(id: 'img1', path: '/tmp/photo.jpg');

    expect(image.id, 'img1');
    expect(image.path, '/tmp/photo.jpg');
  });
}

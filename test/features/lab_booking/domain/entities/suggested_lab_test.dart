import 'package:flutter_test/flutter_test.dart';
import 'package:med_super/features/lab_booking/domain/entities/suggested_lab.dart';

void main() {
  test('SuggestedLab stores id, name, distance and rating', () {
    const lab = SuggestedLab(
      id: 'lab1',
      name: 'Alpha Labs',
      distanceKm: 2.5,
      rating: 4.7,
    );

    expect(lab.id, 'lab1');
    expect(lab.name, 'Alpha Labs');
    expect(lab.distanceKm, 2.5);
    expect(lab.rating, 4.7);
  });
}

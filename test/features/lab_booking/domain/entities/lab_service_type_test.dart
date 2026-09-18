import 'package:flutter_test/flutter_test.dart';
import 'package:med_super/features/lab_booking/domain/entities/lab_service_type.dart';

void main() {
  test('has exactly the two upload-step options', () {
    expect(LabServiceType.values, [
      LabServiceType.branchVisit,
      LabServiceType.homeCollection,
    ]);
  });

  test('each value has a distinct titleKey under upload.*', () {
    final keys = LabServiceType.values.map((t) => t.titleKey).toSet();

    expect(keys, hasLength(LabServiceType.values.length));
    for (final key in keys) {
      expect(key, startsWith('lab_booking.upload.service_'));
    }
  });

  test('each value has a distinct subtitleKey under upload.*', () {
    final keys = LabServiceType.values.map((t) => t.subtitleKey).toSet();

    expect(keys, hasLength(LabServiceType.values.length));
    for (final key in keys) {
      expect(key, startsWith('lab_booking.upload.service_'));
      expect(key, endsWith('_subtitle'));
    }
  });

  test('apiValue matches the backend CollectionType enum exactly', () {
    expect(LabServiceType.branchVisit.apiValue, 'VISIT');
    expect(LabServiceType.homeCollection.apiValue, 'HOME_COLLECTION');
  });

  test('each value has a distinct apiValue', () {
    final values = LabServiceType.values.map((t) => t.apiValue).toSet();
    expect(values, hasLength(LabServiceType.values.length));
  });
}

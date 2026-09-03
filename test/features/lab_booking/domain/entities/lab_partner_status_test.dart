import 'package:flutter_test/flutter_test.dart';
import 'package:med_super/features/lab_booking/domain/entities/lab_partner_status.dart';

void main() {
  test('has exactly the three operating states', () {
    expect(LabPartnerStatus.values, [
      LabPartnerStatus.openNow,
      LabPartnerStatus.closedNow,
      LabPartnerStatus.busyNow,
    ]);
  });

  test('each value has a distinct labelKey under select_lab.*', () {
    final keys = LabPartnerStatus.values.map((s) => s.labelKey).toSet();

    expect(keys, hasLength(LabPartnerStatus.values.length));
    for (final key in keys) {
      expect(key, startsWith('lab_booking.select_lab.status_'));
    }
  });

  test('apiValue is a stable snake_case wire value per status', () {
    expect(LabPartnerStatus.openNow.apiValue, 'open_now');
    expect(LabPartnerStatus.closedNow.apiValue, 'closed_now');
    expect(LabPartnerStatus.busyNow.apiValue, 'busy_now');
  });

  test('each value has a distinct apiValue', () {
    final values = LabPartnerStatus.values.map((s) => s.apiValue).toSet();
    expect(values, hasLength(LabPartnerStatus.values.length));
  });

  group('fromApiValue', () {
    test('parses closed_now', () {
      expect(
        LabPartnerStatus.fromApiValue('closed_now'),
        LabPartnerStatus.closedNow,
      );
    });

    test('parses busy_now', () {
      expect(
        LabPartnerStatus.fromApiValue('busy_now'),
        LabPartnerStatus.busyNow,
      );
    });

    test('parses open_now', () {
      expect(
        LabPartnerStatus.fromApiValue('open_now'),
        LabPartnerStatus.openNow,
      );
    });

    test('defaults to openNow for null', () {
      expect(LabPartnerStatus.fromApiValue(null), LabPartnerStatus.openNow);
    });

    test('defaults to openNow for unknown value', () {
      expect(
        LabPartnerStatus.fromApiValue('unknown'),
        LabPartnerStatus.openNow,
      );
    });
  });
}

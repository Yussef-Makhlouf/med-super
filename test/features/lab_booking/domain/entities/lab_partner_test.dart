import 'package:flutter_test/flutter_test.dart';
import 'package:med_super/features/lab_booking/domain/entities/lab_partner.dart';
import 'package:med_super/features/lab_booking/domain/entities/lab_partner_status.dart';

void main() {
  test('LabPartner stores all fields', () {
    const partner = LabPartner(
      id: 'p1',
      name: 'Alpha Labs',
      address: '12 Tahrir St, Cairo',
      distanceKm: 3.2,
      rating: 4.5,
      ratingCount: 120,
      startingPrice: 500,
      latitude: 24.7,
      longitude: 46.6,
      status: LabPartnerStatus.openNow,
    );

    expect(partner.id, 'p1');
    expect(partner.name, 'Alpha Labs');
    expect(partner.address, '12 Tahrir St, Cairo');
    expect(partner.distanceKm, 3.2);
    expect(partner.rating, 4.5);
    expect(partner.ratingCount, 120);
    expect(partner.startingPrice, 500);
    expect(partner.latitude, 24.7);
    expect(partner.longitude, 46.6);
    expect(partner.status, LabPartnerStatus.openNow);
  });
}

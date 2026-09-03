import 'package:flutter_test/flutter_test.dart';
import 'package:med_super/features/lab_booking/data/models/lab_partner_dto.dart';
import 'package:med_super/features/lab_booking/domain/entities/lab_partner_status.dart';

void main() {
  group('LabPartnerDto', () {
    test('fromJson parses all fields', () {
      final dto = LabPartnerDto.fromJson(const {
        'id': 'p1',
        'name': 'Alpha Labs',
        'address': '12 Tahrir St, Cairo',
        'distance_km': 2.5,
        'rating': 4.6,
        'rating_count': 87,
        'starting_price': 450,
        'latitude': 24.7,
        'longitude': 46.6,
        'status': 'closed_now',
      });

      expect(dto.id, 'p1');
      expect(dto.name, 'Alpha Labs');
      expect(dto.address, '12 Tahrir St, Cairo');
      expect(dto.distanceKm, 2.5);
      expect(dto.rating, 4.6);
      expect(dto.ratingCount, 87);
      expect(dto.startingPrice, 450);
      expect(dto.latitude, 24.7);
      expect(dto.longitude, 46.6);
      expect(dto.status, LabPartnerStatus.closedNow);
    });

    test('fromJson defaults missing address to an empty string', () {
      final dto = LabPartnerDto.fromJson(const {'id': 'p2', 'name': 'Beta'});

      expect(dto.address, '');
    });

    test('fromJson defaults missing optional numeric fields to 0', () {
      final dto = LabPartnerDto.fromJson(const {'id': 'p2', 'name': 'Beta'});

      expect(dto.distanceKm, 0);
      expect(dto.rating, 0);
      expect(dto.ratingCount, 0);
      expect(dto.startingPrice, 0);
      expect(dto.latitude, 0);
      expect(dto.longitude, 0);
    });

    test('fromJson defaults missing status to openNow', () {
      final dto = LabPartnerDto.fromJson(const {'id': 'p2', 'name': 'Beta'});

      expect(dto.status, LabPartnerStatus.openNow);
    });

    test('fromJson defaults unknown status value to openNow', () {
      final dto = LabPartnerDto.fromJson(const {
        'id': 'p2',
        'name': 'Beta',
        'status': 'something_else',
      });

      expect(dto.status, LabPartnerStatus.openNow);
    });

    test('fromJson parses busy_now status', () {
      final dto = LabPartnerDto.fromJson(const {
        'id': 'p3',
        'name': 'Gamma',
        'status': 'busy_now',
      });

      expect(dto.status, LabPartnerStatus.busyNow);
    });

    test('fromJson accepts int json values for double fields', () {
      final dto = LabPartnerDto.fromJson(const {
        'id': 'p3',
        'name': 'Gamma',
        'distance_km': 4,
        'rating': 5,
        'latitude': 24,
        'longitude': 46,
      });

      expect(dto.distanceKm, 4.0);
      expect(dto.rating, 5.0);
      expect(dto.latitude, 24.0);
      expect(dto.longitude, 46.0);
    });

    test('toEntity maps every field 1:1', () {
      final dto = LabPartnerDto.fromJson(const {
        'id': 'p1',
        'name': 'Alpha Labs',
        'address': '12 Tahrir St, Cairo',
        'distance_km': 2.5,
        'rating': 4.6,
        'rating_count': 87,
        'starting_price': 450,
        'latitude': 24.7,
        'longitude': 46.6,
        'status': 'open_now',
      });

      final entity = dto.toEntity();

      expect(entity.id, dto.id);
      expect(entity.name, dto.name);
      expect(entity.address, dto.address);
      expect(entity.distanceKm, dto.distanceKm);
      expect(entity.rating, dto.rating);
      expect(entity.ratingCount, dto.ratingCount);
      expect(entity.startingPrice, dto.startingPrice);
      expect(entity.latitude, dto.latitude);
      expect(entity.longitude, dto.longitude);
      expect(entity.status, dto.status);
    });
  });
}

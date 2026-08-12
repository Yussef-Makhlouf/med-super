import 'package:flutter_test/flutter_test.dart';
import 'package:med_super/features/lab_booking/data/models/lab_partner_dto.dart';

void main() {
  group('LabPartnerDto', () {
    test('fromJson parses all fields', () {
      final dto = LabPartnerDto.fromJson(const {
        'id': 'p1',
        'name': 'Alpha Labs',
        'distance_km': 2.5,
        'rating': 4.6,
        'rating_count': 87,
        'total_price': 450,
        'latitude': 24.7,
        'longitude': 46.6,
      });

      expect(dto.id, 'p1');
      expect(dto.name, 'Alpha Labs');
      expect(dto.distanceKm, 2.5);
      expect(dto.rating, 4.6);
      expect(dto.ratingCount, 87);
      expect(dto.totalPrice, 450);
      expect(dto.latitude, 24.7);
      expect(dto.longitude, 46.6);
    });

    test('fromJson defaults missing optional numeric fields to 0', () {
      final dto = LabPartnerDto.fromJson(const {'id': 'p2', 'name': 'Beta'});

      expect(dto.distanceKm, 0);
      expect(dto.rating, 0);
      expect(dto.ratingCount, 0);
      expect(dto.totalPrice, 0);
      expect(dto.latitude, 0);
      expect(dto.longitude, 0);
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
        'distance_km': 2.5,
        'rating': 4.6,
        'rating_count': 87,
        'total_price': 450,
        'latitude': 24.7,
        'longitude': 46.6,
      });

      final entity = dto.toEntity();

      expect(entity.id, dto.id);
      expect(entity.name, dto.name);
      expect(entity.distanceKm, dto.distanceKm);
      expect(entity.rating, dto.rating);
      expect(entity.ratingCount, dto.ratingCount);
      expect(entity.totalPrice, dto.totalPrice);
      expect(entity.latitude, dto.latitude);
      expect(entity.longitude, dto.longitude);
    });
  });
}

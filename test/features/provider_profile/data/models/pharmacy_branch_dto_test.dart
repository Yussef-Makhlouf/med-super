import 'package:flutter_test/flutter_test.dart';
import 'package:med_super/features/provider_profile/data/models/pharmacy_branch_dto.dart';

void main() {
  group('PharmacyBranchDto', () {
    test('fromJson parses the real backend snake_case shape', () {
      final dto = PharmacyBranchDto.fromJson(const {
        'id': 'branch-1',
        'pharmacy_id': 'pharmacy-1',
        'phone': '+201234567890',
        'iana_timezone': 'Africa/Cairo',
        'delivery_capable': true,
        'status': 'VERIFIED',
        'pharmacy': {
          'id': 'pharmacy-1',
          'legal_name': 'Al Ezaby Legal Co.',
          'brand_name': 'Al Ezaby Pharmacy',
        },
        'address': {
          'line1': '12 Tahrir St',
          'city': 'Cairo',
          'region_code': 'CAI',
          'country_code': 'EG',
          'geo_lat': 30.05,
          'geo_lng': 31.23,
        },
      });

      expect(dto.id, 'branch-1');
      expect(dto.pharmacyId, 'pharmacy-1');
      expect(dto.pharmacyName, 'Al Ezaby Pharmacy');
      expect(dto.phone, '+201234567890');
      expect(dto.ianaTimezone, 'Africa/Cairo');
      expect(dto.deliveryCapable, isTrue);
      expect(dto.status, 'VERIFIED');
      expect(dto.addressLine1, '12 Tahrir St');
      expect(dto.addressCity, 'Cairo');
      expect(dto.addressRegionCode, 'CAI');
      expect(dto.addressCountryCode, 'EG');
      expect(dto.geoLat, 30.05);
      expect(dto.geoLng, 31.23);
    });

    test('fromJson accepts int json values for the double geo fields', () {
      final dto = PharmacyBranchDto.fromJson(const {
        'id': 'branch-1',
        'address': {'geo_lat': 30, 'geo_lng': 31},
      });

      expect(dto.geoLat, 30.0);
      expect(dto.geoLng, 31.0);
    });

    test('fromJson falls back to legal_name when brand_name is missing', () {
      final dto = PharmacyBranchDto.fromJson(const {
        'id': 'branch-1',
        'pharmacy': {'legal_name': 'Al Ezaby Legal Co.'},
      });

      expect(dto.pharmacyName, 'Al Ezaby Legal Co.');
    });

    test(
      'fromJson defaults every missing field to a safe empty value',
      () {
        final dto = PharmacyBranchDto.fromJson(const {});

        expect(dto.id, '');
        expect(dto.pharmacyId, '');
        expect(dto.pharmacyName, '');
        expect(dto.phone, '');
        expect(dto.ianaTimezone, '');
        expect(dto.deliveryCapable, isFalse);
        expect(dto.status, 'PENDING');
        expect(dto.addressLine1, '');
        expect(dto.addressCity, '');
        expect(dto.addressRegionCode, '');
        expect(dto.addressCountryCode, '');
        expect(dto.geoLat, isNull);
        expect(dto.geoLng, isNull);
      },
    );

    test('toEntity maps every field 1:1, including the nested address', () {
      final dto = PharmacyBranchDto.fromJson(const {
        'id': 'branch-1',
        'pharmacy_id': 'pharmacy-1',
        'phone': '+201234567890',
        'iana_timezone': 'Africa/Cairo',
        'delivery_capable': true,
        'status': 'VERIFIED',
        'pharmacy': {'brand_name': 'Al Ezaby Pharmacy'},
        'address': {
          'line1': '12 Tahrir St',
          'city': 'Cairo',
          'region_code': 'CAI',
          'country_code': 'EG',
          'geo_lat': 30.05,
          'geo_lng': 31.23,
        },
      });

      final entity = dto.toEntity();

      expect(entity.id, dto.id);
      expect(entity.pharmacyId, dto.pharmacyId);
      expect(entity.pharmacyName, dto.pharmacyName);
      expect(entity.phone, dto.phone);
      expect(entity.ianaTimezone, dto.ianaTimezone);
      expect(entity.deliveryCapable, dto.deliveryCapable);
      expect(entity.status, dto.status);
      expect(entity.isVerified, isTrue);
      expect(entity.address.line1, dto.addressLine1);
      expect(entity.address.city, dto.addressCity);
      expect(entity.address.regionCode, dto.addressRegionCode);
      expect(entity.address.countryCode, dto.addressCountryCode);
      expect(entity.address.geoLat, dto.geoLat);
      expect(entity.address.geoLng, dto.geoLng);
    });
  });
}

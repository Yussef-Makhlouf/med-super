import 'package:flutter_test/flutter_test.dart';
import 'package:med_super/features/provider_profile/data/models/clinic_profile_dto.dart';

void main() {
  group('ClinicProfileDto', () {
    test('fromJson parses the real backend snake_case shape', () {
      final dto = ClinicProfileDto.fromJson({
        'id': 'c1',
        'legal_name': 'Nile Medical Group LLC',
        'brand_name': 'Nile Clinic',
        'tax_id': 'TAX-123',
        'region_code': 'CAI',
        'status': 'VERIFIED',
        'verified_at': '2024-01-01T00:00:00.000Z',
        'deleted_at': null,
        'created_at': '2023-01-01T00:00:00.000Z',
        'updated_at': '2023-06-01T00:00:00.000Z',
        'version': 3,
        'branches': [
          {
            'id': 'b1',
            'clinic_id': 'c1',
            'address_id': 'a1',
            'phone': '+201234567890',
            'iana_timezone': 'Africa/Cairo',
            'status': 'VERIFIED',
            'created_at': '2023-01-01T00:00:00.000Z',
            'updated_at': '2023-06-01T00:00:00.000Z',
            'version': 1,
            'address': {
              'id': 'a1',
              'line1': '12 Tahrir St',
              'city': 'Cairo',
              'region_code': 'CAI',
              'country_code': 'EG',
              'geo_lat': '30.044420',
              'geo_lng': '31.235712',
            },
          },
        ],
      });

      expect(dto.id, 'c1');
      expect(dto.legalName, 'Nile Medical Group LLC');
      expect(dto.brandName, 'Nile Clinic');
      expect(dto.taxId, 'TAX-123');
      expect(dto.regionCode, 'CAI');
      expect(dto.status, 'VERIFIED');
      expect(dto.branches, hasLength(1));

      final branch = dto.branches.single;
      expect(branch.id, 'b1');
      expect(branch.phone, '+201234567890');
      expect(branch.ianaTimezone, 'Africa/Cairo');
      expect(branch.status, 'VERIFIED');
      expect(branch.address.line1, '12 Tahrir St');
      expect(branch.address.city, 'Cairo');
      expect(branch.address.regionCode, 'CAI');
      expect(branch.address.countryCode, 'EG');
      // geo_lat/geo_lng are Prisma Decimal fields, which serialize to
      // strings on the wire — must still parse to double.
      expect(branch.address.geoLat, closeTo(30.044420, 1e-6));
      expect(branch.address.geoLng, closeTo(31.235712, 1e-6));
    });

    test('fromJson accepts numeric geo_lat/geo_lng too', () {
      final dto = ClinicProfileDto.fromJson({
        'id': 'c1',
        'legal_name': 'L',
        'brand_name': 'B',
        'status': 'PENDING',
        'branches': [
          {
            'id': 'b1',
            'phone': '+2010',
            'iana_timezone': 'Africa/Cairo',
            'status': 'PENDING',
            'address': {
              'line1': 'X',
              'city': 'Y',
              'region_code': 'CAI',
              'country_code': 'EG',
              'geo_lat': 30.1,
              'geo_lng': 31.2,
            },
          },
        ],
      });

      expect(dto.branches.single.address.geoLat, 30.1);
      expect(dto.branches.single.address.geoLng, 31.2);
    });

    test('fromJson defaults missing optional fields rather than throwing', () {
      final dto = ClinicProfileDto.fromJson(const {'id': 'c1'});

      expect(dto.id, 'c1');
      expect(dto.legalName, '');
      expect(dto.brandName, '');
      expect(dto.status, 'PENDING');
      expect(dto.taxId, isNull);
      expect(dto.regionCode, isNull);
      expect(dto.branches, isEmpty);
    });

    test(
      'fromJson defaults a branch missing its address to an empty address',
      () {
        final dto = ClinicProfileDto.fromJson({
          'id': 'c1',
          'legal_name': 'L',
          'brand_name': 'B',
          'status': 'VERIFIED',
          'branches': [
            {'id': 'b1', 'phone': '+2010', 'iana_timezone': 'Africa/Cairo'},
          ],
        });

        final branch = dto.branches.single;
        expect(branch.address.line1, '');
        expect(branch.address.city, '');
        expect(branch.address.geoLat, isNull);
        expect(branch.address.geoLng, isNull);
      },
    );

    test('fromJson also accepts a camelCase fallback shape', () {
      final dto = ClinicProfileDto.fromJson({
        'id': 'c1',
        'legalName': 'L',
        'brandName': 'B',
        'taxId': 'T1',
        'regionCode': 'CAI',
        'status': 'VERIFIED',
        'branches': [
          {
            'id': 'b1',
            'phone': '+2010',
            'ianaTimezone': 'Africa/Cairo',
            'status': 'VERIFIED',
            'address': {
              'line1': 'X',
              'city': 'Y',
              'regionCode': 'CAI',
              'countryCode': 'EG',
              'geoLat': 1.5,
              'geoLng': 2.5,
            },
          },
        ],
      });

      expect(dto.legalName, 'L');
      expect(dto.brandName, 'B');
      expect(dto.taxId, 'T1');
      expect(dto.regionCode, 'CAI');
      expect(dto.branches.single.ianaTimezone, 'Africa/Cairo');
      expect(dto.branches.single.address.regionCode, 'CAI');
      expect(dto.branches.single.address.countryCode, 'EG');
      expect(dto.branches.single.address.geoLat, 1.5);
      expect(dto.branches.single.address.geoLng, 2.5);
    });

    test('toEntity maps every field 1:1', () {
      final dto = ClinicProfileDto.fromJson({
        'id': 'c1',
        'legal_name': 'L',
        'brand_name': 'B',
        'tax_id': 'T1',
        'region_code': 'CAI',
        'status': 'VERIFIED',
        'branches': [
          {
            'id': 'b1',
            'phone': '+2010',
            'iana_timezone': 'Africa/Cairo',
            'status': 'VERIFIED',
            'address': {
              'line1': 'X',
              'city': 'Y',
              'region_code': 'CAI',
              'country_code': 'EG',
              'geo_lat': 1.5,
              'geo_lng': 2.5,
            },
          },
        ],
      });

      final entity = dto.toEntity();

      expect(entity.id, dto.id);
      expect(entity.legalName, dto.legalName);
      expect(entity.brandName, dto.brandName);
      expect(entity.taxId, dto.taxId);
      expect(entity.regionCode, dto.regionCode);
      expect(entity.status, dto.status);
      expect(entity.branches, hasLength(1));
      expect(entity.branches.single.id, dto.branches.single.id);
      expect(entity.branches.single.phone, dto.branches.single.phone);
      expect(
        entity.branches.single.ianaTimezone,
        dto.branches.single.ianaTimezone,
      );
      expect(
        entity.branches.single.address.line1,
        dto.branches.single.address.line1,
      );
      expect(
        entity.branches.single.address.geoLat,
        dto.branches.single.address.geoLat,
      );
    });
  });
}

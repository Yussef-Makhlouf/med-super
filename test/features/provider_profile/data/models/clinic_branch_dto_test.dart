import 'package:flutter_test/flutter_test.dart';
import 'package:med_super/features/provider_profile/data/models/clinic_branch_dto.dart';
import 'package:med_super/features/provider_profile/domain/entities/clinic_branch.dart';

void main() {
  group('ClinicBranchDto', () {
    test('fromJson parses the raw snake_case Prisma shape', () {
      final dto = ClinicBranchDto.fromJson(const {
        'id': 'branch-1',
        'clinic_id': 'clinic-1',
        'address_id': 'address-1',
        'phone': '+201234567890',
        'iana_timezone': 'Africa/Cairo',
        'status': 'VERIFIED',
        'created_at': '2024-01-01T00:00:00.000Z',
        'updated_at': '2024-02-01T00:00:00.000Z',
        'version': 3,
        'address': {
          'id': 'address-1',
          'line1': '12 Tahrir St',
          'city': 'Cairo',
          'region_code': 'CAI',
          'country_code': 'EG',
          'geo_lat': 30.05,
          'geo_lng': 31.23,
        },
        'clinic': {
          'id': 'clinic-1',
          'legal_name': 'Nile Medical Group LLC',
          'brand_name': 'Nile Medical',
          'tax_id': 'TAX-123',
          'region_code': 'CAI',
          'status': 'VERIFIED',
        },
      });

      expect(dto.id, 'branch-1');
      expect(dto.clinicId, 'clinic-1');
      expect(dto.phone, '+201234567890');
      expect(dto.ianaTimezone, 'Africa/Cairo');
      expect(dto.status, ClinicBranchStatus.verified);
      expect(dto.createdAt, DateTime.parse('2024-01-01T00:00:00.000Z'));
      expect(dto.updatedAt, DateTime.parse('2024-02-01T00:00:00.000Z'));

      expect(dto.address.line1, '12 Tahrir St');
      expect(dto.address.city, 'Cairo');
      expect(dto.address.regionCode, 'CAI');
      expect(dto.address.countryCode, 'EG');
      expect(dto.address.geoLat, 30.05);
      expect(dto.address.geoLng, 31.23);

      expect(dto.clinic.id, 'clinic-1');
      expect(dto.clinic.legalName, 'Nile Medical Group LLC');
      expect(dto.clinic.brandName, 'Nile Medical');
      expect(dto.clinic.taxId, 'TAX-123');
      expect(dto.clinic.regionCode, 'CAI');
      expect(dto.clinic.status, ClinicBranchStatus.verified);
    });

    test('fromJson accepts lowercase status values', () {
      final dto = ClinicBranchDto.fromJson(const {
        'id': 'branch-1',
        'status': 'suspended',
      });

      expect(dto.status, ClinicBranchStatus.suspended);
    });

    test('fromJson defaults an unknown/missing status to pending', () {
      final missing = ClinicBranchDto.fromJson(const {'id': 'branch-1'});
      final unknown = ClinicBranchDto.fromJson(const {
        'id': 'branch-1',
        'status': 'SOMETHING_ELSE',
      });

      expect(missing.status, ClinicBranchStatus.pending);
      expect(unknown.status, ClinicBranchStatus.pending);
    });

    test(
      'fromJson falls back to safe defaults when fields/relations are missing',
      () {
        final dto = ClinicBranchDto.fromJson(const {});

        expect(dto.id, '');
        expect(dto.clinicId, '');
        expect(dto.phone, '');
        expect(dto.ianaTimezone, '');
        expect(dto.status, ClinicBranchStatus.pending);
        expect(dto.createdAt, isNull);
        expect(dto.updatedAt, isNull);

        expect(dto.address.line1, '');
        expect(dto.address.city, '');
        expect(dto.address.regionCode, '');
        expect(dto.address.countryCode, '');
        expect(dto.address.geoLat, isNull);
        expect(dto.address.geoLng, isNull);

        expect(dto.clinic.id, '');
        expect(dto.clinic.legalName, '');
        expect(dto.clinic.brandName, '');
        expect(dto.clinic.taxId, isNull);
        expect(dto.clinic.regionCode, isNull);
        expect(dto.clinic.status, ClinicBranchStatus.pending);
      },
    );

    test('fromJson accepts int json values for geo double fields', () {
      final dto = ClinicBranchDto.fromJson(const {
        'id': 'branch-1',
        'address': {'geo_lat': 30, 'geo_lng': 31},
      });

      expect(dto.address.geoLat, 30.0);
      expect(dto.address.geoLng, 31.0);
    });

    test('toEntity maps every field 1:1', () {
      final dto = ClinicBranchDto.fromJson(const {
        'id': 'branch-1',
        'clinic_id': 'clinic-1',
        'phone': '+201234567890',
        'iana_timezone': 'Africa/Cairo',
        'status': 'VERIFIED',
        'address': {
          'line1': '12 Tahrir St',
          'city': 'Cairo',
          'region_code': 'CAI',
          'country_code': 'EG',
        },
        'clinic': {
          'id': 'clinic-1',
          'legal_name': 'Nile Medical Group LLC',
          'brand_name': 'Nile Medical',
          'status': 'VERIFIED',
        },
      });

      final entity = dto.toEntity();

      expect(entity.id, dto.id);
      expect(entity.clinicId, dto.clinicId);
      expect(entity.phone, dto.phone);
      expect(entity.ianaTimezone, dto.ianaTimezone);
      expect(entity.status, dto.status);
      expect(entity.address.line1, dto.address.line1);
      expect(entity.clinic.brandName, dto.clinic.brandName);
    });
  });
}

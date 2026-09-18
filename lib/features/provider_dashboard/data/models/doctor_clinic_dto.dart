import '../../domain/entities/doctor_clinic.dart';

/// Wire model for `GET /v1/doctors/me/clinics` and the two PATCH routes
/// under it (File 12 Part 49.2-49.4). All three return the same row shape.
class DoctorClinicDto {
  const DoctorClinicDto({
    required this.affiliationId,
    required this.affiliationStatus,
    required this.consultFee,
    required this.currency,
    required this.clinicId,
    required this.clinicName,
    required this.clinicStatus,
    required this.clinicBranchId,
    required this.branchStatus,
    required this.phone,
    required this.ianaTimezone,
    required this.addressLine1,
    required this.addressCity,
    required this.addressRegionCode,
    required this.addressCountryCode,
  });

  factory DoctorClinicDto.fromJson(Map<String, dynamic> json) {
    final address = (json['address'] as Map<String, dynamic>?) ?? const {};
    return DoctorClinicDto(
      affiliationId: json['affiliationId'] as String? ?? '',
      affiliationStatus: json['affiliationStatus'] as String? ?? '',
      consultFee: json['consultFee'] as String? ?? '0.00',
      currency: json['currency'] as String? ?? 'EGP',
      clinicId: json['clinicId'] as String? ?? '',
      clinicName: json['clinicName'] as String? ?? '',
      clinicStatus: json['clinicStatus'] as String? ?? '',
      clinicBranchId: json['clinicBranchId'] as String? ?? '',
      branchStatus: json['branchStatus'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      ianaTimezone: json['ianaTimezone'] as String? ?? 'UTC',
      addressLine1: address['line1'] as String? ?? '',
      addressCity: address['city'] as String? ?? '',
      addressRegionCode: address['regionCode'] as String? ?? '',
      addressCountryCode: address['countryCode'] as String? ?? '',
    );
  }

  final String affiliationId;
  final String affiliationStatus;
  final String consultFee;
  final String currency;
  final String clinicId;
  final String clinicName;
  final String clinicStatus;
  final String clinicBranchId;
  final String branchStatus;
  final String phone;
  final String ianaTimezone;
  final String addressLine1;
  final String addressCity;
  final String addressRegionCode;
  final String addressCountryCode;

  DoctorClinic toEntity() => DoctorClinic(
    affiliationId: affiliationId,
    affiliationStatus: affiliationStatusFromWire(affiliationStatus),
    consultFee: consultFee,
    currency: currency,
    clinicId: clinicId,
    clinicName: clinicName,
    clinicStatus: providerVerificationStatusFromWire(clinicStatus),
    clinicBranchId: clinicBranchId,
    branchStatus: providerVerificationStatusFromWire(branchStatus),
    phone: phone,
    ianaTimezone: ianaTimezone,
    address: ClinicAddress(
      line1: addressLine1,
      city: addressCity,
      regionCode: addressRegionCode,
      countryCode: addressCountryCode,
    ),
  );
}

/// Body for `PATCH /v1/doctors/me/clinics/branches/{branchId}`.
///
/// Only the operational fields the backend actually accepts are serialised —
/// sending anything else is rejected outright by the server's
/// `forbidNonWhitelisted` validation pipe (a `400`, not a silent drop), so
/// this must not carry `status`, `regionCode` or `countryCode`.
class UpdateDoctorBranchRequestDto {
  const UpdateDoctorBranchRequestDto({
    this.phone,
    this.ianaTimezone,
    this.addressLine1,
    this.addressCity,
  });

  final String? phone;
  final String? ianaTimezone;
  final String? addressLine1;
  final String? addressCity;

  bool get isEmpty =>
      phone == null &&
      ianaTimezone == null &&
      addressLine1 == null &&
      addressCity == null;

  Map<String, dynamic> toJson() {
    final address = <String, dynamic>{
      if (addressLine1 != null) 'line1': addressLine1,
      if (addressCity != null) 'city': addressCity,
    };
    return {
      if (phone != null) 'phone': phone,
      if (ianaTimezone != null) 'ianaTimezone': ianaTimezone,
      if (address.isNotEmpty) 'address': address,
    };
  }
}

class CreateDoctorBranchRequestDto {
  const CreateDoctorBranchRequestDto({
    required this.phone,
    required this.ianaTimezone,
    required this.line1,
    required this.city,
    required this.regionCode,
    required this.countryCode,
    required this.consultFee,
  });

  final String phone;
  final String ianaTimezone;
  final String line1;
  final String city;
  final String regionCode;
  final String countryCode;
  final double consultFee;

  Map<String, dynamic> toJson() => {
    'phone': phone,
    'ianaTimezone': ianaTimezone,
    'consultFee': consultFee,
    'address': {
      'line1': line1,
      'city': city,
      'regionCode': regionCode,
      'countryCode': countryCode,
    },
  };
}

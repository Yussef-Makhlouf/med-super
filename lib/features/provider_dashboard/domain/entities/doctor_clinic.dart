/// Verification lifecycle shared by clinics and branches
/// (`provider_status_enum`). A doctor cannot change this — only an Admin can
/// (File 11 07.3) — but the dashboard shows it, because an unverified or
/// suspended branch is the most common reason a doctor's slots stop being
/// generated.
enum ProviderVerificationStatus { pending, verified, suspended, other }

/// Whether the doctor is currently practising at this branch
/// (`doctor_clinic_affiliations_status_enum`). Pausing is the only
/// deactivation the doctor surface offers — nothing here deletes.
enum AffiliationStatus { active, paused, other }

ProviderVerificationStatus providerVerificationStatusFromWire(String? value) =>
    switch (value?.toUpperCase()) {
      'PENDING' => ProviderVerificationStatus.pending,
      'VERIFIED' => ProviderVerificationStatus.verified,
      'SUSPENDED' => ProviderVerificationStatus.suspended,
      _ => ProviderVerificationStatus.other,
    };

AffiliationStatus affiliationStatusFromWire(String? value) =>
    switch (value?.toUpperCase()) {
      'ACTIVE' => AffiliationStatus.active,
      'PAUSED' => AffiliationStatus.paused,
      _ => AffiliationStatus.other,
    };

class ClinicAddress {
  const ClinicAddress({
    required this.line1,
    required this.city,
    required this.regionCode,
    required this.countryCode,
  });

  final String line1;
  final String city;

  /// Read-only on this surface — region/country partition search results, so
  /// they stay on the Admin-only branch endpoint (File 12 Part 49.3).
  final String regionCode;
  final String countryCode;

  ClinicAddress copyWith({String? line1, String? city}) => ClinicAddress(
    line1: line1 ?? this.line1,
    city: city ?? this.city,
    regionCode: regionCode,
    countryCode: countryCode,
  );
}

/// One clinic/branch the authenticated doctor is affiliated with
/// (`GET /v1/doctors/me/clinics`, File 12 Part 49.2).
///
/// This replaces the mock-only `ClinicSettings`, which modelled a single
/// hardcoded clinic with an `email` field no clinic table has. A doctor can
/// be affiliated with several branches, so this is a list, not a singleton.
///
/// The clinic's legal name and tax id are intentionally absent: a doctor
/// affiliated with a clinic is not its legal operator, and the endpoint does
/// not return them.
class DoctorClinic {
  const DoctorClinic({
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
    required this.address,
  });

  final String affiliationId;
  final AffiliationStatus affiliationStatus;

  /// Editable by the doctor via `SetMyAffiliationActiveUseCase` (the doctor
  /// owns the commercial fee; the Admin only verifies license/documents —
  /// File 12 Part 49.4).
  final String consultFee;
  final String currency;

  final String clinicId;
  final String clinicName;
  final ProviderVerificationStatus clinicStatus;

  final String clinicBranchId;
  final ProviderVerificationStatus branchStatus;

  /// Editable operational fields.
  final String phone;
  final String ianaTimezone;
  final ClinicAddress address;

  /// `clinicName` alone is shared by every branch of the same clinic, so a
  /// doctor with two branches of "عيادة النيل" would otherwise see the exact
  /// same label twice in any list/dropdown. This appends the branch's own
  /// city — real per-branch data (`address`), not something shared — to make
  /// each entry distinct.
  String get displayTitle => '$clinicName — ${address.city}';

  /// Slots are only generated for an ACTIVE affiliation at a VERIFIED branch
  /// of a VERIFIED clinic (the Part 32 visibility chain). Surfacing this lets
  /// the dashboard explain an empty calendar instead of looking broken.
  bool get isAcceptingBookings =>
      affiliationStatus == AffiliationStatus.active &&
      branchStatus == ProviderVerificationStatus.verified &&
      clinicStatus == ProviderVerificationStatus.verified;

  DoctorClinic copyWith({String? phone, String? ianaTimezone, ClinicAddress? address, AffiliationStatus? affiliationStatus}) =>
      DoctorClinic(
        affiliationId: affiliationId,
        affiliationStatus: affiliationStatus ?? this.affiliationStatus,
        consultFee: consultFee,
        currency: currency,
        clinicId: clinicId,
        clinicName: clinicName,
        clinicStatus: clinicStatus,
        clinicBranchId: clinicBranchId,
        branchStatus: branchStatus,
        phone: phone ?? this.phone,
        ianaTimezone: ianaTimezone ?? this.ianaTimezone,
        address: address ?? this.address,
      );
}

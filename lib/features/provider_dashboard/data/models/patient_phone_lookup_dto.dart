/// Wire model for `GET /v1/doctors/me/appointments/patients/lookup?phone=...`
/// (backend `LookupPatientByPhoneResult`).
class PatientPhoneLookupDto {
  const PatientPhoneLookupDto({required this.exists, this.name});

  factory PatientPhoneLookupDto.fromJson(Map<String, dynamic> json) {
    return PatientPhoneLookupDto(
      exists: json['exists'] as bool? ?? false,
      name: json['name'] as String?,
    );
  }

  final bool exists;
  final String? name;
}

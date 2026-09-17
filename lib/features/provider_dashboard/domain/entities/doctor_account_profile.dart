/// `GET /v1/doctors/me` — a doctor's own directory record
/// (`clinic-reservations` File 12 Part 45). Replaces the previous
/// entirely-invented `/v1/provider/me` shape.
///
/// `hospitalName` was dropped (2026-08-31) — no clinic-affiliation join
/// exists in the real endpoint's response, so it had nothing to be backed
/// by; showing one would mean fabricating data. `licenseNumber`/`degree`
/// are new, real fields; `specialty` stays read-only (Admin-only to change,
/// same as `licenseNumber`).
class DoctorAccountProfile {
  const DoctorAccountProfile({
    required this.id,
    required this.name,
    required this.specialty,
    required this.licenseNumber,
    required this.phone,
    this.email,
    this.avatarUrl,
    this.degree,
    this.yearsOfExperience,
    this.bio = '',
    this.isVerified = false,
  });

  final String id;
  final String name;
  final String specialty;
  final String licenseNumber;
  final String phone;
  final String? email;
  final String? avatarUrl;
  final String? degree;
  final int? yearsOfExperience;
  final String bio;
  final bool isVerified;

  DoctorAccountProfile copyWith({
    String? id,
    String? name,
    String? specialty,
    String? licenseNumber,
    String? phone,
    String? email,
    String? avatarUrl,
    String? degree,
    int? yearsOfExperience,
    String? bio,
    bool? isVerified,
  }) {
    return DoctorAccountProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      specialty: specialty ?? this.specialty,
      licenseNumber: licenseNumber ?? this.licenseNumber,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      degree: degree ?? this.degree,
      yearsOfExperience: yearsOfExperience ?? this.yearsOfExperience,
      bio: bio ?? this.bio,
      isVerified: isVerified ?? this.isVerified,
    );
  }
}

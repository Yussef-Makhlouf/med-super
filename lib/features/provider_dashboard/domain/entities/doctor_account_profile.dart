class DoctorAccountProfile {
  const DoctorAccountProfile({
    required this.id,
    required this.name,
    required this.specialty,
    required this.hospitalName,
    this.avatarUrl,
  });

  final String id;
  final String name;
  final String specialty;
  final String hospitalName;
  final String? avatarUrl;
}

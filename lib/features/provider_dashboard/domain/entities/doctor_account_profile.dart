class DoctorAccountProfile {
  const DoctorAccountProfile({
    required this.id,
    required this.name,
    required this.specialty,
    required this.hospitalName,
    this.avatarUrl,
    this.yearsOfExperience = 10,
    this.bio = '',
  });

  final String id;
  final String name;
  final String specialty;
  final String hospitalName;
  final String? avatarUrl;
  final int yearsOfExperience;
  final String bio;

  DoctorAccountProfile copyWith({
    String? id,
    String? name,
    String? specialty,
    String? hospitalName,
    String? avatarUrl,
    int? yearsOfExperience,
    String? bio,
  }) {
    return DoctorAccountProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      specialty: specialty ?? this.specialty,
      hospitalName: hospitalName ?? this.hospitalName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      yearsOfExperience: yearsOfExperience ?? this.yearsOfExperience,
      bio: bio ?? this.bio,
    );
  }
}

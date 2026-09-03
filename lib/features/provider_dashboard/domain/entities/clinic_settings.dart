class ClinicSettings {
  const ClinicSettings({
    required this.clinicName,
    required this.address,
    required this.phone,
    required this.email,
    this.city = 'الرياض',
  });

  final String clinicName;
  final String address;
  final String phone;
  final String email;
  final String city;

  ClinicSettings copyWith({
    String? clinicName,
    String? address,
    String? phone,
    String? email,
    String? city,
  }) {
    return ClinicSettings(
      clinicName: clinicName ?? this.clinicName,
      address: address ?? this.address,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      city: city ?? this.city,
    );
  }
}

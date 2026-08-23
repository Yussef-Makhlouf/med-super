import '../../domain/entities/clinic_settings.dart';

class ClinicSettingsDto {
  const ClinicSettingsDto({
    required this.clinicName,
    required this.address,
    required this.phone,
    required this.email,
    required this.city,
  });

  factory ClinicSettingsDto.fromJson(Map<String, dynamic> json) {
    return ClinicSettingsDto(
      clinicName: json['clinic_name'] as String? ?? 'مستشفى الملك فيصل التخصصي',
      address: json['address'] as String? ?? 'شارع التخصصي، الرياض',
      phone: json['phone'] as String? ?? '+20221234567',
      email: json['email'] as String? ?? 'info@kfshrc.edu.sa',
      city: json['city'] as String? ?? 'الرياض',
    );
  }

  final String clinicName;
  final String address;
  final String phone;
  final String email;
  final String city;

  Map<String, dynamic> toJson() => {
    'clinic_name': clinicName,
    'address': address,
    'phone': phone,
    'email': email,
    'city': city,
  };

  ClinicSettings toEntity() {
    return ClinicSettings(
      clinicName: clinicName,
      address: address,
      phone: phone,
      email: email,
      city: city,
    );
  }
}

class Patient {
  const Patient({
    required this.id,
    required this.name,
    required this.medId,
    this.avatarUrl,
    required this.status,
    required this.nextAppointment,
  });

  final String id;
  final String name;
  final String medId;
  final String? avatarUrl;
  final String status;
  final DateTime nextAppointment;
}

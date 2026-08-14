import 'doctor_summary.dart';

class DoctorSearchResult {
  const DoctorSearchResult({required this.doctors, required this.totalCount});

  final List<DoctorSummary> doctors;
  final int totalCount;
}

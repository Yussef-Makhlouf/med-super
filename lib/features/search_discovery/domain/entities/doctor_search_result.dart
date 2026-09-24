import 'doctor_summary.dart';

class DoctorSearchResult {
  const DoctorSearchResult({
    required this.doctors,
    required this.totalCount,
    this.nextCursor,
  });

  final List<DoctorSummary> doctors;
  final int totalCount;

  /// Opaque cursor for the next page (API_RULES.md: cursor-based pagination
  /// only). Null means there is no further page.
  final String? nextCursor;
}

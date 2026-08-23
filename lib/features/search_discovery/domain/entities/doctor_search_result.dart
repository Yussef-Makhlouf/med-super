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
  /// only). Null means there is no further page. Not yet consumed by any
  /// "load more" UI — the data layer is contract-correct even though no
  /// screen currently requests a second page.
  final String? nextCursor;
}

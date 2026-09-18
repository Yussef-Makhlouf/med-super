import 'package:med_super/core/error/result.dart';
import 'package:med_super/features/search_discovery/domain/entities/doctor_search_result.dart';
import 'package:med_super/features/search_discovery/domain/entities/doctor_sort.dart';

abstract class DoctorSearchRepository {
  /// [latitude]/[longitude]/[radiusKm]/[date] are accepted and forwarded to
  /// the real backend contract (05_API_RULES.md / 04_API_CONTRACT.md) but no
  /// current screen supplies them yet (no location-picker/date-picker wired
  /// into search) — plumbed through so the contract is complete without
  /// inventing UI that doesn't exist.
  Future<Result<DoctorSearchResult>> searchDoctors({
    String? query,
    String? specialty,
    DoctorSort sort = DoctorSort.topRated,
    double? latitude,
    double? longitude,
    double? radiusKm,
    DateTime? date,
    String? cursor,
    int limit = 20,
  });
}

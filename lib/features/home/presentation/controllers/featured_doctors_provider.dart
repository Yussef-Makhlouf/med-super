import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:med_super/features/search_discovery/domain/entities/doctor_search_result.dart';
import 'package:med_super/features/search_discovery/domain/entities/doctor_sort.dart';
import 'package:med_super/features/search_discovery/domain/entities/doctor_summary.dart';
import 'package:med_super/features/search_discovery/presentation/controllers/search_providers.dart';

const _featuredDoctorsLimit = 5;

/// Plain `FutureProvider` (no `@riverpod` codegen — see
/// `doctor_availability_providers.dart` for the same convention) backing the
/// home screen's "nearby doctors" row. Reuses the same `SearchDoctorsUseCase`
/// as `search_discovery` with no query/specialty filter, top-rated first,
/// capped to a short list — this is a preview row, not the full search
/// results screen.
final featuredDoctorsProvider = FutureProvider<List<DoctorSummary>>((
  ref,
) async {
  final result = await ref
      .watch(searchDoctorsUseCaseProvider)
      .call(sort: DoctorSort.topRated, limit: _featuredDoctorsLimit);
  final DoctorSearchResult searchResult = result.when(
    ok: (value) => value,
    err: (failure) => throw failure,
  );
  return searchResult.doctors;
});

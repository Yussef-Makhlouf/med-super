import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:med_super/core/constants/api_paths.dart';
import 'package:med_super/core/di/core_providers.dart';
import 'package:med_super/features/provider_registration/domain/entities/lookup_item.dart';

part 'registration_lookups_providers.g.dart';

List<LookupItem> _parseLookupList(dynamic raw) =>
    (raw as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(
          (j) => LookupItem(id: j['id'] as String, label: j['label'] as String),
        )
        .toList();

/// Specialties + cities fetched once from the mock/API catalog — never
/// hardcoded inside a screen.
@riverpod
Future<({List<LookupItem> specialties, List<LookupItem> cities})>
registrationLookups(Ref ref) async {
  final response = await ref
      .watch(dioProvider)
      .get<Map<String, dynamic>>(ApiPaths.providerRegistrationLookups);
  final data = response.data ?? const {};
  return (
    specialties: _parseLookupList(data['specialties']),
    cities: _parseLookupList(data['cities']),
  );
}

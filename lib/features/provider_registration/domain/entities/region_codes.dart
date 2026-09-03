import 'lookup_item.dart';

/// No `region_code` lookup exists on the backend yet (`Address.region_code`
/// is a free-text string with no enum/table behind it) — this hardcoded
/// governorate list is a client-side convention only, matching the values
/// already used in backend seed/test data (e.g. `CAI`, `ALX`).
const kRegionCodes = [
  LookupItem(id: 'CAI', label: 'Cairo'),
  LookupItem(id: 'GIZ', label: 'Giza'),
  LookupItem(id: 'ALX', label: 'Alexandria'),
  LookupItem(id: 'QAL', label: 'Qalyubia'),
  LookupItem(id: 'DAK', label: 'Dakahlia'),
  LookupItem(id: 'SHR', label: 'Sharqia'),
  LookupItem(id: 'GHR', label: 'Gharbia'),
  LookupItem(id: 'ASN', label: 'Aswan'),
];

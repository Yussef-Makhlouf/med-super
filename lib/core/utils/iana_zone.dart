import 'package:timezone/data/latest_10y.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

bool _initialized = false;

/// Resolves a clinic branch's `ianaTimezone` (e.g. `Africa/Cairo`) with real
/// IANA rules, including Egypt's DST (reinstated 2023). Returns `null` for a
/// missing or unknown zone so callers can label times as UTC instead of
/// guessing. Never use the device zone as a stand-in for the clinic's.
tz.Location? ianaLocation(String? ianaTimezone) {
  if (ianaTimezone == null || ianaTimezone.isEmpty) return null;
  if (!_initialized) {
    tzdata.initializeTimeZones();
    _initialized = true;
  }
  try {
    return tz.getLocation(ianaTimezone);
  } on tz.LocationNotFoundException {
    return null;
  }
}

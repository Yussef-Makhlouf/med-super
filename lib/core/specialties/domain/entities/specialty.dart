/// A medical specialty from the provider directory's static seed data
/// (`GET /v1/specialties` — public, no auth; clinic-reservations
/// `provider-directory` module). Shared between `home` (the specialties
/// row) and `search_discovery` (the specialty filter), so it lives under
/// `core/` rather than duplicated into either feature.
class Specialty {
  const Specialty({
    required this.code,
    required this.nameEn,
    required this.nameAr,
    this.parentCode,
  });

  /// Stable identifier — also the value sent back to the backend as the
  /// `specialty` query parameter on `GET /v1/doctors/search`.
  final String code;
  final String nameEn;
  final String nameAr;
  final String? parentCode;

  /// Picks the display name for [languageCode] ('ar' vs. everything else,
  /// matching how `context.locale.languageCode` is used across the app).
  String localizedName(String languageCode) =>
      languageCode == 'ar' && nameAr.isNotEmpty ? nameAr : nameEn;

  /// Resolves a doctor-row specialty for the current locale.
  ///
  /// Doctor search/detail return a single English `specialty` string (and
  /// sometimes a `specialtyKey` code). The specialties catalog from
  /// `GET /v1/specialties` is the source of `name_ar` / `name_en`. Match
  /// by [code] first, then by [fallback] against `nameEn`/`code`, and keep
  /// [fallback] if the catalog has no row (unknown specialty, catalog
  /// still loading).
  static String resolveLabel({
    required Iterable<Specialty> catalog,
    required String languageCode,
    String? code,
    required String fallback,
  }) {
    return findIn(
          catalog,
          code: code,
          name: fallback,
        )?.localizedName(languageCode) ??
        fallback;
  }

  static Specialty? findIn(
    Iterable<Specialty> catalog, {
    String? code,
    String? name,
  }) {
    if (code != null && code.isNotEmpty) {
      final needle = code.toUpperCase();
      for (final specialty in catalog) {
        if (specialty.code.toUpperCase() == needle) return specialty;
      }
    }
    final trimmed = name?.trim() ?? '';
    if (trimmed.isEmpty) return null;
    final needle = trimmed.toLowerCase();
    for (final specialty in catalog) {
      if (specialty.nameEn.toLowerCase() == needle ||
          specialty.code.toLowerCase() == needle ||
          specialty.nameAr == trimmed) {
        return specialty;
      }
    }
    return null;
  }

  @override
  bool operator ==(Object other) =>
      other is Specialty &&
      other.code == code &&
      other.nameEn == nameEn &&
      other.nameAr == nameAr &&
      other.parentCode == parentCode;

  @override
  int get hashCode => Object.hash(code, nameEn, nameAr, parentCode);
}

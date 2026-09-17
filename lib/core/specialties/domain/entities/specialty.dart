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

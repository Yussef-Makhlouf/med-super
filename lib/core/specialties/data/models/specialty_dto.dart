import 'package:med_super/core/specialties/domain/entities/specialty.dart';

class SpecialtyDto {
  const SpecialtyDto({
    required this.code,
    required this.nameAr,
    this.parentCode,
  });

  final String code;
  final String nameAr;
  final String? parentCode;

  /// Backend shape (prisma/schema/provider-directory.prisma's `Specialty`
  /// model, returned verbatim by `ListSpecialtiesUseCase`): snake_case
  /// `{code, name_ar, parent_code, created_at, updated_at,
  /// version}`. `created_at`/`updated_at`/`version` aren't needed client
  /// side and are intentionally not modeled here.
  factory SpecialtyDto.fromJson(Map<String, dynamic> json) => SpecialtyDto(
    code: json['code'] as String? ?? '',
    nameAr: (json['name_ar'] ?? json['nameAr']) as String? ?? '',
    parentCode: (json['parent_code'] ?? json['parentCode']) as String?,
  );

  Specialty toEntity() => Specialty(
    code: code,
    nameAr: nameAr,
    parentCode: parentCode,
  );
}

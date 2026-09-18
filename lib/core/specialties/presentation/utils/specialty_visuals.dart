import 'package:flutter/material.dart';
import 'package:med_super/core/theme/color_schemes.dart';

/// Client-side icon/color for a specialty row — the backend's static seed
/// data (`Specialty.code`) carries no visual metadata, so this maps a few
/// well-known codes to the icons the design already used, falling back to a
/// neutral default for anything else (new specialties added server-side
/// show up automatically, just without a bespoke icon).
class SpecialtyVisual {
  const SpecialtyVisual({required this.icon, required this.color});

  final IconData icon;
  final Color color;
}

const _defaultVisual = SpecialtyVisual(
  icon: Icons.medical_services_outlined,
  color: brandBlue,
);

// Keys are matched in insertion order (first `code.contains(key)` wins), so
// more specific/earlier keys shadow looser ones added later — e.g. 'NEURO'
// must stay ahead of 'UROLOGY' below, since "NEUROLOGY".contains('UROLOGY')
// is also true. The bare 3-letter 'ENT' key that used to live here was
// removed for the same reason: it silently matched "GASTROENTEROLOGY" too.
const _visualsByKeyword = <String, SpecialtyVisual>{
  'CARDIO': SpecialtyVisual(icon: Icons.favorite, color: Color(0xFFEF4444)),
  'PEDIA': SpecialtyVisual(icon: Icons.child_care, color: Color(0xFF06B6D4)),
  'CHILD': SpecialtyVisual(icon: Icons.child_care, color: Color(0xFF06B6D4)),
  'DERMA': SpecialtyVisual(icon: Icons.spa_outlined, color: Color(0xFF14B8A6)),
  'SKIN': SpecialtyVisual(icon: Icons.spa_outlined, color: Color(0xFF14B8A6)),
  'DENTAL': SpecialtyVisual(icon: Icons.medical_services_outlined, color: brandBlue),
  'DENT': SpecialtyVisual(icon: Icons.medical_services_outlined, color: brandBlue),
  'OPHTHALM': SpecialtyVisual(
    icon: Icons.visibility_outlined,
    color: Color(0xFFF97316),
  ),
  'EYE': SpecialtyVisual(icon: Icons.visibility_outlined, color: Color(0xFFF97316)),
  'ORTHO': SpecialtyVisual(icon: Icons.accessibility_new, color: Color(0xFF8B5CF6)),
  'NEURO': SpecialtyVisual(icon: Icons.psychology_outlined, color: Color(0xFF6366F1)),
  'OTOLARYNGOLOGY': SpecialtyVisual(icon: Icons.hearing_outlined, color: Color(0xFF0EA5E9)),
  'GYN': SpecialtyVisual(icon: Icons.pregnant_woman_outlined, color: Color(0xFFEC4899)),
  'PSYCH': SpecialtyVisual(icon: Icons.psychology_alt_outlined, color: Color(0xFF8B5CF6)),
  'GENERAL': SpecialtyVisual(icon: Icons.local_hospital_outlined, color: brandBlue),
  'UROLOGY': SpecialtyVisual(icon: Icons.water_drop_outlined, color: Color(0xFF0891B2)),
  'ENDOCRINOLOGY': SpecialtyVisual(icon: Icons.science_outlined, color: Color(0xFFF59E0B)),
  'GASTROENTEROLOGY': SpecialtyVisual(icon: Icons.restaurant_outlined, color: Color(0xFF84CC16)),
  'PULMONOLOGY': SpecialtyVisual(icon: Icons.air_outlined, color: Color(0xFF3B82F6)),
  'RHEUMAT': SpecialtyVisual(icon: Icons.healing_outlined, color: Color(0xFFF43F5E)),
  'HEMAT': SpecialtyVisual(icon: Icons.bloodtype_outlined, color: Color(0xFFDC2626)),
  'NEPHR': SpecialtyVisual(icon: Icons.filter_alt_outlined, color: Color(0xFF22D3EE)),
  'ALLERGY': SpecialtyVisual(icon: Icons.local_florist_outlined, color: Color(0xFFA855F7)),
  'FAMILY': SpecialtyVisual(icon: Icons.family_restroom_outlined, color: Color(0xFF16A34A)),
  'INTERNAL': SpecialtyVisual(icon: Icons.health_and_safety_outlined, color: Color(0xFF64748B)),
};

SpecialtyVisual specialtyVisualForCode(String code) {
  final normalized = code.toUpperCase();
  for (final entry in _visualsByKeyword.entries) {
    if (normalized.contains(entry.key)) return entry.value;
  }
  return _defaultVisual;
}

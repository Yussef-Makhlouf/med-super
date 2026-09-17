import 'package:flutter/material.dart';

/// Design tokens matching the Figma "Healthcare Platform" file exactly.
/// Used exclusively by the new Lab Booking + Provider Registration features.
/// Existing Sprint 0/1/2 screens keep their own local colors untouched.
abstract final class AppColors {
  // Flavor accents
  static const patientPrimary = Color(0xFF2563EB);
  static const providerPrimary = Color(0xFF004AC6);

  // Neutral text
  static const ink900 = Color(0xFF191C1E);
  static const ink700 = Color(0xFF0F172A);
  static const bodyText = Color(0xFF434655);
  static const mutedText = Color(0xFF737686);
  static const mutedText2 = Color(0xFF64748B);
  static const placeholderText = Color(0xFF6B7280);

  // Borders / surfaces
  static const borderLight = Color(0xFFE0E3E5);
  static const borderMedium = Color(0xFFC3C6D7);
  static const borderSubtle = Color(0x4DC3C6D7);
  static const surfaceApp = Color(0xFFF8FAFC);
  static const surfaceCard = Color(0xFFF2F4F6);
  static const surfaceMuted = Color(0xFFECEEF0);
  static const surfaceReviewCardBorder = Color(0xFFF2F4F6);

  // Semantic
  static const errorRed = Color(0xFFBA1A1A);
  static const ratingAmber = Color(0xFFF59E0B);
  static const tealAccent = Color(0xFF0F766E);
  static const tealBg = Color(0x1A0F766E);
  static const infoTealBg = Color(0x3399EFE5);
  static const infoTealIcon = Color(0xFF99EFE5);
  static const infoTealText = Color(0xFF006F67);

  // Warning / important-instructions banner (peach/orange)
  static const warningAmberBg = Color(0xFFFDF2E9);
  static const warningAmberBorder = Color(0xFFFBE0C4);
  static const warningAmberText = Color(0xFFB45309);
}

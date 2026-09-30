import 'package:flutter/material.dart';
import 'app_palette.dart';
import 'app_radii.dart';
import 'color_schemes.dart';
import 'typography.dart';

class AppTheme {
  AppTheme._();

  static ThemeData light() => ThemeData(
    useMaterial3: true,
    colorScheme: lightColorScheme,
    scaffoldBackgroundColor: AppPalette.paper,
    textTheme: buildTextTheme(brightness: Brightness.light),
    visualDensity: VisualDensity.standard,
    materialTapTargetSize: MaterialTapTargetSize.padded,
    appBarTheme: AppBarTheme(
      centerTitle: false,
      backgroundColor: AppPalette.paper,
      foregroundColor: lightColorScheme.onSurface,
      elevation: 0,
      scrolledUnderElevation: 1,
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadii.md),
        borderSide: BorderSide(color: AppPalette.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadii.md),
        borderSide: BorderSide(color: AppPalette.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadii.md),
        borderSide: const BorderSide(color: AppPalette.primary, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      filled: true,
      fillColor: AppPalette.surface,
      hintStyle: const TextStyle(color: AppPalette.inkFaint),
      errorStyle: const TextStyle(
        color: AppPalette.error,
        fontWeight: FontWeight.w600,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(64, 52),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.lg),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(64, 52),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.lg),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(64, 52),
        side: const BorderSide(color: AppPalette.border),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.lg),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        minimumSize: const Size(48, 48),
        foregroundColor: AppPalette.primary,
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
      ),
    ),
    dividerTheme: const DividerThemeData(
      color: AppPalette.border,
      thickness: 1,
      space: 1,
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: AppPalette.primary,
      linearTrackColor: AppPalette.primarySoft,
      circularTrackColor: AppPalette.primarySoft,
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: AppPalette.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.xl),
      ),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: AppPalette.surface,
      surfaceTintColor: Colors.transparent,
      showDragHandle: true,
      dragHandleColor: AppPalette.inkFaint,
      dragHandleSize: Size(36, 4),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: AppPalette.ink,
      contentTextStyle: const TextStyle(color: Colors.white, fontSize: 14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.md),
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: AppPalette.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.lg),
        side: BorderSide(color: AppPalette.border.withValues(alpha: 0.72)),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Colors.white,
      indicatorColor: AppPalette.primarySoft,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      height: 68,
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      indicatorShape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.md),
      ),
      iconTheme: WidgetStateProperty.resolveWith(
        (states) => IconThemeData(
          size: 23,
          color: states.contains(WidgetState.selected)
              ? AppPalette.primary
              : AppPalette.inkFaint,
        ),
      ),
      labelTextStyle: WidgetStateProperty.resolveWith(
        (states) => TextStyle(
          fontSize: 12,
          fontWeight: states.contains(WidgetState.selected)
              ? FontWeight.w700
              : FontWeight.w500,
          color: states.contains(WidgetState.selected)
              ? AppPalette.primary
              : AppPalette.inkMuted,
        ),
      ),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      type: BottomNavigationBarType.fixed,
      selectedLabelStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
      unselectedLabelStyle: TextStyle(fontSize: 12),
    ),
  );

  static ThemeData dark() => ThemeData(
    useMaterial3: true,
    colorScheme: darkColorScheme,
    textTheme: buildTextTheme(brightness: Brightness.dark),
    appBarTheme: AppBarTheme(
      centerTitle: false,
      backgroundColor: darkColorScheme.surface,
      foregroundColor: darkColorScheme.onSurface,
      elevation: 0,
      scrolledUnderElevation: 1,
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      filled: true,
      fillColor: darkColorScheme.surfaceContainerLowest,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(64, 52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(64, 52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: darkColorScheme.outlineVariant),
      ),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      type: BottomNavigationBarType.fixed,
      selectedLabelStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
      unselectedLabelStyle: TextStyle(fontSize: 12),
    ),
  );
}

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../tokens/colors.dart';
import '../tokens/radii.dart';

/// Configures Material [ThemeData] to match the Eden UI design system.
///
/// ```dart
/// MaterialApp(
///   theme: EdenTheme.light(),
///   darkTheme: EdenTheme.dark(),
/// )
/// ```
class EdenTheme {
  EdenTheme._();

  /// The currently active brand color. Defaults to [EdenColors.gold].
  /// Change this before calling [light]/[dark] to switch brand presets.
  static MaterialColor brandColor = EdenColors.gold;

  // ---------------------------------------------------------------------------
  // Light theme
  // ---------------------------------------------------------------------------

  static ThemeData light({MaterialColor? brand}) {
    final primary = brand ?? brandColor;
    final colorScheme = ColorScheme.light(
      primary: primary,
      onPrimary: Colors.white,
      primaryContainer: primary[100]!,
      onPrimaryContainer: primary[900]!,
      secondary: EdenColors.neutral[600]!,
      onSecondary: Colors.white,
      surface: Colors.white,
      onSurface: EdenColors.neutral[900]!,
      onSurfaceVariant: EdenColors.neutral[500]!,
      outline: EdenColors.neutral[300]!,
      outlineVariant: EdenColors.neutral[200]!,
      error: EdenColors.error,
      onError: Colors.white,
    );

    return _buildTheme(colorScheme, Brightness.light);
  }

  // ---------------------------------------------------------------------------
  // Dark theme
  // ---------------------------------------------------------------------------

  static ThemeData dark({MaterialColor? brand}) {
    final primary = brand ?? brandColor;
    final colorScheme = ColorScheme.dark(
      primary: primary[400]!,
      onPrimary: primary[950]!,
      primaryContainer: primary[900]!,
      onPrimaryContainer: primary[100]!,
      secondary: EdenColors.neutral[400]!,
      onSecondary: EdenColors.neutral[950]!,
      surface: EdenColors.neutral[900]!,
      onSurface: EdenColors.neutral[100]!,
      onSurfaceVariant: EdenColors.neutral[400]!,
      outline: EdenColors.neutral[700]!,
      outlineVariant: EdenColors.neutral[800]!,
      error: EdenColors.error,
      onError: Colors.white,
    );

    return _buildTheme(colorScheme, Brightness.dark);
  }

  // ---------------------------------------------------------------------------
  // Shared builder
  // ---------------------------------------------------------------------------

  static ThemeData _buildTheme(ColorScheme colorScheme, Brightness brightness) {
    final isDark = brightness == Brightness.dark;

    final textTheme = TextTheme(
      displayLarge: GoogleFonts.outfit(fontSize: 48, fontWeight: FontWeight.w800, height: 1.1),
      displayMedium: GoogleFonts.outfit(fontSize: 36, fontWeight: FontWeight.w700, height: 1.2),
      displaySmall: GoogleFonts.outfit(fontSize: 30, fontWeight: FontWeight.w700, height: 1.2),
      headlineLarge: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.w700, height: 1.3),
      headlineMedium: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w600, height: 1.3),
      headlineSmall: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w600, height: 1.4),
      titleLarge: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w600, height: 1.4),
      titleMedium: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w600, height: 1.4),
      titleSmall: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w600, height: 1.4),
      bodyLarge: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w400, height: 1.6),
      bodyMedium: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w400, height: 1.5),
      bodySmall: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w400, height: 1.5),
      labelLarge: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w600, height: 1.4),
      labelMedium: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600, height: 1.4),
      labelSmall: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w500, height: 1.4),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      textTheme: textTheme,
      scaffoldBackgroundColor: isDark ? EdenColors.neutral[950] : EdenColors.neutral[50],
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: EdenRadii.borderRadiusLg),
        color: isDark ? EdenColors.neutral[800] : colorScheme.surface,
      ),
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 1,
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        titleTextStyle: GoogleFonts.outfit(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: colorScheme.onSurface,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? EdenColors.neutral[800] : Colors.white,
        border: OutlineInputBorder(
          borderRadius: EdenRadii.borderRadiusLg,
          borderSide: BorderSide(color: colorScheme.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: EdenRadii.borderRadiusLg,
          borderSide: BorderSide(color: colorScheme.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: EdenRadii.borderRadiusLg,
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: EdenRadii.borderRadiusLg,
          borderSide: BorderSide(color: colorScheme.error),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: EdenRadii.borderRadiusLg),
          textStyle: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: EdenRadii.borderRadiusLg),
          side: BorderSide(color: colorScheme.outline),
          textStyle: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          shape: RoundedRectangleBorder(borderRadius: EdenRadii.borderRadiusLg),
          textStyle: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(borderRadius: EdenRadii.borderRadiusFull),
      ),
      dividerTheme: DividerThemeData(
        color: colorScheme.outlineVariant,
        thickness: 1,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: colorScheme.surface,
        selectedItemColor: colorScheme.primary,
        unselectedItemColor: colorScheme.onSurfaceVariant,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: EdenRadii.borderRadiusLg),
      ),
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(borderRadius: EdenRadii.borderRadiusXl),
      ),
    );
  }
}

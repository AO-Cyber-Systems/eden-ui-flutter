import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Eden UI typography — uses Outfit (display), Plus Jakarta Sans (body),
/// JetBrains Mono (code). Matches eden_ui/tokens.css font tokens.
class EdenTypography {
  EdenTypography._();

  // ---------------------------------------------------------------------------
  // Font families
  // ---------------------------------------------------------------------------

  static TextStyle get displayFont => GoogleFonts.outfit();
  static TextStyle get bodyFont => GoogleFonts.plusJakartaSans();
  static TextStyle get monoFont => GoogleFonts.jetBrainsMono();

  // ---------------------------------------------------------------------------
  // Display styles (Outfit)
  // ---------------------------------------------------------------------------

  static TextStyle displayLarge(BuildContext context) =>
      GoogleFonts.outfit(fontSize: 48, fontWeight: FontWeight.w800, height: 1.1);

  static TextStyle displayMedium(BuildContext context) =>
      GoogleFonts.outfit(fontSize: 36, fontWeight: FontWeight.w700, height: 1.2);

  static TextStyle displaySmall(BuildContext context) =>
      GoogleFonts.outfit(fontSize: 30, fontWeight: FontWeight.w700, height: 1.2);

  // ---------------------------------------------------------------------------
  // Heading styles (Outfit)
  // ---------------------------------------------------------------------------

  static TextStyle headlineLarge(BuildContext context) =>
      GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.w700, height: 1.3);

  static TextStyle headlineMedium(BuildContext context) =>
      GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w600, height: 1.3);

  static TextStyle headlineSmall(BuildContext context) =>
      GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w600, height: 1.4);

  // ---------------------------------------------------------------------------
  // Body styles (Plus Jakarta Sans)
  // ---------------------------------------------------------------------------

  static TextStyle bodyLarge(BuildContext context) =>
      GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w400, height: 1.6);

  static TextStyle bodyMedium(BuildContext context) =>
      GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w400, height: 1.5);

  static TextStyle bodySmall(BuildContext context) =>
      GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w400, height: 1.5);

  // ---------------------------------------------------------------------------
  // Label styles (Plus Jakarta Sans, semibold)
  // ---------------------------------------------------------------------------

  static TextStyle labelLarge(BuildContext context) =>
      GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w600, height: 1.4);

  static TextStyle labelMedium(BuildContext context) =>
      GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600, height: 1.4);

  static TextStyle labelSmall(BuildContext context) =>
      GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w500, height: 1.4);

  // ---------------------------------------------------------------------------
  // Code styles (JetBrains Mono)
  // ---------------------------------------------------------------------------

  static TextStyle codeLarge(BuildContext context) =>
      GoogleFonts.jetBrainsMono(fontSize: 15, fontWeight: FontWeight.w400, height: 1.6);

  static TextStyle codeMedium(BuildContext context) =>
      GoogleFonts.jetBrainsMono(fontSize: 13, fontWeight: FontWeight.w400, height: 1.5);

  static TextStyle codeSmall(BuildContext context) =>
      GoogleFonts.jetBrainsMono(fontSize: 12, fontWeight: FontWeight.w400, height: 1.5);

  // ---------------------------------------------------------------------------
  // AOHealth wireframe-specific styles
  // ---------------------------------------------------------------------------

  /// Card section title: UPPERCASE, 13px, w600, 0.5px spacing (Outfit)
  static TextStyle cardTitle(BuildContext context) =>
      GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w600, letterSpacing: 0.5, height: 1.4);

  /// Stat card large value: 22px, w700 (Outfit)
  static TextStyle statValue(BuildContext context) =>
      GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.w700);

  /// Calorie ring center value: 28px, w700 (Outfit)
  static TextStyle ringValue(BuildContext context) =>
      GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.w700);

  /// Settings section label: 12px, w600, 0.5px spacing (Outfit)
  static TextStyle sectionLabel(BuildContext context) =>
      GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.5);
}

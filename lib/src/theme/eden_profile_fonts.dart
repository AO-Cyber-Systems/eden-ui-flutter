import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'eden_theme_profile.dart';

/// Per-profile font resolver.
///
/// Bridges the [EdenThemeProfileData] font-family String fields (from
/// TRD 009-01) to renderable [TextStyle]s via the existing `google_fonts`
/// package. Consumers either:
///   - call [bodyTextStyle] / [displayTextStyle] / [monoTextStyle] directly
///     to get a profile-aware TextStyle, or
///   - call [bodyFontFamily] / [displayFontFamily] / [monoFontFamily] to
///     get the family-name String (null = use default).
///
/// **Back-compat fallback contract:** when a profile has no opt-in for a
/// given style (family-string is null), the corresponding TextStyle builder
/// returns the SAME font as today's `EdenTheme` defaults:
///   - body fallback = Plus Jakarta Sans
///   - display fallback = Outfit
///   - mono fallback = JetBrains Mono
///
/// **No Roboto.** A failing fallback would silently render Material's
/// default Roboto; the test suite asserts fontFamily is never 'Roboto'.
///
/// Reads from [EdenThemeProfileData] — single source of truth for the
/// per-profile font-family table. Changing TRD 009-01's data updates this
/// resolver automatically (except for mono which is universally null in v1).
class EdenProfileFonts {
  EdenProfileFonts._();

  // ---------------------------------------------------------------------------
  // Family-name lookups (delegate to profile data — single source of truth).
  // ---------------------------------------------------------------------------

  static String? bodyFontFamily(EdenThemeProfile profile) =>
      profile.data.bodyFontFamily;

  static String? displayFontFamily(EdenThemeProfile profile) =>
      profile.data.displayFontFamily;

  static String? monoFontFamily(EdenThemeProfile profile) =>
      profile.data.monoFontFamily;

  // ---------------------------------------------------------------------------
  // TextStyle builders.
  // ---------------------------------------------------------------------------

  /// Returns a body [TextStyle] for the active profile.
  /// Fallback (family null) = Plus Jakarta Sans (today's default).
  static TextStyle bodyTextStyle(
    EdenThemeProfile profile, {
    double? fontSize,
    FontWeight? fontWeight,
    double? height,
    Color? color,
  }) {
    final family = bodyFontFamily(profile);
    if (family == null) {
      return GoogleFonts.plusJakartaSans(
        fontSize: fontSize,
        fontWeight: fontWeight,
        height: height,
        color: color,
      );
    }
    return GoogleFonts.getFont(
      family,
      fontSize: fontSize,
      fontWeight: fontWeight,
      height: height,
      color: color,
    );
  }

  /// Returns a display [TextStyle] for the active profile.
  /// Fallback (family null) = Outfit (today's default).
  static TextStyle displayTextStyle(
    EdenThemeProfile profile, {
    double? fontSize,
    FontWeight? fontWeight,
    double? height,
    Color? color,
  }) {
    final family = displayFontFamily(profile);
    if (family == null) {
      return GoogleFonts.outfit(
        fontSize: fontSize,
        fontWeight: fontWeight,
        height: height,
        color: color,
      );
    }
    return GoogleFonts.getFont(
      family,
      fontSize: fontSize,
      fontWeight: fontWeight,
      height: height,
      color: color,
    );
  }

  /// Returns a mono [TextStyle] for the active profile.
  /// Fallback (family null — all v1 profiles) = JetBrains Mono.
  static TextStyle monoTextStyle(
    EdenThemeProfile profile, {
    double? fontSize,
    FontWeight? fontWeight,
    double? height,
    Color? color,
  }) {
    final family = monoFontFamily(profile);
    if (family == null) {
      return GoogleFonts.jetBrainsMono(
        fontSize: fontSize,
        fontWeight: fontWeight,
        height: height,
        color: color,
      );
    }
    return GoogleFonts.getFont(
      family,
      fontSize: fontSize,
      fontWeight: fontWeight,
      height: height,
      color: color,
    );
  }
}

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
///     get the family-name String (null = use default), or
///   - call [bodyTextStyleForFamily] / [displayTextStyleForFamily] /
///     [monoTextStyleForFamily] to resolve a RUNTIME family name (objective
///     022 capability 3) — e.g. a String read out of `window.APP_CONFIG` at
///     boot rather than baked into a profile.
///
/// **Back-compat fallback contract:** when a profile has no opt-in for a
/// given style (family-string is null), the corresponding TextStyle builder
/// returns the SAME font as today's `EdenTheme` defaults:
///   - body fallback = Plus Jakarta Sans
///   - display fallback = Outfit
///   - mono fallback = JetBrains Mono
///
/// The same fallback contract applies to the runtime family-taking methods,
/// with one addition: an unavailable, misspelled, empty, blank or null
/// family falls back rather than throwing (LOCKED decision 4,
/// 022-CONTEXT.md) — a bad partner value must not crash an app's boot.
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
  // Runtime family resolution.
  //
  // Objective 022 capability 3: a downstream Flutter web app reads a font
  // family out of `window.APP_CONFIG` at boot and passes the String
  // straight in.
  //
  // LOCKED decision 4 (022-CONTEXT.md): no new font delivery mechanism —
  // this reuses GoogleFonts.getFont — and an unavailable family falls back
  // to the profile default rather than throwing, because a bad partner
  // value must not crash an app's boot.
  // ---------------------------------------------------------------------------

  /// Families already reported as unresolvable, so a per-frame theme
  /// rebuild does not spam the debug console. Debug-only bookkeeping.
  static final Set<String> _reportedMissingFamilies = <String>{};

  /// Resets the debug fallback-log dedupe. Tests only.
  @visibleForTesting
  static void resetMissingFamilyLog() => _reportedMissingFamilies.clear();

  /// Resolves [family] via GoogleFonts, falling back to [fallback] when the
  /// family is absent, blank, or unknown to GoogleFonts. Never throws.
  ///
  /// This is the ONE code path both the enum-taking methods
  /// ([bodyTextStyle], [displayTextStyle], [monoTextStyle]) and the
  /// runtime family-taking methods ([bodyTextStyleForFamily],
  /// [displayTextStyleForFamily], [monoTextStyleForFamily]) route through.
  static TextStyle _resolveFamily(
    String? family, {
    required TextStyle Function() fallback,
    double? fontSize,
    FontWeight? fontWeight,
    double? height,
    Color? color,
  }) {
    if (family == null || family.trim().isEmpty) return fallback();
    try {
      return GoogleFonts.getFont(
        family,
        fontSize: fontSize,
        fontWeight: fontWeight,
        height: height,
        color: color,
      );
    } catch (_) {
      // Deliberately broad. GoogleFonts throws a library-private _Exception
      // for an unknown family, so the concrete type cannot be named in an
      // `on` clause. `on Exception` WOULD match it today (verified), but
      // that is an upstream implementation detail, and `catch (_)`
      // additionally survives an Error from a future google_fonts change.
      // A font name must never take an app's boot down (022-CONTEXT.md
      // LOCKED decision 4). Do not narrow this.
      assert(() {
        if (_reportedMissingFamilies.add(family)) {
          debugPrint(
            'EdenProfileFonts: font family "$family" is not available via '
            'google_fonts — falling back to the Eden default.',
          );
        }
        return true;
      }());
      return fallback();
    }
  }

  /// Body [TextStyle] for a RUNTIME family name.
  /// Unavailable / blank / null falls back to Plus Jakarta Sans (today's
  /// default) and NEVER throws.
  static TextStyle bodyTextStyleForFamily(
    String? family, {
    double? fontSize,
    FontWeight? fontWeight,
    double? height,
    Color? color,
  }) =>
      _resolveFamily(
        family,
        fallback: () => GoogleFonts.plusJakartaSans(
          fontSize: fontSize,
          fontWeight: fontWeight,
          height: height,
          color: color,
        ),
        fontSize: fontSize,
        fontWeight: fontWeight,
        height: height,
        color: color,
      );

  /// Display [TextStyle] for a RUNTIME family name.
  /// Unavailable / blank / null falls back to Outfit (today's default) and
  /// NEVER throws.
  static TextStyle displayTextStyleForFamily(
    String? family, {
    double? fontSize,
    FontWeight? fontWeight,
    double? height,
    Color? color,
  }) =>
      _resolveFamily(
        family,
        fallback: () => GoogleFonts.outfit(
          fontSize: fontSize,
          fontWeight: fontWeight,
          height: height,
          color: color,
        ),
        fontSize: fontSize,
        fontWeight: fontWeight,
        height: height,
        color: color,
      );

  /// Mono [TextStyle] for a RUNTIME family name.
  /// Unavailable / blank / null falls back to JetBrains Mono (today's
  /// default) and NEVER throws.
  static TextStyle monoTextStyleForFamily(
    String? family, {
    double? fontSize,
    FontWeight? fontWeight,
    double? height,
    Color? color,
  }) =>
      _resolveFamily(
        family,
        fallback: () => GoogleFonts.jetBrainsMono(
          fontSize: fontSize,
          fontWeight: fontWeight,
          height: height,
          color: color,
        ),
        fontSize: fontSize,
        fontWeight: fontWeight,
        height: height,
        color: color,
      );

  // ---------------------------------------------------------------------------
  // TextStyle builders (profile-aware). Delegate to the family-taking
  // methods above so there is a single guarded `GoogleFonts.getFont` call
  // site (LOCKED decision 2's one-path principle).
  // ---------------------------------------------------------------------------

  /// Returns a body [TextStyle] for the active profile.
  /// Fallback (family null) = Plus Jakarta Sans (today's default).
  static TextStyle bodyTextStyle(
    EdenThemeProfile profile, {
    double? fontSize,
    FontWeight? fontWeight,
    double? height,
    Color? color,
  }) =>
      bodyTextStyleForFamily(
        bodyFontFamily(profile),
        fontSize: fontSize,
        fontWeight: fontWeight,
        height: height,
        color: color,
      );

  /// Returns a display [TextStyle] for the active profile.
  /// Fallback (family null) = Outfit (today's default).
  static TextStyle displayTextStyle(
    EdenThemeProfile profile, {
    double? fontSize,
    FontWeight? fontWeight,
    double? height,
    Color? color,
  }) =>
      displayTextStyleForFamily(
        displayFontFamily(profile),
        fontSize: fontSize,
        fontWeight: fontWeight,
        height: height,
        color: color,
      );

  /// Returns a mono [TextStyle] for the active profile.
  /// Fallback (family null — all v1 profiles) = JetBrains Mono.
  static TextStyle monoTextStyle(
    EdenThemeProfile profile, {
    double? fontSize,
    FontWeight? fontWeight,
    double? height,
    Color? color,
  }) =>
      monoTextStyleForFamily(
        monoFontFamily(profile),
        fontSize: fontSize,
        fontWeight: fontWeight,
        height: height,
        color: color,
      );
}

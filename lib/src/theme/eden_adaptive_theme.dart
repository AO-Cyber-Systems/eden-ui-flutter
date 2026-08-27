import 'package:flutter/material.dart';
import 'eden_brand_preset.dart';
import 'eden_brand_swatch.dart';
import 'eden_profile_fonts.dart';
import 'eden_theme.dart';
import 'eden_theme_profile.dart';
import 'eden_theme_profile_scope.dart';

/// Top-level integration of the vertical theme system (objective 009).
///
/// Two consumption patterns:
///
/// **Pattern A — Static factory for MaterialApp.theme** (app-wide theming):
/// ```dart
/// MaterialApp(
///   theme: EdenAdaptiveTheme.light(
///     EdenThemeProfile.medicalInstitutional,
///     brand: EdenBrandPresetRegistry.byId('medical-teal'),
///   ),
///   darkTheme: EdenAdaptiveTheme.dark(EdenThemeProfile.medicalInstitutional),
/// );
/// ```
///
/// **Pattern B — Widget wrapper** (in-tree subtree override; catalog
/// screens, embedded preview surfaces):
/// ```dart
/// EdenAdaptiveTheme(
///   profile: EdenThemeProfile.govFederal,
///   brand: EdenBrandPresetRegistry.byId('gov-federal-navy'),
///   child: PreviewArea(),
/// )
/// ```
///
/// Both patterns compose:
///   - [EdenTheme.light]/[EdenTheme.dark] from TRD 009-02 (attaches the
///     `EdenStatusPalette` per profile)
///   - [EdenProfileFonts] from TRD 009-04 (profile-aware TextTheme overlay)
///   - [EdenBrandPreset.color] override for [ColorScheme.primary]
///
/// **Back-compat anchor (OBJECTIVE.md Constraint 1):** for
/// [EdenThemeProfile.commercialWarm] with no brand override, the static
/// factories return [ThemeData] equivalent to today's `EdenTheme.light()`
/// output — verified by the test suite via observable-field equality.
class EdenAdaptiveTheme extends StatelessWidget {
  const EdenAdaptiveTheme({
    super.key,
    required this.profile,
    this.brand,
    required this.child,
  });

  final EdenThemeProfile profile;
  final EdenBrandPreset? brand;
  final Widget child;

  /// Static factory returning a [ThemeData] for [MaterialApp.theme].
  ///
  /// Composes [EdenTheme.light] (which attaches the status palette) and
  /// overlays a profile-aware [TextTheme] using [EdenProfileFonts].
  ///
  /// **Primary-color resolution order:** explicit `brand` → profile's
  /// canonical `primaryColor` (from [EdenThemeProfileData]) → `EdenTheme`'s
  /// default `brandColor` (gold). The profile default is what makes the
  /// adaptive layer distinct: `EdenAdaptiveTheme.light(govFederal)` produces
  /// a navy primary even without a brand override, because [EdenThemeProfile]
  /// `.data.primaryColor` for gov is `EdenColors.blue`.
  ///
  /// **Back-compat carve-out:** for [EdenThemeProfile.commercialWarm] the
  /// profile's `primaryColor` is `EdenColors.gold`, which equals
  /// `EdenTheme.brandColor` — so the no-brand case still produces identical
  /// output to today's `EdenTheme.light()`.
  static ThemeData light(
    EdenThemeProfile profile, {
    EdenBrandPreset? brand,
  }) =>
      lightFromData(profile.data, brand: brand?.color);

  /// Static factory for dark mode. Analogous to [light].
  /// v1 reuses the same per-profile palette in dark mode (no per-profile
  /// dark-mode aesthetic tuning — Out-of-Scope per OBJECTIVE.md).
  static ThemeData dark(
    EdenThemeProfile profile, {
    EdenBrandPreset? brand,
  }) =>
      darkFromData(profile.data, brand: brand?.color);

  /// Data-taking core for [light]. Accepts a runtime-constructed
  /// [EdenThemeProfileData] (e.g. from [EdenThemeProfileData.runtime])
  /// instead of a fixed [EdenThemeProfile] enum member — this is the seam
  /// [lightFromConfig] and the enum-taking [light] both delegate through.
  ///
  /// **Primary-color resolution order:** explicit `brand` → `data`'s
  /// canonical `primaryColor`.
  static ThemeData lightFromData(
    EdenThemeProfileData data, {
    MaterialColor? brand,
  }) {
    final resolvedBrand = brand ?? data.primaryColor;
    final base = EdenTheme.light(profile: data.profile, brand: resolvedBrand);
    return _withDataTextTheme(base, data);
  }

  /// Data-taking core for [dark]. Analogous to [lightFromData].
  static ThemeData darkFromData(
    EdenThemeProfileData data, {
    MaterialColor? brand,
  }) {
    final resolvedBrand = brand ?? data.primaryColor;
    final base = EdenTheme.dark(profile: data.profile, brand: resolvedBrand);
    return _withDataTextTheme(base, data);
  }

  /// Static factory for the runtime `window.APP_CONFIG` boot path.
  ///
  /// Accepts plain strings matching the shape a downstream Flutter web app
  /// reads off `window.APP_CONFIG` at startup: [brandHex] (e.g. `'#0F62FE'`),
  /// [bodyFontFamily], [displayFontFamily]. [base] selects the starting
  /// [EdenThemeProfile] (defaults to [EdenThemeProfile.commercialWarm]) whose
  /// other tokens (radius, density, status palette, etc.) are preserved.
  ///
  /// Malformed input never throws: an unparsable [brandHex] falls back to
  /// `base`'s profile `primaryColor`; an unrecognized font family falls back
  /// to the Eden per-role default (see [EdenProfileFonts]).
  ///
  /// Deliberately has NO `monoFontFamily` parameter — see
  /// [EdenThemeProfileData.runtime] doc comment. Mono has no Material
  /// [TextTheme] role to theme; it stays reachable via
  /// [EdenThemeProfileData.runtime]'s `monoFontFamily` field plus
  /// [EdenProfileFonts.monoTextStyleForFamily] called directly by a consumer.
  static ThemeData lightFromConfig({
    EdenThemeProfile base = EdenThemeProfile.commercialWarm,
    String? brandHex,
    String? bodyFontFamily,
    String? displayFontFamily,
  }) =>
      lightFromData(
        _configData(
          base: base,
          brandHex: brandHex,
          bodyFontFamily: bodyFontFamily,
          displayFontFamily: displayFontFamily,
        ),
      );

  /// Static factory for the runtime `window.APP_CONFIG` boot path, dark mode.
  /// Analogous to [lightFromConfig].
  static ThemeData darkFromConfig({
    EdenThemeProfile base = EdenThemeProfile.commercialWarm,
    String? brandHex,
    String? bodyFontFamily,
    String? displayFontFamily,
  }) =>
      darkFromData(
        _configData(
          base: base,
          brandHex: brandHex,
          bodyFontFamily: bodyFontFamily,
          displayFontFamily: displayFontFamily,
        ),
      );

  /// Builds the [EdenThemeProfileData] shared by [lightFromConfig] and
  /// [darkFromConfig]. [EdenBrandSwatch.tryParse] returns `null` on
  /// malformed hex — never force-unwrapped — so [EdenThemeProfileData.runtime]
  /// falls back to `base`'s canonical `primaryColor` automatically.
  static EdenThemeProfileData _configData({
    required EdenThemeProfile base,
    String? brandHex,
    String? bodyFontFamily,
    String? displayFontFamily,
  }) =>
      EdenThemeProfileData.runtime(
        base: base,
        primaryColor: EdenBrandSwatch.tryParse(brandHex),
        bodyFontFamily: bodyFontFamily,
        displayFontFamily: displayFontFamily,
      );

  /// Overlay the base TextTheme with profile-aware font families.
  ///
  /// Short-circuits when `data` uses defaults for both body + display
  /// (back-compat preservation: zero allocation, zero change for default
  /// profile / retailVibrant / legalProfessional-body / etc.).
  ///
  /// **Merge direction:** `body.bodyLarge?.merge(overlay)` — the BASE TextStyle
  /// supplies fontSize / fontWeight / height; the OVERLAY supplies fontFamily.
  /// `TextStyle.merge(other)` semantics: fields from `other` override `this`
  /// when non-null in `other`. Since the overlay TextStyle is constructed from
  /// `GoogleFonts.getFont(family)` (which sets only fontFamily, leaving size/
  /// weight null), the BASE's sizing tokens are preserved verbatim.
  static ThemeData _withDataTextTheme(
    ThemeData base,
    EdenThemeProfileData data,
  ) {
    if (data.bodyFontFamily == null && data.displayFontFamily == null) {
      return base;
    }

    final body = base.textTheme;
    final displayOverlay =
        EdenProfileFonts.displayTextStyleForFamily(data.displayFontFamily);
    final bodyOverlay =
        EdenProfileFonts.bodyTextStyleForFamily(data.bodyFontFamily);
    final overridden = body.copyWith(
      // Display + headline roles use the display font.
      displayLarge: body.displayLarge?.merge(displayOverlay),
      displayMedium: body.displayMedium?.merge(displayOverlay),
      displaySmall: body.displaySmall?.merge(displayOverlay),
      headlineLarge: body.headlineLarge?.merge(displayOverlay),
      headlineMedium: body.headlineMedium?.merge(displayOverlay),
      headlineSmall: body.headlineSmall?.merge(displayOverlay),
      // Title / body / label roles use the body font.
      titleLarge: body.titleLarge?.merge(bodyOverlay),
      titleMedium: body.titleMedium?.merge(bodyOverlay),
      titleSmall: body.titleSmall?.merge(bodyOverlay),
      bodyLarge: body.bodyLarge?.merge(bodyOverlay),
      bodyMedium: body.bodyMedium?.merge(bodyOverlay),
      bodySmall: body.bodySmall?.merge(bodyOverlay),
      labelLarge: body.labelLarge?.merge(bodyOverlay),
      labelMedium: body.labelMedium?.merge(bodyOverlay),
      labelSmall: body.labelSmall?.merge(bodyOverlay),
    );
    return base.copyWith(textTheme: overridden);
  }

  @override
  Widget build(BuildContext context) {
    final themeData = light(profile, brand: brand);
    return EdenThemeProfileScope(
      profile: profile,
      child: Theme(
        data: themeData,
        child: child,
      ),
    );
  }
}

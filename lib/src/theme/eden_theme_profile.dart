import 'package:flutter/material.dart';
import '../tokens/colors.dart';

/// Five canonical Eden vertical theme profiles.
///
/// **LOCKED per OBJECTIVE.md Constraint 11.** Do not add, remove, or rename.
/// Profile-specific data values live in [EdenThemeProfileData].
///
/// Default-by-position: [commercialWarm] is ordinal 0 — it is the back-compat
/// anchor and reproduces today's `EdenTheme.light()` output exactly.
enum EdenThemeProfile {
  /// Default — today's behavior. Warm gold on neutral slate.
  /// Salon, retail mid-market, consumer-tilt verticals.
  commercialWarm,

  /// Teal/cyan institutional. Sharper corners, less shadow, IBM Plex Sans body.
  /// Medical, healthtech.
  medicalInstitutional,

  /// Federal navy + USWDS conformance. Public Sans, 4pt radii,
  /// border-only surfaces, ≥48pt touch floor. DHHS / DOD / federal civilian.
  govFederal,

  /// High-saturation primary + brand-color totals + cart accents.
  /// Mass-market retail, Shopify POS-style brand expression.
  retailVibrant,

  /// Navy primary + serif display opt-in + restrained accent.
  /// Traditional law firm gravitas.
  legalProfessional,
}

/// Per-profile density. Declared for forward-compatibility; v1 does NOT
/// wire density to spacing tokens (OBJECTIVE.md Constraint 12). All 5
/// v1 profile data instances use [comfortable].
enum EdenThemeProfileDensity {
  comfortable,
  dense,
}

/// Immutable per-profile token deltas. Const-able.
///
/// Static instances per profile (e.g. [commercialWarmData]) carry the
/// canonical values from `VERTICAL_UX_RESEARCH_2026-05-16.md` §2.4.2.
///
/// **Back-compat lock:** [commercialWarmData] MUST reproduce today's
/// behavior — any drift breaks OBJECTIVE.md Constraint 1.
@immutable
class EdenThemeProfileData {
  const EdenThemeProfileData({
    required this.profile,
    required this.primaryColor,
    required this.surfaceTonalSeed,
    this.radiusMultiplier = 1.0,
    this.density = EdenThemeProfileDensity.comfortable,
    this.minimumTouchTargetPx = 0,
    this.bodyFontFamily,
    this.displayFontFamily,
    this.monoFontFamily,
    this.preferBorderOverShadow = false,
  });

  final EdenThemeProfile profile;
  final MaterialColor primaryColor;
  final Color surfaceTonalSeed;
  final double radiusMultiplier;
  final EdenThemeProfileDensity density;
  final double minimumTouchTargetPx;
  final String? bodyFontFamily;
  final String? displayFontFamily;
  final String? monoFontFamily;
  final bool preferBorderOverShadow;

  /// Returns a copy of this profile data with the given fields replaced.
  ///
  /// Exposes `density` because it is a genuine v1 knob (see
  /// [EdenThemeProfileDensity]) even though v1 does not yet wire it to
  /// spacing tokens. Does NOT expose `surfaceTonalSeed`, `radiusMultiplier`,
  /// `minimumTouchTargetPx`, or `preferBorderOverShadow` as parameters —
  /// those four tokens are declared but read by no production widget today
  /// (022-CONTEXT.md finding 6). Adding a knob that reaches no widget would
  /// look finished when it is not; wiring them up is a separate objective's
  /// job, not this one's. This method still carries all four through
  /// unchanged, so a caller who only wants to change e.g. [primaryColor]
  /// never silently resets them.
  EdenThemeProfileData copyWith({
    EdenThemeProfile? profile,
    MaterialColor? primaryColor,
    EdenThemeProfileDensity? density,
    String? bodyFontFamily,
    String? displayFontFamily,
    String? monoFontFamily,
  }) {
    return EdenThemeProfileData(
      profile: profile ?? this.profile,
      primaryColor: primaryColor ?? this.primaryColor,
      surfaceTonalSeed: surfaceTonalSeed,
      radiusMultiplier: radiusMultiplier,
      density: density ?? this.density,
      minimumTouchTargetPx: minimumTouchTargetPx,
      bodyFontFamily: bodyFontFamily ?? this.bodyFontFamily,
      displayFontFamily: displayFontFamily ?? this.displayFontFamily,
      monoFontFamily: monoFontFamily ?? this.monoFontFamily,
      preferBorderOverShadow: preferBorderOverShadow,
    );
  }

  /// Builds profile data from values learned at runtime (for example,
  /// `window.APP_CONFIG` in a downstream app), without adding a sixth
  /// [EdenThemeProfile].
  ///
  /// [base] selects which of the five canonical profiles to start from —
  /// defaults to [EdenThemeProfile.commercialWarm], today's default. The
  /// returned data still carries `base`'s real enum value, so
  /// `EdenStatusPalette.forProfile` and other exhaustive switches over
  /// [EdenThemeProfile] keep resolving correctly.
  ///
  /// Unlike [copyWith], `density` is deliberately NOT a parameter here:
  /// [copyWith] is a Dart-literal API for code that already holds an
  /// [EdenThemeProfileData], while [runtime] is the config surface that
  /// runtime app config reaches — and density has no wired effect in v1
  /// (see [EdenThemeProfileDensity]), so it is not offered as a runtime
  /// knob. The same "preserve, never expose" rule as [copyWith] applies to
  /// `surfaceTonalSeed`, `radiusMultiplier`, `minimumTouchTargetPx`, and
  /// `preferBorderOverShadow`: none of the four appears here as a
  /// parameter either.
  static EdenThemeProfileData runtime({
    EdenThemeProfile base = EdenThemeProfile.commercialWarm,
    MaterialColor? primaryColor,
    String? bodyFontFamily,
    String? displayFontFamily,
    String? monoFontFamily,
  }) {
    return base.data.copyWith(
      primaryColor: primaryColor,
      bodyFontFamily: bodyFontFamily,
      displayFontFamily: displayFontFamily,
      monoFontFamily: monoFontFamily,
    );
  }

  // ---------------------------------------------------------------------------
  // Canonical per-profile static instances.
  //
  // Hex literals are used for `surfaceTonalSeed` (not MaterialColor[shade]!
  // lookups) because MaterialColor[X] is NOT a const expression. The hex
  // values MUST match the corresponding shade in lib/src/tokens/colors.dart.
  //
  // Do NOT "simplify" the hex literals back into EdenColors lookups — it
  // breaks const-ness and the back-compat contract.
  // ---------------------------------------------------------------------------

  /// Back-compat anchor — reproduces today's `EdenTheme.light()` output.
  /// OBJECTIVE.md Constraint 1.
  static const EdenThemeProfileData commercialWarmData = EdenThemeProfileData(
    profile: EdenThemeProfile.commercialWarm,
    primaryColor: EdenColors.gold,
    surfaceTonalSeed: Color(0xFFFAFAFA), // == EdenColors.neutral[50]
    // radiusMultiplier 1.0, density comfortable, touch 0, all fonts null,
    // preferBorderOverShadow false — all defaults.
  );

  /// Teal/cyan institutional. Sharper corners (lg 12 → 8 via 0.667 multiplier).
  /// IBM Plex Sans body. Border-over-shadow.
  static const EdenThemeProfileData medicalInstitutionalData =
      EdenThemeProfileData(
    profile: EdenThemeProfile.medicalInstitutional,
    primaryColor: EdenColors.cyan,
    surfaceTonalSeed: Color(0xFFF0FDFA), // teal-50 approximation
    radiusMultiplier: 0.667, // 12pt lg → 8pt
    bodyFontFamily: 'IBM Plex Sans',
    preferBorderOverShadow: true,
  );

  /// Federal navy + USWDS conformance. 4pt radii (multiplier 0.333),
  /// Public Sans for body AND display, ≥48pt touch floor, border-over-shadow.
  static const EdenThemeProfileData govFederalData = EdenThemeProfileData(
    profile: EdenThemeProfile.govFederal,
    primaryColor: EdenColors.blue, // .blue[900] == #1E3A8A (federal navy)
    surfaceTonalSeed: Color(0xFFF8FAFC), // slate-50
    radiusMultiplier: 0.333, // 12pt lg → 4pt
    minimumTouchTargetPx: 48,
    bodyFontFamily: 'Public Sans',
    displayFontFamily: 'Public Sans',
    preferBorderOverShadow: true,
  );

  /// High-saturation primary. Retail / POS / Shopify-style brand expression.
  static const EdenThemeProfileData retailVibrantData = EdenThemeProfileData(
    profile: EdenThemeProfile.retailVibrant,
    primaryColor: EdenColors.purple,
    surfaceTonalSeed: Color(0xFFFAFAFA),
    // radiusMultiplier 1.0 — same as commercial.
  );

  /// Navy primary + restrained palette + Crimson Pro display headers (opt-in).
  /// Legal practice management.
  static const EdenThemeProfileData legalProfessionalData =
      EdenThemeProfileData(
    profile: EdenThemeProfile.legalProfessional,
    primaryColor: EdenColors.slate,
    surfaceTonalSeed: Color(0xFFF8FAFC),
    displayFontFamily: 'Crimson Pro',
  );
}

/// Convenience extension to look up the canonical [EdenThemeProfileData]
/// for any [EdenThemeProfile].
extension EdenThemeProfileDataLookup on EdenThemeProfile {
  EdenThemeProfileData get data {
    switch (this) {
      case EdenThemeProfile.commercialWarm:
        return EdenThemeProfileData.commercialWarmData;
      case EdenThemeProfile.medicalInstitutional:
        return EdenThemeProfileData.medicalInstitutionalData;
      case EdenThemeProfile.govFederal:
        return EdenThemeProfileData.govFederalData;
      case EdenThemeProfile.retailVibrant:
        return EdenThemeProfileData.retailVibrantData;
      case EdenThemeProfile.legalProfessional:
        return EdenThemeProfileData.legalProfessionalData;
    }
  }
}

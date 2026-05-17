import 'package:flutter/material.dart';
import 'eden_theme_profile.dart';

/// Profile-aware semantic status palette.
///
/// Exposes 5 semantic groups (success / warning / danger / info / neutral)
/// × 3 facets (bg / fg / border) as Color fields. Attaches to
/// [ThemeData.extensions] via [EdenTheme.light] / [EdenTheme.dark] when
/// a profile is supplied (default: [EdenThemeProfile.commercialWarm] —
/// today's behavior).
///
/// Read via:
/// ```dart
/// final palette = Theme.of(context).extension<EdenStatusPalette>()
///     ?? EdenStatusPalette.commercial();
/// ```
///
/// **Back-compat note:** the static `EdenColors.{success,warning,error,info}`
/// constants remain UNCHANGED. Widgets that read those constants directly
/// continue to work. The extension is the future read path for widgets that
/// want profile-aware status colors.
///
/// Per OBJECTIVE.md (009-vertical-theme-system) Constraint 1 — `commercial()`
/// reproduces today's EdenColors values exactly. Drift breaks back-compat.
@immutable
class EdenStatusPalette extends ThemeExtension<EdenStatusPalette> {
  const EdenStatusPalette({
    required this.successBg,
    required this.successFg,
    required this.successBorder,
    required this.warningBg,
    required this.warningFg,
    required this.warningBorder,
    required this.dangerBg,
    required this.dangerFg,
    required this.dangerBorder,
    required this.infoBg,
    required this.infoFg,
    required this.infoBorder,
    required this.neutralBg,
    required this.neutralFg,
    required this.neutralBorder,
  });

  final Color successBg;
  final Color successFg;
  final Color successBorder;
  final Color warningBg;
  final Color warningFg;
  final Color warningBorder;
  final Color dangerBg;
  final Color dangerFg;
  final Color dangerBorder;
  final Color infoBg;
  final Color infoFg;
  final Color infoBorder;
  final Color neutralBg;
  final Color neutralFg;
  final Color neutralBorder;

  /// Today's EdenColors-driven values. Back-compat anchor — drift here
  /// breaks OBJECTIVE.md Constraint 1.
  ///
  /// Hex values mirror `lib/src/tokens/colors.dart`:
  /// - successFg/Bg ←→ EdenColors.success / .successBg
  /// - warningFg/Bg ←→ EdenColors.warning / .warningBg
  /// - dangerFg/Bg ←→ EdenColors.error / .errorBg (semantic rename)
  /// - infoFg/Bg ←→ EdenColors.info / .infoBg
  /// - neutralFg/Bg ←→ EdenColors.neutral[600] / [100]
  /// - *Border ←→ derived 30% alpha (NEW — no static EdenColors equivalent)
  factory EdenStatusPalette.commercial() => const EdenStatusPalette(
        successBg: Color(0x1A10B981),
        successFg: Color(0xFF10B981),
        successBorder: Color(0x4D10B981),
        warningBg: Color(0x1AF59E0B),
        warningFg: Color(0xFFF59E0B),
        warningBorder: Color(0x4DF59E0B),
        dangerBg: Color(0x1AEF4444),
        dangerFg: Color(0xFFEF4444),
        dangerBorder: Color(0x4DEF4444),
        infoBg: Color(0x1A3B82F6),
        infoFg: Color(0xFF3B82F6),
        infoBorder: Color(0x4D3B82F6),
        neutralBg: Color(0xFFF4F4F5),
        neutralFg: Color(0xFF52525B),
        neutralBorder: Color(0xFFE4E4E7),
      );

  /// Medical institutional palette. Borders at 40% alpha (vs 30%) for
  /// border-over-shadow aesthetic. Standard hue families with info shifted
  /// to cyan for institutional fit.
  static const EdenStatusPalette _medicalInstitutional = EdenStatusPalette(
    successBg: Color(0x1A10B981),
    successFg: Color(0xFF10B981),
    successBorder: Color(0x6610B981), // 40% alpha
    warningBg: Color(0x1AF59E0B),
    warningFg: Color(0xFFF59E0B),
    warningBorder: Color(0x66F59E0B),
    dangerBg: Color(0x1AEF4444),
    dangerFg: Color(0xFFEF4444),
    dangerBorder: Color(0x66EF4444),
    infoBg: Color(0x1A06B6D4),
    infoFg: Color(0xFF06B6D4),
    infoBorder: Color(0x6606B6D4),
    neutralBg: Color(0xFFF4F4F5),
    neutralFg: Color(0xFF52525B),
    neutralBorder: Color(0xFFD4D4D8), // neutral[300] — stronger border
  );

  /// USWDS-conformant palette per research §1.7. Border alpha = full opacity
  /// (USWDS Card / Alert pattern). Deeper red + deeper blue per USWDS spec.
  static const EdenStatusPalette _govFederal = EdenStatusPalette(
    successBg: Color(0xFFECF3EC),
    successFg: Color(0xFF00A91C),
    successBorder: Color(0xFF00A91C),
    warningBg: Color(0xFFFEF7E1),
    warningFg: Color(0xFFFFBE2E),
    warningBorder: Color(0xFFFFBE2E),
    dangerBg: Color(0xFFF4E3DB),
    dangerFg: Color(0xFFB50909),
    dangerBorder: Color(0xFFB50909),
    infoBg: Color(0xFFE7F6F8),
    infoFg: Color(0xFF005EA2),
    infoBorder: Color(0xFF005EA2),
    neutralBg: Color(0xFFF0F0F0),
    neutralFg: Color(0xFF71767A),
    neutralBorder: Color(0xFFA9AEB1),
  );

  /// Dispatch a per-profile palette.
  factory EdenStatusPalette.forProfile(EdenThemeProfile profile) {
    switch (profile) {
      case EdenThemeProfile.commercialWarm:
      case EdenThemeProfile.retailVibrant:
      case EdenThemeProfile.legalProfessional:
        return EdenStatusPalette.commercial();
      case EdenThemeProfile.medicalInstitutional:
        return _medicalInstitutional;
      case EdenThemeProfile.govFederal:
        return _govFederal;
    }
  }

  @override
  EdenStatusPalette copyWith({
    Color? successBg,
    Color? successFg,
    Color? successBorder,
    Color? warningBg,
    Color? warningFg,
    Color? warningBorder,
    Color? dangerBg,
    Color? dangerFg,
    Color? dangerBorder,
    Color? infoBg,
    Color? infoFg,
    Color? infoBorder,
    Color? neutralBg,
    Color? neutralFg,
    Color? neutralBorder,
  }) {
    return EdenStatusPalette(
      successBg: successBg ?? this.successBg,
      successFg: successFg ?? this.successFg,
      successBorder: successBorder ?? this.successBorder,
      warningBg: warningBg ?? this.warningBg,
      warningFg: warningFg ?? this.warningFg,
      warningBorder: warningBorder ?? this.warningBorder,
      dangerBg: dangerBg ?? this.dangerBg,
      dangerFg: dangerFg ?? this.dangerFg,
      dangerBorder: dangerBorder ?? this.dangerBorder,
      infoBg: infoBg ?? this.infoBg,
      infoFg: infoFg ?? this.infoFg,
      infoBorder: infoBorder ?? this.infoBorder,
      neutralBg: neutralBg ?? this.neutralBg,
      neutralFg: neutralFg ?? this.neutralFg,
      neutralBorder: neutralBorder ?? this.neutralBorder,
    );
  }

  @override
  EdenStatusPalette lerp(ThemeExtension<EdenStatusPalette>? other, double t) {
    if (other is! EdenStatusPalette) return this;
    return EdenStatusPalette(
      successBg: Color.lerp(successBg, other.successBg, t)!,
      successFg: Color.lerp(successFg, other.successFg, t)!,
      successBorder: Color.lerp(successBorder, other.successBorder, t)!,
      warningBg: Color.lerp(warningBg, other.warningBg, t)!,
      warningFg: Color.lerp(warningFg, other.warningFg, t)!,
      warningBorder: Color.lerp(warningBorder, other.warningBorder, t)!,
      dangerBg: Color.lerp(dangerBg, other.dangerBg, t)!,
      dangerFg: Color.lerp(dangerFg, other.dangerFg, t)!,
      dangerBorder: Color.lerp(dangerBorder, other.dangerBorder, t)!,
      infoBg: Color.lerp(infoBg, other.infoBg, t)!,
      infoFg: Color.lerp(infoFg, other.infoFg, t)!,
      infoBorder: Color.lerp(infoBorder, other.infoBorder, t)!,
      neutralBg: Color.lerp(neutralBg, other.neutralBg, t)!,
      neutralFg: Color.lerp(neutralFg, other.neutralFg, t)!,
      neutralBorder: Color.lerp(neutralBorder, other.neutralBorder, t)!,
    );
  }
}

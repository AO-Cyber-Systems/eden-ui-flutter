// lib/src/theme/eden_brand_swatch.dart
//
// Runtime brand-color escape hatch (objective 022 TRD 02).
//
// EdenBrandPresetRegistry (objective 009) is a CLOSED set of 15 curated
// presets. Some Eden consumers — most concretely a Flutter web app that
// reads a single hex string from `window.APP_CONFIG` at boot — need to
// derive a full Eden-shaped MaterialColor from an ARBITRARY brand color
// that isn't in the registry at all. EdenBrandSwatch is that escape hatch:
// a pure function from one hex string (or Color) to an 11-shade
// MaterialColor, generated via an HSL lightness ramp anchored at the
// input's own lightness so that shade 500 always equals the input exactly.
//
// Do not extend this to mutate or replace EdenBrandPresetRegistry — the
// registry stays closed; this is a parallel, unrelated capability.

import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Parses an arbitrary hex color string into a full 11-shade Eden
/// [MaterialColor], or builds one directly from a [Color].
///
/// Eden's swatches carry eleven shades (50, 100, 200, 300, 400, 500, 600,
/// 700, 800, 900, 950) — one more than Flutter's conventional ten.
/// `EdenTheme.dark` dereferences `primary[950]!`, so a swatch missing that
/// shade is a dark-mode boot crash, not a cosmetic gap.
class EdenBrandSwatch {
  EdenBrandSwatch._();

  /// Mean HSL lightness (0-100) for each Eden shade, averaged across the
  /// seven non-neutral EdenColors swatches. This is the shape of the ramp;
  /// [fromColor] anchors it at the input's own lightness at shade 500.
  static const Map<int, double> _meanLightness = {
    50: 97.0,
    100: 92.8,
    200: 86.2,
    300: 76.3,
    400: 62.9,
    500: 53.1,
    600: 44.7,
    700: 37.5,
    800: 30.7,
    900: 25.2,
    950: 14.6,
  };

  /// Precomputed normalized position weights for shades lighter than 500,
  /// derived from [_meanLightness]. Embedded directly per the TRD research
  /// context — do not re-derive from [_meanLightness] at runtime.
  static const Map<int, double> _lightWeights = {
    50: 1.000000,
    100: 0.904328,
    200: 0.753986,
    300: 0.528474,
    400: 0.223235,
  };

  /// Precomputed normalized position weights for shades darker than 500.
  static const Map<int, double> _darkWeights = {
    600: 0.218182,
    700: 0.405195,
    800: 0.581818,
    900: 0.724675,
    950: 1.000000,
  };

  /// Parses [hex] into a full Eden [MaterialColor], or returns null if
  /// [hex] is not a recognizable color string.
  ///
  /// NEVER throws. Accepts (surrounding whitespace and a leading `#` are
  /// both optional):
  ///  - 6 hex digits — `RRGGBB` (e.g. `0F62FE`)
  ///  - 8 hex digits — `AARRGGBB` (e.g. `FF0F62FE`)
  ///  - 3 hex digits — shorthand `RGB`, expanded to `RRGGBB` (e.g. `F00`)
  ///
  /// Any other input — wrong length, non-hex characters, a signed form
  /// like `-0F62FE` that would otherwise sneak past `int.tryParse(radix:
  /// 16)`, or null — returns null rather than throwing, so callers can use
  /// this directly against untrusted runtime config (e.g. a hex string
  /// read from `window.APP_CONFIG` at web-app boot) without a try/catch.
  static MaterialColor? tryParse(String? hex) {
    if (hex == null) return null;
    var value = hex.trim();
    if (value.isEmpty) return null;
    if (value.startsWith('#')) {
      value = value.substring(1);
    }
    if (value.isEmpty) return null;

    // Reject anything that isn't pure hex digits BEFORE calling
    // int.tryParse — int.tryParse(..., radix: 16) accepts a leading `+`
    // or `-` sign, which would otherwise let a string like `-0F62FE`
    // silently parse as a negative int instead of being rejected here.
    if (!RegExp(r'^[0-9A-Fa-f]+$').hasMatch(value)) return null;

    switch (value.length) {
      case 3:
        final expanded = value.split('').map((c) => '$c$c').join();
        value = 'FF$expanded';
        break;
      case 6:
        value = 'FF$value';
        break;
      case 8:
        break;
      default:
        return null;
    }

    final argb = int.tryParse(value, radix: 16);
    if (argb == null) return null;

    return fromColor(Color(argb));
  }

  /// Builds a full Eden 11-shade [MaterialColor] from [seed] directly.
  ///
  /// Shade 500 is [seed] exactly — [seed]'s hue and saturation are held
  /// fixed and only lightness is varied to produce the other ten shades,
  /// via an HSL lightness ramp anchored at [seed]'s own lightness. This is
  /// the only ramp family that can guarantee `swatch[500] == seed` exactly;
  /// tonal-palette approaches (e.g. `ColorScheme.fromSeed`) re-tone the
  /// seed and were rejected for that reason.
  static MaterialColor fromColor(Color seed) {
    final hsl = HSLColor.fromColor(seed);
    final anchorL = hsl.lightness * 100.0;

    // Both clamps are load-bearing: without them the ramp inverts for
    // near-white (light50 < light500) or near-black (dark950 > dark500)
    // inputs. They no-op for normal brand colors.
    final lightEnd = math.max(97.0, (anchorL + 100.0) / 2.0);
    final darkEnd = math.min(14.6, anchorL / 2.0);

    final shades = <int, Color>{};
    for (final shade in _meanLightness.keys) {
      if (shade == 500) {
        shades[shade] = seed;
        continue;
      }
      double lightness;
      if (shade < 500) {
        final t = _lightWeights[shade]!;
        lightness = anchorL + t * (lightEnd - anchorL);
      } else {
        final u = _darkWeights[shade]!;
        lightness = anchorL - u * (anchorL - darkEnd);
      }
      shades[shade] = hsl.withLightness((lightness / 100.0).clamp(0.0, 1.0)).toColor();
    }

    return MaterialColor(seed.value, {
      50: shades[50]!,
      100: shades[100]!,
      200: shades[200]!,
      300: shades[300]!,
      400: shades[400]!,
      500: shades[500]!,
      600: shades[600]!,
      700: shades[700]!,
      800: shades[800]!,
      900: shades[900]!,
      950: shades[950]!,
    });
  }
}

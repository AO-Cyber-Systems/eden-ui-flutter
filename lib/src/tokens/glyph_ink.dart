import 'package:flutter/material.dart';

import 'colors.dart';

/// The ink a SEMANTIC hue takes when it carries its meaning as a GLYPH — a
/// dot, an icon, a rule — rather than as a word.
///
/// WHY THIS EXISTS. Eden's hues are tuned against the DARK surface, and every
/// one of them falls to roughly 2:1 when the same token is painted as a glyph
/// on the LIGHT one. Measured on the 34 re-blessed story baselines
/// (eden-ui-flutter#55):
///
///   selected rail icon, `colorScheme.primary` on the 10% band
///     light  #D4A853              2.05:1
///     dark   #E59A3C (gold[400])  6.49:1
///
///   The hex is split per brightness because `colorScheme.primary` RESOLVES
///   differently per theme. The dark figure is `gold[400]` on its own
///   surface, not `#D4A853` re-measured there — that pair is 6.85:1. One row
///   quoting a single hex against two ratios reads as one colour measured
///   twice, and it is two colours measured once each.
///
///   That rail band is also gone as of eden-ui-flutter#58's review — the
///   selected row now carries a solid pill and an `onPrimaryContainer` rim
///   (`EdenNavSelectionIndicator`), because 1.08:1 light / 1.17:1 dark
///   against the rail's own fill never identified anything. Both ratios
///   above are unaffected: they measure the same `colorScheme.primary`
///   against a surface of that same colour either way. The label is updated
///   so this founding example still names something that exists.
///   appointment status dot, `successFg` #10B981
///                              on `surfaceContainerHigh`    2.00:1 light
///                                                           5.87:1 dark
///   truncation-notice icon, `warningFg` #F59E0B
///                              on `surfaceContainerLow`     2.06:1 light
///                                                           8.25:1 dark
///
/// Three components, three hues, three surfaces, all within 0.06 of each other
/// at ~2.0:1 in light and comfortable in dark. WCAG 1.4.11's floor for
/// non-text is 3:1. That is not three coincidences; it is the palette having
/// no headroom on the light surface, and nothing in this package measuring it.
///
/// THE TONE HAS TO BE SPLIT BY BRIGHTNESS — this is the finding, not a
/// convenience. There is no single tone in either ramp that clears 3:1 on both
/// themes' surfaces for these components:
///
///   emerald[600] #059669   2.97:1 on light `surfaceContainerHigh`  FAILS
///                          3.95:1 on dark  `surfaceContainerHigh`
///   emerald[700] #047857   4.32:1 light                            OK
///                          2.72:1 dark                             FAILS
///   amber[700]   #B45309   3.96:1 on light `surfaceContainerHigh`  OK
///                          2.97:1 on dark  `surfaceContainerHigh`  FAILS
///
/// So a glyph token is a PAIR, and anything that tries to be one value is
/// wrong in one theme. The dark member is the base hue — it already clears the
/// floor there and is the tone the palette was designed around; the light
/// member is two steps down the same ramp.
///
/// SCOPE, stated because the exemption matters. WCAG 1.4.11 does not bind a
/// glyph that is purely decorative or fully redundant with adjacent text. Two
/// of the three sites above are arguably exempt on those grounds — the status
/// dot sits beside the word "confirmed", the notice icon beside its sentence.
/// They use this anyway, because "whether it happens to sit next to
/// explanatory text" is not a property a palette can know, and a hue that is
/// invisible on half the themes it ships in is a defect either way. Where a
/// glyph is genuinely decoration and the hue is the point — a chip fill, a
/// gradient, a chart band — keep the base hue and do not reach for this.
///
/// NOT PROFILE-AWARE, recorded rather than fixed. [EdenStatusPalette] varies
/// its hues by vertical profile, and this does not follow it: the `govFederal`
/// palette's own `successFg` #00A91C is 2.47:1 and its `warningFg` #FFBE2E is
/// 1.59:1 on the light surfaces above, so following the profile here would
/// mean shipping a conformance floor that two profiles fail. Giving each
/// profile a measured glyph pair is the real answer and it is a separate
/// decision; until then this is the floor, in every profile.
class EdenGlyphInk {
  EdenGlyphInk._();

  /// The four tones resolved against **the theme's** brightness.
  ///
  /// PREFER THIS OVER THE `Brightness` FORMS AT A WIDGET CALL SITE, and the
  /// reason is a foot-gun with no instrument behind it. The bare
  /// `Brightness` overloads are correct only if the caller threads the
  /// THEME's brightness. The obvious-looking alternative —
  /// `MediaQuery.platformBrightnessOf(context)` — is the PLATFORM's, and it
  /// disagrees with the theme whenever the app pins `ThemeMode.light`/`dark`
  /// or a subtree overrides `Theme`. A caller who reaches for it on a light
  /// surface gets the dark member: `emerald[500]` at 2.00:1, which is the
  /// exact defect this class was created to fix (eden-ui-flutter#55).
  ///
  /// Nothing could see that mistake. It is not a type error, no lint names
  /// it, and the oracle only measures surfaces a story actually pumps. So
  /// the fix is to make the right thing the short thing:
  ///
  /// ```dart
  /// EdenGlyphInk.of(context).success   // theme brightness, always
  /// ```
  ///
  /// The `Brightness` forms stay for tests, which pump both themes
  /// explicitly and have no `BuildContext` to hand.
  static EdenGlyphInkSet of(BuildContext context) =>
      EdenGlyphInkSet._(Theme.of(context).brightness);

  /// Success/confirmed, as a glyph. `emerald[700]` light, `emerald[500]` dark.
  ///
  ///   light 4.32:1 on `surfaceContainerHigh`, 5.25:1 on `surfaceContainerLow`
  ///   dark  5.87:1 on `surfaceContainerHigh`, 6.98:1 on `surfaceContainerLow`
  static Color success(Brightness brightness) =>
      brightness == Brightness.light
          ? EdenColors.emerald[700]!
          : EdenColors.success;

  /// Warning/truncation, as a glyph. `amber[700]` light, `amber[500]` dark.
  ///
  ///   light 3.96:1 on `surfaceContainerHigh`, 4.81:1 on `surfaceContainerLow`
  ///   dark  6.94:1 on `surfaceContainerHigh`, 8.25:1 on `surfaceContainerLow`
  static Color warning(Brightness brightness) =>
      brightness == Brightness.light
          ? EdenColors.amber[700]!
          : EdenColors.warning;

  /// Danger/error, as a glyph. `red[600]` light, `red[500]` dark.
  ///
  /// The only one of the four that was NOT failing: `EdenRefusal`'s red
  /// `block` icon measures 3.61:1 on `#FAFAFA` today. It is here so the four
  /// semantic glyph tones are reached for the same way, and because 3.61:1 is
  /// a 0.61 margin — `red[600]` takes it to 4.63:1 on the same surface.
  static Color danger(Brightness brightness) =>
      brightness == Brightness.light ? EdenColors.red[600]! : EdenColors.error;

  /// Info, as a glyph. `blue[600]` light, `blue[500]` dark.
  ///
  /// No site fails today; `info` #3B82F6 is 3.52:1 on `#FAFAFA`. Present for
  /// the same reason as [danger] — one way to ask for a glyph tone, so the
  /// next one added does not start from the base hue by default.
  static Color info(Brightness brightness) =>
      brightness == Brightness.light ? EdenColors.blue[600]! : EdenColors.info;
}

/// The four glyph tones already resolved against one brightness.
///
/// Returned by [EdenGlyphInk.of]; not constructed directly, so a caller
/// cannot hand it the platform brightness by accident — which is the whole
/// point of it existing.
class EdenGlyphInkSet {
  const EdenGlyphInkSet._(this.brightness);

  /// The brightness these four were resolved against. Exposed so a test can
  /// assert WHICH brightness a widget resolved, not merely that some colour
  /// came back.
  final Brightness brightness;

  /// See [EdenGlyphInk.success].
  Color get success => EdenGlyphInk.success(brightness);

  /// See [EdenGlyphInk.warning].
  Color get warning => EdenGlyphInk.warning(brightness);

  /// See [EdenGlyphInk.danger].
  Color get danger => EdenGlyphInk.danger(brightness);

  /// See [EdenGlyphInk.info].
  Color get info => EdenGlyphInk.info(brightness);
}

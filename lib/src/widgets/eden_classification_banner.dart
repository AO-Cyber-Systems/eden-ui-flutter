import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../tokens/spacing.dart';

/// Federal classification level per ICD 710 (Intelligence Community
/// Directive 710) + civilian-vertical custom escape hatch.
///
/// Federal levels (UNCLASSIFIED / CUI / SECRET / TOP SECRET) come with
/// mandated ICD 710 colors. The [custom] level supports civilian re-use
/// as a generic sensitivity banner — consumer passes [labelText] +
/// [backgroundColor] + [foregroundColor] to render commercial labels.
enum EdenClassificationLevel {
  unclassified,
  controlledUnclassified,
  secret,
  topSecret,
  custom,
}

/// Banner display mode.
enum EdenClassificationDisplay {
  /// Full-width strip. The dominant federal pattern; sits at top (and
  /// optionally bottom) of every regulated screen.
  bar,

  /// Semi-transparent diagonal overlay. Used for screen-capture-sensitive
  /// content as a visual deterrent + provenance marker.
  watermark,
}

// ICD 710 mandated federal palette. Local stub until Objective 009 ships
// `Theme.of(context).extension<EdenStatusPalette>()` with the
// `EdenThemeProfile.govFederal` profile — at which point this widget will
// resolve colors from the theme instead.
//
// Research-confirmed sources:
//  - DOD Instruction 5200.48 (Controlled Unclassified Information)
//  - GSA CUI Guide
//  - ICD 710 (Classification Management and Control Markings System)
const _classificationPalette = <EdenClassificationLevel, ({Color bg, Color fg})>{
  EdenClassificationLevel.unclassified:
      (bg: Color(0xFF007A33), fg: Color(0xFFFFFFFF)), // CIA Heritage Green
  EdenClassificationLevel.controlledUnclassified:
      (bg: Color(0xFF502B85), fg: Color(0xFFFFFFFF)), // ICD 710 Purple
  EdenClassificationLevel.secret:
      (bg: Color(0xFFC8102E), fg: Color(0xFFFFFFFF)), // ICD 710 Red
  EdenClassificationLevel.topSecret:
      (bg: Color(0xFFFF7F00), fg: Color(0xFF000000)), // ICD 710 Orange (black fg per contrast spec)
};

const _defaultLabels = <EdenClassificationLevel, String>{
  EdenClassificationLevel.unclassified: 'UNCLASSIFIED',
  EdenClassificationLevel.controlledUnclassified: 'CUI',
  EdenClassificationLevel.secret: 'SECRET',
  EdenClassificationLevel.topSecret: 'TOP SECRET',
};

/// A federal classification banner per ICD 710 (Intelligence Community
/// Directive 710).
///
/// Renders the classification level at top (and optionally bottom) of a
/// regulated app screen. Two display modes:
///
///  * [EdenClassificationDisplay.bar] — full-width top/bottom strip. The
///    dominant federal pattern.
///  * [EdenClassificationDisplay.watermark] — diagonal semi-transparent
///    overlay; useful for screen-capture-sensitive content.
///
/// Federal levels carry the ICD 710 mandated palette. Use
/// [EdenClassificationLevel.custom] for civilian-vertical re-use — pass
/// [labelText], [backgroundColor], and [foregroundColor] to render
/// commercial-context sensitivity labels ('CONFIDENTIAL', 'INTERNAL USE
/// ONLY', 'ATTORNEY-CLIENT PRIVILEGED', etc.).
///
/// Civilian re-use: see also [EdenSensitivityBanner], a typedef alias of
/// this widget surfaced under a commercial-friendly name. The library
/// ships them as a single source of truth — the only difference is the
/// public type name.
class EdenClassificationBanner extends StatelessWidget {
  const EdenClassificationBanner({
    super.key,
    required this.level,
    this.display = EdenClassificationDisplay.bar,
    this.labelText,
    this.backgroundColor,
    this.foregroundColor,
    this.height = 28,
    this.child,
  });

  /// Classification level. Drives default label + federal palette.
  final EdenClassificationLevel level;

  /// Display mode. Defaults to [EdenClassificationDisplay.bar].
  final EdenClassificationDisplay display;

  /// Optional label override. Required when [level] is
  /// [EdenClassificationLevel.custom]. Always rendered uppercase.
  final String? labelText;

  /// Optional background override. Required (with [foregroundColor]) when
  /// [level] is [EdenClassificationLevel.custom].
  final Color? backgroundColor;

  /// Optional foreground override.
  final Color? foregroundColor;

  /// Bar mode minimum height. Per ICD 710, min 28pt.
  final double height;

  /// Required when [display] is [EdenClassificationDisplay.watermark] —
  /// the content underneath the diagonal overlay.
  final Widget? child;

  String _resolveLabel() {
    final raw = labelText ?? _defaultLabels[level] ?? '';
    return raw.toUpperCase();
  }

  Color _resolveBg() {
    if (backgroundColor != null) return backgroundColor!;
    final palette = _classificationPalette[level];
    return palette?.bg ?? const Color(0xFF6B7280); // neutral fallback
  }

  Color _resolveFg() {
    if (foregroundColor != null) return foregroundColor!;
    final palette = _classificationPalette[level];
    return palette?.fg ?? const Color(0xFFFFFFFF);
  }

  @override
  Widget build(BuildContext context) {
    final label = _resolveLabel();
    final bg = _resolveBg();
    final fg = _resolveFg();

    if (display == EdenClassificationDisplay.bar) {
      return Semantics(
        label: '$label classification banner',
        container: true,
        readOnly: true,
        child: Container(
          width: double.infinity,
          constraints: BoxConstraints(minHeight: height),
          color: bg,
          padding: const EdgeInsets.symmetric(
            horizontal: EdenSpacing.space2,
            vertical: 4,
          ),
          alignment: Alignment.center,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              maxLines: 1,
              style: TextStyle(
                color: fg,
                fontWeight: FontWeight.w700,
                fontSize: 14,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
      );
    }

    // Watermark mode.
    assert(
      child != null,
      'EdenClassificationBanner watermark mode requires a non-null child',
    );
    return Stack(
      children: [
        child!,
        Positioned.fill(
          child: IgnorePointer(
            child: Center(
              child: Transform.rotate(
                angle: -math.pi / 4,
                child: Opacity(
                  opacity: 0.16,
                  child: Text(
                    label,
                    style: TextStyle(
                      color: fg,
                      fontWeight: FontWeight.w700,
                      fontSize: 64,
                      letterSpacing: 4,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Civilian-vertical alias for [EdenClassificationBanner]. Same widget,
/// surfaced under a commercial-friendly name for downstream apps that
/// render generic sensitivity labels (CONFIDENTIAL, INTERNAL USE ONLY,
/// ATTORNEY-CLIENT PRIVILEGED, etc.) without federal-domain framing.
typedef EdenSensitivityBanner = EdenClassificationBanner;

/// Wraps a content [child] with top (and optional bottom) classification
/// banners per ICD 710 dual-marking standard.
///
/// Mirrors the screen-scaffold pattern used in trades-flutter app shells.
/// Use as `Scaffold(body: EdenClassificationBannerScaffold(level: ...,
/// child: ...))` to mark an entire regulated page.
class EdenClassificationBannerScaffold extends StatelessWidget {
  const EdenClassificationBannerScaffold({
    super.key,
    required this.level,
    required this.child,
    this.showBottomBanner = false,
    this.labelText,
    this.backgroundColor,
    this.foregroundColor,
  });

  final EdenClassificationLevel level;
  final Widget child;

  /// When true, renders a duplicate banner at the bottom of the page
  /// (per ICD 710 dual-marking standard for SECRET / TOP SECRET).
  final bool showBottomBanner;

  final String? labelText;
  final Color? backgroundColor;
  final Color? foregroundColor;

  @override
  Widget build(BuildContext context) {
    final banner = EdenClassificationBanner(
      level: level,
      labelText: labelText,
      backgroundColor: backgroundColor,
      foregroundColor: foregroundColor,
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        banner,
        Expanded(child: child),
        if (showBottomBanner) banner,
      ],
    );
  }
}

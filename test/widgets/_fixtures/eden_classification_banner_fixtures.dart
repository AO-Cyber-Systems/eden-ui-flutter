// Do NOT regenerate via LLM — hand-built fixtures for EdenClassificationBanner.
//
// ICD 710 federal classification palette + civilian-vertical custom level
// references. Used by `eden_classification_banner_test.dart` to verify both
// color-binding correctness and WCAG 2.1 contrast for every shipped level.

import 'dart:math' as math;
import 'package:flutter/material.dart';

class EdenClassificationBannerFixtures {
  EdenClassificationBannerFixtures._();

  // ICD 710 mandated hex values (research-confirmed; do NOT pull from EdenColors).
  static const icdGreen = Color(0xFF007A33); // UNCLASSIFIED
  static const icdPurple = Color(0xFF502B85); // CUI
  static const icdRed = Color(0xFFC8102E); // SECRET
  static const icdOrange = Color(0xFFFF7F00); // TOP SECRET

  static const white = Color(0xFFFFFFFF);
  static const black = Color(0xFF000000);

  static const unclassifiedPalette = (bg: icdGreen, fg: white);
  static const cuiPalette = (bg: icdPurple, fg: white);
  static const secretPalette = (bg: icdRed, fg: white);
  static const topSecretPalette = (bg: icdOrange, fg: black);

  // Civilian-vertical sample sensitivity labels.
  static const customConfidential = (
    label: 'CONFIDENTIAL',
    bg: Color(0xFFF59E0B),
    fg: white,
  );
  static const customPrivilege = (
    label: 'ATTORNEY-CLIENT PRIVILEGED',
    bg: Color(0xFFA855F7),
    fg: white,
  );

  /// WCAG 2.1 relative-luminance contrast ratio.
  ///
  /// Formula: L = 0.2126*R + 0.7152*G + 0.0722*B (sRGB linearized).
  /// Ratio = (Lmax + 0.05) / (Lmin + 0.05).
  ///
  /// Sanity: black vs white = 21.0.
  static double contrastRatio(Color a, Color b) {
    final la = _relativeLuminance(a);
    final lb = _relativeLuminance(b);
    final lmax = math.max(la, lb);
    final lmin = math.min(la, lb);
    return (lmax + 0.05) / (lmin + 0.05);
  }

  static double _relativeLuminance(Color c) {
    final r = _channelToLinear(c.red / 255.0);
    final g = _channelToLinear(c.green / 255.0);
    final b = _channelToLinear(c.blue / 255.0);
    return 0.2126 * r + 0.7152 * g + 0.0722 * b;
  }

  static double _channelToLinear(double v) {
    return v <= 0.03928 ? v / 12.92 : math.pow((v + 0.055) / 1.055, 2.4) as double;
  }
}

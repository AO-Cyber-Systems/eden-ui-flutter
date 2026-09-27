// WCAG 2.x contrast arithmetic, written out FROM THE SPEC.
//
// IMPORT CONVENTION: `test_support/` is a top-level directory and is NOT part
// of the package's `lib/`, so there is no `package:eden_ui_flutter/...` URI for
// it. Tests reach this file by RELATIVE import:
//
//     import '../../test_support/ui_oracle/wcag_contrast.dart';
//
// WHY IT IS NOT READ OFF THE CODE UNDER TEST. A contrast assertion that calls
// the library's own colour maths proves the library agrees with itself. These
// two functions are transcribed from
// https://www.w3.org/TR/WCAG21/#dfn-relative-luminance and
// https://www.w3.org/TR/WCAG21/#dfn-contrast-ratio and depend on nothing in
// `lib/`.
//
// WHY IT IS SHARED. `eden_mobile_layout_selected_state_test.dart` (the bar) and
// `eden_mobile_layout_drawer_selected_state_test.dart` (the drawer and the
// "More" sheet) hold three renderings of ONE nav row to one floor. Two copies
// of the formula is two places for the floor to drift.
library;

import 'dart:math' as math;
import 'dart:ui' show Color;

/// WCAG 2.x relative luminance of [colour].
double wcagRelativeLuminance(Color colour) {
  double channel(double c) =>
      c <= 0.03928 ? c / 12.92 : math.pow((c + 0.055) / 1.055, 2.4).toDouble();
  return 0.2126 * channel(colour.r) +
      0.7152 * channel(colour.g) +
      0.0722 * channel(colour.b);
}

/// WCAG 2.x contrast ratio between [a] and [b], in the range 1.0 .. 21.0.
///
/// Both colours must be OPAQUE. A translucent colour has no contrast ratio of
/// its own — composite it over its backdrop first (`Color.alphaBlend`) or the
/// answer is meaningless.
double wcagContrastRatio(Color a, Color b) {
  final double la = wcagRelativeLuminance(a);
  final double lb = wcagRelativeLuminance(b);
  final double hi = math.max(la, lb);
  final double lo = math.min(la, lb);
  return (hi + 0.05) / (lo + 0.05);
}

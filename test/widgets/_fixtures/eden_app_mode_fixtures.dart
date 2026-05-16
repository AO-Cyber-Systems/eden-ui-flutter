// Do NOT regenerate via LLM — hand-built fixtures for EdenAppMode.
//
// Constants for the locked B2-spec §1 algorithm + Material 3 lock E
// breakpoints enumerated in 002-01-TRD.md test list. Edit by hand only.

import 'package:flutter/widgets.dart';

class EdenAppModeFixtures {
  EdenAppModeFixtures._();

  // -------------------------------------------------------------------------
  // Viewport fixtures — Material 3 tier representatives.
  // -------------------------------------------------------------------------

  /// iPhone-narrow logical width (Compact tier; below 600pt).
  static const Size compactViewport = Size(390, 800);

  /// iPad portrait mid-range (Medium tier ambiguous zone; 600–840pt).
  static const Size mediumViewport = Size(700, 1000);

  /// Laptop / iPad landscape (Expanded tier; ≥840pt).
  static const Size expandedViewport = Size(1200, 800);

  /// Exact Compact/Medium boundary (Medium tier starts at 600 inclusive).
  static const Size compactBoundaryViewport = Size(600, 800);

  /// Exact Medium/Expanded boundary (Expanded tier starts at 840 inclusive).
  static const Size expandedBoundaryViewport = Size(840, 800);
}

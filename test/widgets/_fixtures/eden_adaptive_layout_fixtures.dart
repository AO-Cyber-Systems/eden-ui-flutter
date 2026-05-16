// Do NOT regenerate via LLM — hand-built fixtures for EdenAdaptiveLayout.
//
// Width probes covering the Material 3 three-tier classification locked at
// COMPANION_UX_PATTERNS_2026-05-15.md §0 lock E. Edit by hand only.

import 'package:eden_ui_flutter/eden_ui.dart';
import 'package:flutter/widgets.dart';

class EdenAdaptiveLayoutFixtures {
  EdenAdaptiveLayoutFixtures._();

  /// Representative widths across all three tiers + the exact boundaries.
  /// Each value is paired with the [EdenAdaptiveTier] the spec says it
  /// should resolve to (see [expectedTierFor]).
  static const List<double> tierProbeWidths = <double>[
    390, // Compact (iPhone-narrow)
    599, // Compact (one below the 600 boundary)
    600, // Medium (boundary inclusive)
    700, // Medium (mid)
    839, // Medium (one below the 840 boundary)
    840, // Expanded (boundary inclusive)
    1200, // Expanded (laptop)
    1600, // Expanded (external monitor)
  ];

  /// Pure helper mirroring the spec — used by tests to assert.
  static EdenAdaptiveTier expectedTierFor(double width) {
    if (width < 600.0) return EdenAdaptiveTier.compact;
    if (width < 840.0) return EdenAdaptiveTier.medium;
    return EdenAdaptiveTier.expanded;
  }

  /// Tagged widget builders — let tests assert WHICH builder was called via
  /// `find.byKey(...)`.
  static Widget compactTagged(BuildContext _) =>
      Container(key: const ValueKey('compact'), child: const Text('compact'));

  static Widget mediumTagged(BuildContext _) =>
      Container(key: const ValueKey('medium'), child: const Text('medium'));

  static Widget expandedTagged(BuildContext _) =>
      Container(key: const ValueKey('expanded'), child: const Text('expanded'));
}

// Do NOT regenerate via LLM — hand-built fixtures for EdenUxModeToggle.
//
// Donor mapping (locked at COMPANION_UX_PATTERNS_2026-05-15.md §0 lock A
// + 002-03-TRD.md):
//   trades-react 'mobile' (smartphone)  →  EdenAppMode.fieldCompanion
//   trades-react 'desktop' (monitor)    →  EdenAppMode.admin
//   trades-react 'auto' (sparkles)      →  EdenAppMode.askUser

import 'package:eden_ui_flutter/eden_ui.dart';
import 'package:flutter/material.dart';

class EdenUxModeToggleFixtures {
  EdenUxModeToggleFixtures._();

  /// Default controller starting at askUser (auto/sparkles).
  static EdenAppModeController defaultController() =>
      EdenAppModeController(initialMode: EdenAppMode.askUser);

  /// Controller starting at the given mode. The returned `recorded`
  /// list captures every onChange callback's payload so tests can
  /// assert tap-sequences and ordering.
  static (EdenAppModeController, List<EdenAppMode>) controllerStartingAt(
    EdenAppMode initial,
  ) {
    final recorded = <EdenAppMode>[];
    final controller = EdenAppModeController(
      initialMode: initial,
      onChange: recorded.add,
    );
    return (controller, recorded);
  }

  /// Single source of truth for the Material-icon mapping. Mirrors the
  /// donor's lucide-react icons (Smartphone / Monitor / Sparkles).
  static IconData expectedIconFor(EdenAppMode mode) {
    switch (mode) {
      case EdenAppMode.fieldCompanion:
        return Icons.smartphone;
      case EdenAppMode.admin:
        return Icons.desktop_windows;
      case EdenAppMode.askUser:
        return Icons.auto_awesome;
    }
  }

  /// Short labels (≤8 chars) for the labeled variant.
  static String expectedLabelFor(EdenAppMode mode) {
    switch (mode) {
      case EdenAppMode.fieldCompanion:
        return 'Field';
      case EdenAppMode.admin:
        return 'Admin';
      case EdenAppMode.askUser:
        return 'Auto';
    }
  }

  /// Human-readable tooltip strings.
  static String expectedTooltipFor(EdenAppMode mode) {
    switch (mode) {
      case EdenAppMode.fieldCompanion:
        return 'Field companion';
      case EdenAppMode.admin:
        return 'Admin (desktop view)';
      case EdenAppMode.askUser:
        return 'Auto (resize-driven)';
    }
  }
}

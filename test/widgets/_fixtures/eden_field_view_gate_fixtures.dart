// Do NOT regenerate via LLM — hand-built fixtures for EdenFieldViewGate.
//
// Helpers for mounting widgets behind an [EdenAppModeScope] with a
// pre-seeded controller. Edit by hand only.

import 'package:eden_ui_flutter/eden_ui.dart';
import 'package:flutter/material.dart';

class EdenFieldViewGateFixtures {
  EdenFieldViewGateFixtures._();

  /// Make a controller starting at the given mode.
  static EdenAppModeController controllerStartingAt(EdenAppMode initial) {
    return EdenAppModeController(initialMode: initial);
  }

  /// Wrap [child] under an [EdenAppModeScope] controlled by [c].
  /// The standard mounting fixture for every test in this TRD.
  static Widget wrapWithScope(Widget child, EdenAppModeController c) {
    return MaterialApp(
      home: Scaffold(
        body: EdenAppModeScope(controller: c, child: child),
      ),
    );
  }
}

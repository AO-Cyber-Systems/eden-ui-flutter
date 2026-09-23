/// Test-only assertions for surfaces built with Eden UI.
///
/// Import from a consumer's `test/` directory ONLY:
///
/// ```dart
/// import 'package:eden_ui_flutter/testing.dart';
/// ```
///
/// NEVER from production code. This library imports `package:flutter_test`,
/// which is a dev_dependency of this package; importing it from `lib/` in a
/// consumer app drags flutter_test into that app's release graph and breaks
/// the build. `lib/eden_ui.dart` deliberately does NOT export this file, and
/// nothing under `lib/src/` imports it.
///
/// This is a SEPARATE public entry point: `package:eden_ui_flutter/testing.dart`
/// resolves to `lib/testing.dart` and to nothing else.
library;

export 'testing/expect_ui_sane.dart';
export 'testing/semantics_geometry.dart'
    show SemanticsGeometryNode, globalRectOf, identifiedNodes, rectsOverlap;

// The UI Oracle pump helper.
//
// IMPORT CONVENTION: `test_support/` is a top-level directory and is NOT part
// of the package's `lib/`, so there is no `package:eden_ui_flutter/...` URI for
// it. Tests reach this file by RELATIVE import:
//
//     import '../../test_support/ui_oracle/wrap.dart';
//
// This convention is load-bearing for 23-03's generated story tests.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:eden_ui_flutter/eden_ui.dart';

/// Pumps [child] inside a Material surface laid out at exactly [width] logical
/// pixels, replacing the raw `MaterialApp` boilerplate that widget tests in
/// this repo write by hand (see `test/widgets/eden_desktop_layout_test.dart`).
///
/// The view override is torn down via [addTearDown]: a leaked `physicalSize`
/// silently changes the viewport of the NEXT test in the same file and turns
/// its golden red.
///
/// [themeMode] selects between `EdenTheme.light()` and `EdenTheme.dark()`;
/// [theme] overrides the light theme when supplied.
///
/// GOTCHA — THE CHILD SLOT IS TIGHT. [child] is laid out inside
/// `SizedBox(width: width)`, which hands it a TIGHT width constraint, so a
/// child's OWN `SizedBox(width: n)` is clamped straight back to [width] by
/// `BoxConstraints.enforce`. A surface that wants a narrower frame must be
/// pumped at a narrower [width] — declare `EdenStory.viewportWidth` and the
/// story harness passes it here. Two goldens were byte-identical to their
/// siblings for exactly this reason before it was declared.
///
/// GOTCHA: this calls `pumpAndSettle()`, which throws on an animation that
/// never settles. A child with an infinite/repeating animation must be pumped
/// by the caller instead — pump a fixed `Duration` after `wrap()` returns
/// rather than asking `wrap()` to settle it.
///
/// NO DEBUG BANNER (eden-ui-flutter#52). `MaterialApp` paints the red
/// "DEBUG" ribbon across the top-right corner by default, and a widget test
/// runs in debug mode, so the ribbon went into every golden baseline this
/// helper produced. It is not merely cosmetic: it is painted OVER the
/// surface, so whatever occupies the top-right corner of a story is hidden
/// behind it and the occlusion is what gets blessed as correct. Turning it
/// off is what lets that corner be a pinned part of the comparison instead of
/// a region nothing can see into.
///
/// ICON GLYPHS come from `test/flutter_test_config.dart`, not from here:
/// `MaterialIcons` has to be registered with the text shaper before any
/// widget is pumped, and that bootstrap is the only place in the suite that
/// is real-async. Without it every `Icon` in a wrapped surface rasterises as
/// an empty square — see that file's header.
Future<void> wrap(
  WidgetTester tester,
  Widget child, {
  double width = 1280,
  double height = 800,
  ThemeMode themeMode = ThemeMode.light,
  ThemeData? theme,
}) async {
  tester.view.devicePixelRatio = 1.0;
  tester.view.physicalSize = Size(width, height);
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    MaterialApp(
      // See the doc comment: the banner is painted over the surface and was
      // blessed into every baseline, occluding whatever sat under it.
      debugShowCheckedModeBanner: false,
      theme: theme ?? EdenTheme.light(),
      darkTheme: EdenTheme.dark(),
      themeMode: themeMode,
      home: Scaffold(
        body: Center(child: SizedBox(width: width, child: child)),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

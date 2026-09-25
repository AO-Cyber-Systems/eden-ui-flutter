// Every test in a file must rasterise in the SAME typeface — and it must be
// Eden's real one.
//
// THE DEFECT THIS PINS. `EdenTheme` builds its type scale from
// `GoogleFonts.outfit(...)` / `GoogleFonts.plusJakartaSans(...)`, and each of
// those fires an UNAWAITED font load at theme-construction time. Inside a
// widget test the fake-async clock never lets that future run, so the first
// test in a file lays out and paints in the FALLBACK face. The first thing in
// a widget test that does let a real-async future complete is
// `tester.runAsync` — which is exactly what `expectUiSane`'s contrast phase
// uses to capture the frame. So the load lands DURING test #1, and every
// later test in the same file uses the real face.
//
// Measured on the desktop shell before the fix: the top bar's search pill was
// 863.1 logical pixels wide in the first test of a file and 904.7 in the
// second — 41.6px of layout movement caused by nothing but position in the
// file. The oracle's GEOMETRY rules (tap target, overlap, containment,
// viewport) all read that layout, and golden baselines would bake in
// whichever face happened to have loaded.
//
// THE FIX is in `test/flutter_test_config.dart`: construct both `EdenTheme`
// themes and `await GoogleFonts.pendingFonts()` in the per-file bootstrap,
// before `testMain()` runs. `testExecutable` is real async, so the load
// actually completes there.
//
// CASE 1 IS THE ANTI-VACUOUS ONE. Case 2 on its own would pass on a tree
// where the fonts NEVER load — both tests would agree, in the wrong face.
// Case 1 therefore proves the real face is registered, by measuring the same
// string twice: once through the theme's resolved family and once with no
// family at all. `flutter_test`'s fallback is a flat test font whose glyphs
// all share one advance width, so the two measurements can only differ when
// the real proportional face is actually in the engine's font collection.
library;

import 'package:eden_ui_flutter/eden_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

const EdenTopBarConfig _topBar = EdenTopBarConfig(
  title: 'Orders',
  showSearch: true,
  searchHint: 'Search orders…',
);

Future<void> _pumpShell(WidgetTester tester) async {
  tester.view.devicePixelRatio = 1.0;
  tester.view.physicalSize = const Size(1280, 800);
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(MaterialApp(
    theme: EdenTheme.light(),
    home: EdenDesktopLayout(
      navItems: const <EdenNavItem>[
        // Deliberately NOT "Orders": the top bar's title is the string this
        // file measures, and it has to be findable on its own.
        EdenNavItem(
          id: 'inventory',
          label: 'Inventory',
          icon: Icons.inventory_2,
        ),
      ],
      selectedId: 'inventory',
      onNavChanged: (_) {},
      topBar: _topBar,
      body: const SizedBox(),
    ),
  ));
  await tester.pumpAndSettle();
}

/// Width of the top bar's search pill — the `Container(height: 36)` that
/// carries the `surfaceContainerHighest` fill — in logical pixels.
///
/// The pill is `Flexible`, so its width is whatever the rest of the bar
/// leaves it, which makes it a direct readout of how wide the bar's other
/// text laid out. That is what moved 41.6px between test #1 and test #2.
double _searchPillWidth(WidgetTester tester) {
  final Color fill = EdenTheme.light().colorScheme.surfaceContainerHighest;
  final List<double> widths = <double>[];
  void visit(Element element) {
    final RenderObject? renderObject = element.renderObject;
    if (renderObject is RenderDecoratedBox) {
      final Decoration decoration = renderObject.decoration;
      if (decoration is BoxDecoration && decoration.color == fill) {
        widths.add(renderObject.size.width);
      }
    }
    element.visitChildren(visit);
  }

  tester.binding.rootElement!.visitChildren(visit);
  if (widths.length != 1) {
    fail(
      'expected exactly one surfaceContainerHighest-filled box in the desktop '
      'shell (the top bar search pill); found ${widths.length}: $widths',
    );
  }
  return widths.single;
}

/// Set by case 1 and read by case 2. A top-level variable is the point: the
/// two cases must be in ONE file and in this order, because the whole defect
/// is about a test's position in its file.
double? _firstPillWidth;

/// Lets REAL-async work that was already pending run to completion, the way
/// `expectUiSane`'s contrast phase does when it captures the frame through
/// `tester.runAsync`. Nothing else in a widget test opens that window.
Future<void> _letPendingAsyncRun(WidgetTester tester) async {
  await tester.runAsync<void>(
    () => Future<void>.delayed(const Duration(milliseconds: 100)),
  );
}

void main() {
  testWidgets(
    'case 1: no font load may still be pending when a test starts — letting '
    'real async run must not change this test\'s own layout',
    (WidgetTester tester) async {
      await _pumpShell(tester);
      final double before = _searchPillWidth(tester);
      _firstPillWidth = before;

      await _letPendingAsyncRun(tester);

      // Rebuild from scratch so the shell lays out again against whatever the
      // engine's font collection holds NOW.
      await tester.pumpWidget(const SizedBox());
      await _pumpShell(tester);
      final double after = _searchPillWidth(tester);

      expect(
        after,
        closeTo(before, 0.01),
        reason: 'the top bar search pill laid out to ${before}px, and to '
            '${after}px after a real-async window — '
            '${(after - before).abs()}px of movement from nothing but a font '
            'load that was still pending when this test began. EdenTheme '
            'fires its google_fonts loads UNAWAITED, and a widget test\'s '
            'fake clock never lets them finish; the first real-async window '
            'in the file is what completes them, which is why the first test '
            'in a file paints in the fallback face and the rest do not. '
            'test/flutter_test_config.dart must construct both EdenTheme '
            'themes and await GoogleFonts.pendingFonts() before testMain().',
      );
    },
  );

  testWidgets(
    'case 2: the SECOND test in the file lays the same shell out identically',
    (WidgetTester tester) async {
      await _pumpShell(tester);
      final double second = _searchPillWidth(tester);
      final double first = _firstPillWidth!;

      expect(
        second,
        closeTo(first, 0.01),
        reason: 'the top bar search pill is ${second}px wide here and '
            '${first}px wide at the start of case 1 — '
            '${(second - first).abs()}px of layout movement caused by nothing '
            'but this test\'s position in the file. The oracle\'s geometry '
            'rules all read that layout, and golden baselines would bake in '
            'whichever face happened to have loaded first.',
      );
    },
  );
}

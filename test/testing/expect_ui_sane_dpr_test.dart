// The oracle's viewport rule, at a REAL device pixel ratio.
//
// THE DEFECT THIS PINS. `_viewportViolations` compared a PHYSICAL-pixel
// `globalRect` (the semantics transform composes the device-pixel-ratio scale)
// against a LOGICAL viewport (`physicalSize / devicePixelRatio`). At any ratio
// but 1 the rect is `ratio` times too large and the viewport is not, so every
// control on every surface is falsely named as off-screen.
//
// It was latent only because `wrap()` — and `pumpSurface` in
// `expect_ui_sane_test.dart` — pin `devicePixelRatio` to 1, where the two
// numbers coincide. The oracle was correct by accident of its own harness.
//
// WHY THAT IS WORSE THAN AN ORDINARY LATENT BUG. Everything else in this repo
// trusts the oracle, and a check that fires on EVERY control the first time
// somebody pumps at a phone's real ratio does not get debugged — it gets
// switched off, along with the four rules sitting next to it.
//
// THE DIFFERENTIAL. Cases 2 and 3 fail on the pre-fix oracle (2 violations
// each, one per control in `cleanSurface()`) and pass after. Case 4 is what
// stops "fix the units" degenerating into "delete the check": a control that
// really is outside the viewport must still be named, at the same ratio, in
// logical numbers.
library;

import 'package:eden_ui_flutter/testing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '_fixtures/broken_surfaces.dart';

/// Pumps [child] with the LOGICAL viewport fixed at 1280x800 and the device
/// ratio set to [dpr].
///
/// The logical size is held constant on purpose: the surface under test is the
/// same surface at every ratio, so anything that changes with [dpr] is the
/// oracle's arithmetic and not the layout's.
///
/// A stock `ThemeData`, not `EdenTheme` — for the google_fonts reason spelled
/// out on `pumpSurface` in `expect_ui_sane_test.dart`.
Future<void> _pumpAt(
  WidgetTester tester,
  Widget child, {
  required double dpr,
}) async {
  tester.view.devicePixelRatio = dpr;
  tester.view.physicalSize = Size(1280 * dpr, 800 * dpr);
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    MaterialApp(
      theme: ThemeData.light(useMaterial3: true),
      home: Scaffold(
        body: Center(child: SizedBox(width: 1280, child: child)),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// A 48x48 labelled control whose LEFT EDGE is at logical x = 1240 inside a
/// 1280-wide surface, so 8 logical pixels of it hang off the right of the
/// view — at every ratio.
///
/// `Clip.none` is load-bearing: a clipping Stack would mark the node invisible
/// and the rule would have nothing to report.
Widget _controlOffTheRightEdge() {
  return Center(
    child: ColoredBox(
      color: const Color(0xFFFFFFFF),
      child: SizedBox(
        width: 1280,
        height: 200,
        child: Stack(
          clipBehavior: Clip.none,
          children: <Widget>[
            Positioned(
              left: 1240,
              top: 24,
              child: Semantics(
                container: true,
                identifier: 'fx-dpr-offscreen',
                label: 'Publish',
                button: true,
                onTap: () {},
                child: const SizedBox(
                  width: 48,
                  height: 48,
                  child: Center(
                    child: Text(
                      'P',
                      style: TextStyle(fontSize: 20, color: Color(0xFF111111)),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

void main() {
  testWidgets(
    'case 1: the clean surface passes at dpr 1 (the baseline the bug hid '
    'behind)',
    (WidgetTester tester) async {
      await _pumpAt(tester, cleanSurface(), dpr: 1.0);
      await expectUiSane(tester, inputModality: EdenInputModality.touch);
    },
  );

  for (final double dpr in <double>[2.0, 3.0]) {
    testWidgets(
      'case ${dpr == 2.0 ? 2 : 3}: the SAME clean surface passes at dpr $dpr',
      (WidgetTester tester) async {
        // RED (pre-fix): exit 1 —
        //   expectUiSane found 2 violation(s) on this surface:
        //     - control "fx-clean-b" is outside the viewport: its rect is
        //       Rect.fromLTRB(1360.0, 548.0, 1456.0, 644.0), the viewport is
        //       Rect.fromLTRB(0.0, 0.0, 1280.0, 800.0)
        //     ...
        // GREEN (post-fix): exit 0. Nothing about the surface changed.
        await _pumpAt(tester, cleanSurface(), dpr: dpr);
        await expectUiSane(tester, inputModality: EdenInputModality.touch);
      },
    );
  }

  testWidgets(
    'case 4: a control that really IS off the viewport is still named at '
    'dpr 2, in logical pixels',
    (WidgetTester tester) async {
      // The differential control for cases 2 and 3: deleting the rule, or
      // widening the viewport by the ratio, would turn those green too. This
      // one only passes while the rule still fires AND still reports the
      // numbers a reader's layout code is written in.
      await _pumpAt(tester, _controlOffTheRightEdge(), dpr: 2.0);
      await expectLater(
        () => expectUiSane(tester, inputModality: EdenInputModality.touch),
        throwsA(
          isA<TestFailure>().having(
            (TestFailure f) => f.message,
            'message',
            allOf(
              contains('control "fx-dpr-offscreen" is outside the viewport'),
              // Logical, not physical: 1240..1288 against 0..1280. The
              // physical spelling would read 2480..2576 against 2560 and
              // would ALSO "look like" a failure — which is exactly how the
              // unit bug stayed invisible. The top is 324 and not 24
              // because the 200-tall surface is centred in the 800-tall view.
              contains('Rect.fromLTRB(1240.0, 324.0, 1288.0, 372.0)'),
              contains('Rect.fromLTRB(0.0, 0.0, 1280.0, 800.0)'),
            ),
          ),
        ),
      );
    },
  );
}

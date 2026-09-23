// expectUiSane — the UI Oracle's one callable assertion.
//
// RED PROOF PROTOCOL (see 23-02-SUMMARY.md): every failing case below was first
// run as a BARE `await expectUiSane(tester)` against the broken fixture, so the
// real exit code and the real message were captured; then the fixture's `FIX:`
// comment was applied in place and the SAME case was watched going green; then
// the fixture was restored and the case wrapped in the matcher below. The
// matcher asserts on message SUBSTRINGS that name the offending widget — never
// merely that "something threw".
library;

import 'package:eden_ui_flutter/testing.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter/material.dart';

import '_fixtures/broken_surfaces.dart';

/// A deliberately font-free pump.
///
/// 23-01's `wrap()` is the harness everywhere else in this objective, but it
/// builds `EdenTheme.light()`/`EdenTheme.dark()`, and EdenTheme resolves its
/// type scale through google_fonts — which fires an HTTP fetch at
/// theme-construction time. `textContrastGuideline` captures the rendered
/// image through `tester.runAsync`, which is the first thing in a widget test
/// that actually RUNS that pending future; it fails, and the uncaught async
/// error completes the test with an error before any assertion is reached.
///
/// That is a real finding about adoption (recorded in 23-02-SUMMARY.md), not a
/// property of the surfaces under test — so the oracle's own suite pumps with
/// a stock `ThemeData` and keeps `wrap()`'s viewport discipline.
Future<void> pumpSurface(WidgetTester tester, Widget child) async {
  tester.view.devicePixelRatio = 1.0;
  tester.view.physicalSize = const Size(1280, 800);
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

void main() {
  testWidgets('case 1: passes on a clean story', (WidgetTester tester) async {
    await pumpSurface(tester, cleanSurface());
    await expectUiSane(tester);
  });

  testWidgets('case 2: RenderFlex overflow is named with its pixel count',
      (WidgetTester tester) async {
    await pumpSurface(tester, overflowingRow());
    // RED (broken fixture): exit 1 —
    //   RenderFlex overflow of 215 pixels on the right. Offending widget(s):
    //     Row <- SizedBox <- ColoredBox <- Center <- SizedBox <- Center <- ...
    // GREEN (Text wrapped in Expanded + ellipsis): exit 0.
    await expectLater(
      () => expectUiSane(tester),
      throwsA(
        isA<TestFailure>().having(
          (TestFailure f) => f.message,
          'message',
          allOf(
            contains('RenderFlex overflow of 215 pixels on the right'),
            contains('Row \u2190 SizedBox'),
          ),
        ),
      ),
    );
  });

  testWidgets('case 3: overlapping identified controls are both named',
      (WidgetTester tester) async {
    await pumpSurface(tester, overlappingControls());
    // RED (broken fixture): exit 1 —
    //   controls "fx-overlap-a" and "fx-overlap-b" overlap: ... they share
    //   Rect.fromLTRB(564.0, 350.0, 588.0, 398.0).
    // GREEN (fx-overlap-b moved to left: 96): exit 0.
    await expectLater(
      () => expectUiSane(tester),
      throwsA(
        isA<TestFailure>().having(
          (TestFailure f) => f.message,
          'message',
          allOf(
            contains('"fx-overlap-a"'),
            contains('"fx-overlap-b"'),
            contains('overlap'),
          ),
        ),
      ),
    );
  });

  testWidgets('case 4: a control declaring two tap actions is named',
      (WidgetTester tester) async {
    await pumpSurface(tester, doubleTapAction());
    // RED (broken fixture): exit 1 —
    //   control "fx-double-tap" declares 2 tap actions (its own semantics node
    //   plus 1 unidentified descendant node(s) that also advertise
    //   SemanticsAction.tap).
    // GREEN (ElevatedButton wrapped in ExcludeSemantics): exit 0.
    await expectLater(
      () => expectUiSane(tester),
      throwsA(
        isA<TestFailure>().having(
          (TestFailure f) => f.message,
          'message',
          allOf(
            contains('"fx-double-tap"'),
            contains('declares 2 tap actions'),
          ),
        ),
      ),
    );
  });

  testWidgets('case 5: a sub-24px tap target is named',
      (WidgetTester tester) async {
    await pumpSurface(tester, tinyTapTarget());
    // RED (broken fixture, 20x20): exit 1 —
    //   Tappable objects should be at least Size(48.0, 48.0): ...
    //   SemanticsNode#4(..., identifier: "fx-tiny-tap", label: "Dismiss
    //   banner"): expected tap target size of at least Size(48.0, 48.0), but
    //   found Size(20.0, 20.0)
    // (and the same again for the 44.0 iOS floor).
    // GREEN (SizedBox grown to 48x48): exit 0.
    await expectLater(
      () => expectUiSane(tester),
      throwsA(
        isA<TestFailure>().having(
          (TestFailure f) => f.message,
          'message',
          allOf(
            contains('"fx-tiny-tap"'),
            contains('Size(48.0, 48.0)'),
            contains('found Size(20.0, 20.0)'),
          ),
        ),
      ),
    );
  });

  testWidgets('case 6: dark-on-dark text is named',
      (WidgetTester tester) async {
    await pumpSurface(tester, darkOnDark());
    // RED (broken fixture, #2A2A2A on #1E1E1E): exit 1 —
    //   Text contrast should follow WCAG guidelines: ...
    //   SemanticsNode#4(..., label: "Storage almost full"): Expected contrast
    //   ratio of at least 4.5 but found 1.16 for a font size of 16.0.
    // GREEN (text lightened to #F5F5F5): exit 0.
    await expectLater(
      () => expectUiSane(tester),
      throwsA(
        isA<TestFailure>().having(
          (TestFailure f) => f.message,
          'message',
          allOf(
            contains('Storage almost full'),
            contains('Expected contrast ratio of at least 4.5'),
            contains('but found 1.16'),
          ),
        ),
      ),
    );
  });
}

// expectUiSane — the UI Oracle's one callable assertion.
//
// RED PROOF PROTOCOL (see 23-02-SUMMARY.md): every failing case below was first
// run as a BARE `await expectUiSane(tester)` against the broken fixture, so the
// real exit code and the real message were captured; then the fixture's `FIX:`
// comment was applied in place and the SAME case was watched going green; then
// the fixture was restored and the case wrapped in the matcher below. The
// matcher asserts on message SUBSTRINGS that name the offending widget — never
// merely that "something threw".
//
// MODALITY. Every case names its `inputModality` rather than leaning on the
// default. Cases 1-6 declare `touch`: their fixtures are built at 48x48 — the
// touch floor — so touch is the honest declaration AND the one that keeps
// case 5's 48/44 message assertions meaningful. Cases 7-9 are the modality
// rule itself.
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
    await expectUiSane(tester, inputModality: EdenInputModality.touch);
  });

  testWidgets('case 2: RenderFlex overflow is named with its pixel count',
      (WidgetTester tester) async {
    await pumpSurface(tester, overflowingRow());
    // RED (broken fixture): exit 1 —
    //   RenderFlex overflow of 215 pixels on the right. Offending widget(s):
    //     Row <- SizedBox <- ColoredBox <- Center <- SizedBox <- Center <- ...
    // GREEN (Text wrapped in Expanded + ellipsis): exit 0.
    await expectLater(
      () => expectUiSane(tester, inputModality: EdenInputModality.touch),
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
      () => expectUiSane(tester, inputModality: EdenInputModality.touch),
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
      () => expectUiSane(tester, inputModality: EdenInputModality.touch),
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
      () => expectUiSane(tester, inputModality: EdenInputModality.touch),
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
      () => expectUiSane(tester, inputModality: EdenInputModality.touch),
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

  // ---------------------------------------------------------------------
  // Input modality — the tap-target floor depends on what the surface is
  // driven WITH. See EdenInputModality in lib/testing/expect_ui_sane.dart.
  // ---------------------------------------------------------------------

  testWidgets('case 7: the pointer path still rejects a 20x20 target',
      (WidgetTester tester) async {
    await pumpSurface(tester, tinyTapTarget());
    // The pointer floor is a REAL floor, not an absent one. 20x20 is under
    // WCAG 2.5.8's 24x24 minimum, so relaxing 48/44 to 24 must not let this
    // through.
    // RED (before EdenInputModality existed): compile error — no such named
    // parameter `inputModality`.
    // RED (parameter present, pointer path wired to the 48/44 guidelines):
    // the message names Size(48.0, 48.0) and this expectation fails.
    await expectLater(
      () => expectUiSane(tester, inputModality: EdenInputModality.pointer),
      throwsA(
        isA<TestFailure>().having(
          (TestFailure f) => f.message,
          'message',
          allOf(
            contains('"fx-tiny-tap"'),
            contains('Size(24.0, 24.0)'),
            contains('found Size(20.0, 20.0)'),
          ),
        ),
      ),
    );
  });

  testWidgets('case 8: the pointer path accepts a 40px rail row',
      (WidgetTester tester) async {
    await pumpSurface(tester, railRow());
    // The ruling itself: 40px is correct on a pointer surface. 24x24 is WCAG
    // 2.5.8 AA; 44x44 (2.5.5) is AAA and 48dp is Material TOUCH guidance.
    // Asserting a touch floor here would not be a stricter standard, it would
    // be the wrong one.
    await expectUiSane(tester, inputModality: EdenInputModality.pointer);
  });

  testWidgets('case 9: the touch path still rejects the same 40px row',
      (WidgetTester tester) async {
    await pumpSurface(tester, railRow());
    // The same geometry, declared as a touch surface, is still a defect — the
    // modality parameter selects the standard, it does not waive one. Both
    // floors are named so a fixture tuned to 46px could not slip between them.
    await expectLater(
      () => expectUiSane(tester, inputModality: EdenInputModality.touch),
      throwsA(
        isA<TestFailure>().having(
          (TestFailure f) => f.message,
          'message',
          allOf(
            contains('"fx-rail-row"'),
            contains('Size(48.0, 48.0)'),
            contains('Size(44.0, 44.0)'),
            contains('found Size(235.0, 40.0)'),
          ),
        ),
      ),
    );
  });

  // ---------------------------------------------------------------------
  // Liveness — a control that ANNOUNCES an affordance must have one, and it
  // must work. The tap-action rule used to be an upper bound only (`> 1`),
  // so a surface whose controls were all dead reported FEWER violations than
  // a working one: the oracle went green on dead UI. See the "inert" section
  // of expect_ui_sane.dart.
  // ---------------------------------------------------------------------

  testWidgets('case 10: a button with NO tap action is named as inert',
      (WidgetTester tester) async {
    await pumpSurface(tester, inertButton());
    // RED (broken fixture): exit 1 —
    //   control "fx-inert-button" announces itself as a button but has no tap
    //   action - it is inert.
    // GREEN (`onTap: () {}` added to the Semantics): exit 0.
    await expectLater(
      () => expectUiSane(tester, inputModality: EdenInputModality.touch),
      throwsA(
        isA<TestFailure>().having(
          (TestFailure f) => f.message,
          'message',
          allOf(
            contains('"fx-inert-button"'),
            contains('announces itself as a button but has no tap action'),
            contains('it is inert'),
          ),
        ),
      ),
    );
  });

  testWidgets(
      'case 11: a button whose one tap action no pointer can reach is named',
      (WidgetTester tester) async {
    await pumpSurface(tester, unreachableButton());
    // THE FALSE-GREEN CASE. The route COUNT is a healthy 1 here — IgnorePointer
    // blocks the inner GestureDetector's implicit route — so neither the `> 1`
    // arm nor the zero arm fires. Only the reachability arm does.
    //
    // RED (broken fixture): exit 1 —
    //   control "fx-unreachable-button" announces itself as a button and
    //   declares a tap action, but a pointer dropped in the middle of the rect
    //   it publishes never reaches it - it is inert to a real tap.
    // GREEN (IgnorePointer -> ExcludeSemantics): exit 0.
    await expectLater(
      () => expectUiSane(tester, inputModality: EdenInputModality.touch),
      throwsA(
        isA<TestFailure>().having(
          (TestFailure f) => f.message,
          'message',
          allOf(
            contains('"fx-unreachable-button"'),
            contains('never reaches it'),
            contains('inert to a real tap'),
          ),
        ),
      ),
    );
  });

  testWidgets('case 12: a link with NO tap action is named as inert',
      (WidgetTester tester) async {
    await pumpSurface(tester, inertLink());
    // The rule keys on the AFFORDANCE a node advertises, not on the word
    // "button". `link: true` is unused in lib/src today; the case exists so
    // the second arm of the predicate is executed rather than asserted.
    //
    // RED (broken fixture): exit 1 —
    //   control "fx-inert-link" announces itself as a link but has no tap
    //   action - it is inert.
    // GREEN (`onTap: () {}` added): exit 0.
    await expectLater(
      () => expectUiSane(tester, inputModality: EdenInputModality.touch),
      throwsA(
        isA<TestFailure>().having(
          (TestFailure f) => f.message,
          'message',
          allOf(
            contains('"fx-inert-link"'),
            contains('announces itself as a link but has no tap action'),
          ),
        ),
      ),
    );
  });

  testWidgets(
      'case 13: identified NON-interactive controls stay green (the exemption)',
      (WidgetTester tester) async {
    // The differential control for the predicate. A caption band carries an
    // identifier and no affordance flag; the top-bar search carries
    // `textField: true`, not `button: true`. Neither has — or should have — a
    // tap action. Widen the predicate from `button || link` to "any identified
    // node" and this case goes red, which is how the scope is pinned.
    await pumpSurface(tester, nonInteractiveIdentifiedControls());
    await expectUiSane(tester, inputModality: EdenInputModality.touch);
  });
}

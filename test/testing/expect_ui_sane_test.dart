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

import '../../test_support/ui_oracle/wrap.dart';
import '_fixtures/broken_surfaces.dart';

void main() {
  testWidgets('case 1: passes on a clean story', (WidgetTester tester) async {
    await wrap(tester, cleanSurface());
    await expectUiSane(tester);
  });

  testWidgets('case 2: RenderFlex overflow is named with its pixel count',
      (WidgetTester tester) async {
    await wrap(tester, overflowingRow());
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
    await wrap(tester, overlappingControls());
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
    await wrap(tester, doubleTapAction());
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
}

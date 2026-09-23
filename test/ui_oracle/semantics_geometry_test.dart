// Tests for the UI Oracle semantics-geometry helper.
//
// IMPORT CONVENTION: `test_support/` is a top-level directory, not part of the
// package's `lib/`, so there is no `package:eden_ui_flutter/...` URI for it.
// These tests reach the helpers by RELATIVE import.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../test_support/ui_oracle/_fixtures/geometry_fixtures.dart';
import '../../test_support/ui_oracle/semantics_geometry.dart';
import '../../test_support/ui_oracle/wrap.dart';

void main() {
  group('SemanticsGeometry', () {
    testWidgets(
      'case 5: globalRect of a 40x40 child in a 360-wide row is 40 wide',
      (WidgetTester tester) async {
        await wrap(tester, narrowChildInWideRow, width: 360);

        final Rect rect = globalRectOf(tester, kFxNarrowChild);

        // 40, NOT 360. A walk that stops at the nearest container ancestor
        // answers 360 (the row) and is wrong in exactly the way that makes
        // every downstream geometry assertion a green test proving nothing.
        expect(rect.width, 40);
        expect(rect.height, 40);
      },
    );

    testWidgets('case 6: two sibling controls report disjoint rects', (
      WidgetTester tester,
    ) async {
      await wrap(tester, twoSiblingControls, width: 360);

      final Rect a = globalRectOf(tester, kFxSiblingA);
      final Rect b = globalRectOf(tester, kFxSiblingB);

      // The caller never writes matrix code: the helper answers directly.
      expect(rectsOverlap(a, b), isFalse);
      expect(rectsOverlap(b, a), isFalse);
      expect(a.width, 40);
      expect(b.width, 40);
    });

    // ------------------------------------------------------------------
    // CASE 7 — PINNED BUG. DO NOT "FIX" THIS TEST OR ITS FIXTURE.
    //
    // Memory note: `flutter-web-semantics-node-is-the-click-target`. On web the
    // DOM semantics node receives the click, not the widget. A nested
    // `Semantics(identifier: ...)` declared WITHOUT `container: true` does not
    // form its own semantics boundary: its annotations are merged into the
    // enclosing node, so the accessibility tree publishes the PARENT's 200x200
    // rect for that control and the inner identifier is not published at all.
    //
    // This test asserts the BUGGY values on purpose. It is the tripwire that
    // tells 23-02 (`expectUiSane`) and 23-07 (the probe bridge's `tree()`) why
    // they must REQUIRE `container: true`: without it a geometry assertion is
    // silently made against the wrong box, and a lookup by the inner
    // identifier throws instead of returning a 40x40 rect.
    //
    // Observed on Flutter 3.41.9 (local) — see the SUMMARY's deviation note:
    // the plan predicted the inner identifier would be REPORTED with the
    // parent's rect; what actually happens is that the inner identifier is
    // DROPPED and only the parent's node exists, carrying the parent's rect.
    // Same defect, one step more severe.
    // ------------------------------------------------------------------
    testWidgets(
      'case 7 (pinned bug): nested Semantics without container:true is '
      'swallowed by the parent node, which carries the parent rect',
      (WidgetTester tester) async {
        await wrap(tester, nestedSemanticsWithoutContainer, width: 360);

        final List<SemanticsGeometryNode> nodes = identifiedNodes(tester);
        final List<String?> identifiers = nodes
            .map((SemanticsGeometryNode n) => n.identifier)
            .toList();

        // BUGGY, ON PURPOSE: the inner 40x40 control publishes no node of its
        // own. Only the 200x200 parent is in the accessibility tree.
        expect(identifiers, <String>[kFxParent]);
        expect(identifiers, isNot(contains(kFxNestedNoContainer)));

        // BUGGY, ON PURPOSE: the rect a click on the nested control lands in
        // is the PARENT's 200x200 box, not the control's own 40x40.
        final Rect parentRect = globalRectOf(tester, kFxParent);
        expect(parentRect.width, 200);
        expect(parentRect.height, 200);

        // And the lookup a caller would naturally write throws.
        expect(
          () => globalRectOf(tester, kFxNestedNoContainer),
          throwsStateError,
        );
      },
    );
  });
}

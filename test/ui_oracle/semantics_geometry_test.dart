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
    // CASE 7 — AN SDK BEHAVIOUR CHANGE, MEASURED AT BOTH ENDS.
    //
    // This case used to pin a BUG. On Flutter 3.41.9 a nested
    // `Semantics(identifier: ...)` declared WITHOUT `container: true` formed no
    // semantics boundary of its own: its annotations merged UPWARD into the
    // enclosing node, the inner identifier was never published, and the only
    // node in the tree was the 200x200 parent — carrying the inner control's
    // `button: true` flag on the parent's box.
    //
    // On the SDK this repo's CI pins, 3.47.4, that is no longer true. The
    // nested annotation publishes its OWN node, as a child of the parent's,
    // with the control's own 40x40 rect, and the button flag stays on it. The
    // parent keeps its identifier and its 200x200 rect and is no longer a
    // button.
    //
    // MEASURED, not inferred, on both SDKs with the same fixture:
    //
    //   Flutter 3.41.9 (workstation)   #4 "fx-parent" 200x200 isButton=true
    //                                     (no node for the inner control)
    //   Flutter 3.47.4 (CI run         #4 "fx-parent" 200x200 isButton=false
    //   35898905034, Test job)           #5 "fx-nested-no-container" 40x40
    //                                        isButton=true, child of #4
    //
    // The exact stable release that changed it was NOT narrowed: all this
    // asserts is that 3.41.9 behaved one way and 3.47.4 behaves the other.
    //
    // WHAT THIS MEANS FOR CALLERS. Omitting `container: true` no longer makes
    // a control unaddressable on the pinned SDK — `globalRectOf` returns its
    // own 40x40 box instead of throwing. It is still the house rule to pass
    // it, for two reasons that survive the fix: the repo's declared SDK floor
    // (pubspec `flutter: ">=3.27.0"`) still includes versions with the old
    // merging behaviour, and `container: true` states the boundary explicitly
    // instead of depending on which SDK a consumer resolves. `expectUiSane`
    // and the probe bridge keep REQUIRING it; what has changed is the penalty
    // for omitting it, not the rule.
    //
    // NOTE FOR WORKSTATIONS. This case is written against the SDK CI pins.
    // A checkout running the older 3.41.9 fails it, and that is deliberate —
    // memory note `local-flutter-is-months-behind-ci`. The gate is CI.
    //
    // Memory note: `flutter-web-semantics-node-is-the-click-target` — on web
    // the DOM semantics node receives the click, not the widget. That is why
    // this case asserts rects and nesting, not just presence.
    // ------------------------------------------------------------------
    testWidgets(
      'case 7 (SDK behaviour change): on 3.47.4 a nested Semantics without '
      'container:true publishes its own node with its own 40x40 rect',
      (WidgetTester tester) async {
        await wrap(tester, nestedSemanticsWithoutContainer, width: 360);

        final List<SemanticsGeometryNode> nodes = identifiedNodes(tester);
        final List<String?> identifiers = nodes
            .map((SemanticsGeometryNode n) => n.identifier)
            .toList();

        // BOTH are published now. `identifiedNodes` sorts by (top, left,
        // identifier), so the 200x200 parent (top 300) precedes the nested
        // 40x40 control (top 380) — this is not visit order.
        expect(identifiers, <String>[kFxParent, kFxNestedNoContainer]);

        // The parent is unchanged: same identifier, same 200x200 box.
        final Rect parentRect = globalRectOf(tester, kFxParent);
        expect(parentRect.width, 200);
        expect(parentRect.height, 200);

        // The lookup that THREW on 3.41.9 now answers, and it answers with the
        // control's OWN box, not the parent's. This is the whole behaviour
        // change in one assertion.
        final Rect nestedRect = globalRectOf(tester, kFxNestedNoContainer);
        expect(nestedRect.width, 40);
        expect(nestedRect.height, 40);

        // And it is nested INSIDE the parent's box rather than replacing it:
        // the accessibility tree now has two stacked rects over this control.
        expect(parentRect.contains(nestedRect.topLeft), isTrue);
        expect(parentRect.contains(nestedRect.bottomRight - const Offset(1, 1)),
            isTrue);
        expect(rectsOverlap(parentRect, nestedRect), isTrue);

        // A click at the inner control's centre is inside both rects; the
        // smaller, innermost published node is the one a browser's DOM
        // semantics node resolves it to, and on 3.47.4 that node is the
        // control's own 40x40 — on 3.41.9 the only candidate was the parent's
        // 200x200.
        final Offset centre = nestedRect.center;
        expect(nestedRect.contains(centre), isTrue);
        expect(parentRect.contains(centre), isTrue);
        expect(nestedRect.width * nestedRect.height,
            lessThan(parentRect.width * parentRect.height));
      },
    );
  });
}

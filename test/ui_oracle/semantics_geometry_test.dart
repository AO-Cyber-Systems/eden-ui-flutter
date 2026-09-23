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

    testWidgets('case 7 (naive expectation): nested Semantics reports 40x40', (
      WidgetTester tester,
    ) async {
      await wrap(tester, nestedSemanticsWithoutContainer, width: 360);

      final Rect nested = globalRectOf(tester, kFxNestedNoContainer);

      expect(nested.width, 40);
      expect(nested.height, 40);
    });
  });
}

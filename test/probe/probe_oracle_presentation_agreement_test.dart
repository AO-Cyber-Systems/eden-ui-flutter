// The probe and the oracle must answer the SAME question about the SAME tree.
//
// WHY THIS FILE EXISTS. `isPresentedToUser` — skip nodes that are merged into
// their parent, invisible, or `isHidden` — was added to the UI Oracle's
// `identifiedNodes` walk and NOT to `EdenProbeApi`'s. Nothing made that
// divergence visible, and it is the kind that reads green from both sides:
//
//   * a `ListView` publishes a few rows past its viewport, flagged `isHidden`,
//     carrying their identifiers and their tap routes. The oracle skipped
//     them. The probe handed a driver those rows as clickable targets, at
//     rects the user cannot see and a real click cannot reach.
//   * a node flagged `isMergedIntoParent` is not a control of its own; the
//     merge also copies its identifier UP. The probe reported both, so one
//     control came back TWICE under one identifier with two different rects,
//     and a driver picking one of them was picking at random.
//
// A driver that clicks what the probe reports, checked by an oracle that
// asserts over what the oracle reports, is only meaningful while those two
// lists are the same list. They now share ONE predicate
// (`lib/src/a11y/semantics_presentation.dart`); this file is what holds them
// to it over real trees rather than over the fact that they both call it.
library;

import 'package:eden_ui_flutter/src/probe/probe_api.dart';
// The direct import `test/ui_oracle/nav_row_tap_routes_test.dart` already
// uses, rather than `package:eden_ui_flutter/testing.dart`:
// `rootSemanticsNodeOf` and `isPresentedToUser` are deliberately NOT in that
// entry point's show list, and widening a consumer-facing API for one in-repo
// test would be the wrong trade.
import 'package:eden_ui_flutter/testing/semantics_geometry.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../test_support/ui_oracle/wrap.dart';
import '../testing/_fixtures/broken_surfaces.dart' show scrolledListRows;
import '_fixtures/probe_surfaces.dart';

/// `(identifier, rect)` for every node the PROBE reports, in probe order.
List<(String, Rect)> _probeNodes() {
  final Map<String, Object?> tree = EdenProbeApi.tree();
  return <(String, Rect)>[
    for (final Object? n in tree['nodes']! as List<Object?>)
      (
        (n! as Map<String, Object?>)['identifier']! as String,
        () {
          final Map<String, Object?> r =
              (n as Map<String, Object?>)['rect']! as Map<String, Object?>;
          return Rect.fromLTWH(
            r['x']! as double,
            r['y']! as double,
            r['w']! as double,
            r['h']! as double,
          );
        }(),
      ),
  ];
}

/// `(identifier, rect)` for every node the ORACLE reports, in oracle order,
/// converted to the LOGICAL pixels the probe answers in.
///
/// THE TWO UNITS ARE A DELIBERATE DIFFERENCE, NOT A SECOND BUG. The oracle's
/// `globalRect` composes the root semantics transform and stops there, so it
/// is PHYSICAL — `_viewportViolations` and `_pointerReaches` both divide the
/// ratio out again where they need to. The probe divides it out at the source
/// because every OTHER rect it hands a driver is a render box's logical rect
/// and a CDP driver clicks in CSS pixels. Normalising here is what lets this
/// file compare the two lists on the only thing it is about: WHICH nodes are
/// in them.
List<(String, Rect)> _oracleNodes(WidgetTester tester) {
  final double dpr = tester.view.devicePixelRatio;
  return <(String, Rect)>[
    for (final SemanticsGeometryNode n in identifiedNodes(tester))
      (
        n.identifier ?? '',
        Rect.fromLTRB(
          n.globalRect.left / dpr,
          n.globalRect.top / dpr,
          n.globalRect.right / dpr,
          n.globalRect.bottom / dpr,
        ),
      ),
  ];
}

/// Two identified controls that `MergeSemantics` folds into one node.
///
/// MEASURED SHAPE (Flutter 3.41.9, and what the assertions below pin):
///
///   node 4  identifier "fx-merged-a"  merged=false  rect 300x800
///     node 5  identifier "fx-merged-a"  merged=TRUE   rect 300x30
///     node 6  identifier "fx-merged-b"  merged=TRUE   rect 300x30
///
/// A `SemanticsConfiguration` absorbs an identifier when it has none of its
/// own, so the FIRST child's identifier is copied onto the merged parent and
/// the same identifier is published on two nodes with two different rects.
/// Exactly one of the two is the control.
///
/// `container: true` on the children is load-bearing: without it the merge
/// leaves no separate child nodes at all and the shape does not occur.
Widget mergedIdentifiedControl() {
  return Center(
    child: MergeSemantics(
      child: SizedBox(
        width: 300,
        child: Column(
          children: <Widget>[
            Semantics(
              identifier: 'fx-merged-a',
              container: true,
              label: 'A',
              child: const SizedBox(width: 300, height: 30),
            ),
            Semantics(
              identifier: 'fx-merged-b',
              container: true,
              label: 'B',
              child: const SizedBox(width: 300, height: 30),
            ),
          ],
        ),
      ),
    ),
  );
}

Future<void> _agree(WidgetTester tester, String what) async {
  final SemanticsHandle handle = tester.ensureSemantics();
  final List<(String, Rect)> probe = _probeNodes();
  final List<(String, Rect)> oracle = _oracleNodes(tester);
  handle.dispose();

  expect(
    probe,
    isNotEmpty,
    reason: 'neither walk found a node on $what, so this case would agree on '
        'nothing',
  );
  expect(
    probe,
    oracle,
    reason: 'the probe and the oracle disagree about which nodes $what '
        'presents. A driver clicks the probe\'s list and the oracle asserts '
        'over its own; while they differ, a green oracle says nothing about '
        'what the driver can reach.',
  );
}

void main() {
  testWidgets('case 1: a plain surface — the differential control',
      (WidgetTester tester) async {
    // If the two walks disagreed HERE they would disagree everywhere, and
    // cases 2 and 3 would be measuring the harness rather than the exclusion.
    await tester.pumpWidget(
      MaterialApp(home: Scaffold(body: probeSemanticsSurface())),
    );
    await _agree(tester, 'a surface with nothing hidden or merged');
  });

  testWidgets("case 2: a scrolled ListView's off-screen rows",
      (WidgetTester tester) async {
    // 30 correct rows in a 300px viewport. Six fit; Flutter builds a handful
    // more inside the cache extent and publishes them `isHidden` with their
    // identifiers and their tap routes intact.
    //
    // RED (before the probe applied isPresentedToUser): the probe returns 11
    // rows and the oracle 6 — five rows a driver was invited to click.
    await wrap(tester, scrolledListRows());
    await _agree(tester, "a scrolled ListView's cache-extent rows");
  });

  testWidgets('case 3: a control merged into its parent',
      (WidgetTester tester) async {
    // RED (before the probe applied isPresentedToUser): ONE identifier comes
    // back on TWO nodes with two different rects.
    await wrap(tester, mergedIdentifiedControl());
    await _agree(tester, 'a MergeSemantics subtree');
  });

  testWidgets(
      'case 4: the merged case really does publish the identifier twice',
      (WidgetTester tester) async {
    // THE PREMISE OF CASE 3, asserted rather than assumed. If the merge ever
    // stops copying the identifier up, case 3 becomes a case about nothing
    // and would keep passing — the two walks would agree because there was
    // never a second node to disagree about.
    await wrap(tester, mergedIdentifiedControl());
    final SemanticsHandle handle = tester.ensureSemantics();
    final SemanticsNode root = rootSemanticsNodeOf(tester);

    final List<SemanticsNode> carrying = <SemanticsNode>[];
    void visit(SemanticsNode node) {
      if (node.getSemanticsData().identifier == 'fx-merged-a') {
        carrying.add(node);
      }
      node.visitChildren((SemanticsNode child) {
        visit(child);
        return true;
      });
    }

    visit(root);
    handle.dispose();

    // A LOWER BOUND, not an equality. How many nodes a merge publishes is
    // SDK-dependent — `semantics_geometry_test` case 7 is this repo's other
    // record of 3.47.x publishing a node 3.41.9 does not — and a newer SDK
    // publishing MORE of them does not weaken this case. FEWER would: one
    // node means there is nothing to exclude and case 3 is about nothing, so
    // that fails here and says so rather than passing quietly.
    expect(
      carrying.length,
      greaterThanOrEqualTo(2),
      reason: 'the fixture no longer publishes one identifier on more than '
          'one node, so case 3 has nothing to exclude',
    );
    expect(
      carrying.where(isPresentedToUser).length,
      1,
      reason: 'exactly one of them is the control; the rest are merged into '
          'it',
    );
  });
}

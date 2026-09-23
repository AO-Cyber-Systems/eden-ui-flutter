// TEMPORARY DIAGNOSTIC — delete once the 3.47.4 topology is recorded.
//
// This machine runs Flutter 3.41.9; CI pins 3.47.4. Case 7 of
// `semantics_geometry_test.dart` pins a 3.41-era behaviour that 3.47.4 no
// longer exhibits, so the real topology has to be MEASURED on the pinned SDK,
// not inferred. This file prints it into the CI log between greppable markers.
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../test_support/ui_oracle/_fixtures/geometry_fixtures.dart';
import '../../test_support/ui_oracle/semantics_geometry.dart';
import '../../test_support/ui_oracle/wrap.dart';

void main() {
  testWidgets('DIAG nestedSemanticsWithoutContainer topology', (
    WidgetTester tester,
  ) async {
    await wrap(tester, nestedSemanticsWithoutContainer, width: 360);

    final SemanticsHandle handle = tester.ensureSemantics();
    final SemanticsNode root = rootSemanticsNodeOf(tester);

    // ignore: avoid_print
    print('===DIAG-TREE-BEGIN===');
    _dump(root, 0, Matrix4.identity());
    // ignore: avoid_print
    print('===DIAG-TREE-END===');
    handle.dispose();

    // ignore: avoid_print
    print('===DIAG-NODES-BEGIN===');
    for (final SemanticsGeometryNode n in identifiedNodes(tester)) {
      // ignore: avoid_print
      print('NODE $n');
    }
    // ignore: avoid_print
    print('===DIAG-NODES-END===');

    // Where does a click at the inner control's centre land? On web the
    // semantics node receives the click, so report BOTH: the render-object hit
    // path, and every published identified rect that contains the point.
    final Rect inner = tester.getRect(
      find.byWidgetPredicate(
        (Widget w) => w is SizedBox && w.width == 40 && w.height == 40,
      ),
    );
    final Offset centre = inner.center;
    // ignore: avoid_print
    print('===DIAG-HIT-BEGIN===');
    // ignore: avoid_print
    print('inner widget rect: $inner  centre: $centre');
    for (final SemanticsGeometryNode n in identifiedNodes(tester)) {
      // ignore: avoid_print
      print(
        'contains(${n.identifier}) = ${n.globalRect.contains(centre)} '
        'rect=${n.globalRect} area=${n.globalRect.width * n.globalRect.height} '
        'actions=${n.actions}',
      );
    }
    final HitTestResult result = tester.hitTestOnBinding(centre);
    for (final HitTestEntry<HitTestTarget> entry in result.path) {
      // ignore: avoid_print
      print('hit-path: ${entry.target.runtimeType}');
    }
    // ignore: avoid_print
    print('===DIAG-HIT-END===');

    // Does a lookup by the inner identifier now succeed?
    String lookup;
    try {
      lookup = 'OK ${globalRectOf(tester, kFxNestedNoContainer)}';
    } on StateError catch (e) {
      lookup = 'THREW ${e.message}';
    }
    // ignore: avoid_print
    print('===DIAG-LOOKUP=== $lookup');
  });

  // The _navRow shape: an identified Semantics(onTap:) over a renderer that is
  // a bare GestureDetector(onTap:). Printed BOTH ways — with and without the
  // ExcludeSemantics that d2af9d1 added — so "is the exclusion still doing
  // something on 3.47.4?" is answered by measurement, not by reading the SDK.
  testWidgets('DIAG navRow shape with and without ExcludeSemantics', (
    WidgetTester tester,
  ) async {
    for (final bool exclude in <bool>[false, true]) {
      final Widget renderer = GestureDetector(
        onTap: () {},
        child: const SizedBox(width: 80, height: 48),
      );
      await wrap(
        tester,
        Center(
          child: Semantics(
            identifier: 'fx-navrow',
            button: true,
            label: 'Home',
            onTap: () {},
            child: exclude ? ExcludeSemantics(child: renderer) : renderer,
          ),
        ),
        width: 360,
      );
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpAndSettle();
      final SemanticsNode root = rootSemanticsNodeOf(tester);
      // ignore: avoid_print
      print('===DIAG-NAVROW exclude=$exclude BEGIN===');
      _dump(root, 0, Matrix4.identity());
      // ignore: avoid_print
      print('===DIAG-NAVROW exclude=$exclude END===');
      handle.dispose();
    }
  });

  // The OTHER shape the house rule is about: an identifier annotation whose
  // child ALREADY publishes semantics of its own (a real button). Does the
  // identifier get its own node, or does it land on the child's node?
  testWidgets('DIAG annotation over a child that already publishes', (
    WidgetTester tester,
  ) async {
    await wrap(
      tester,
      Center(
        child: Semantics(
          identifier: 'fx-over-published',
          child: ElevatedButton(
            onPressed: () {},
            child: const Text('Go'),
          ),
        ),
      ),
      width: 360,
    );
    final SemanticsHandle handle = tester.ensureSemantics();
    await tester.pumpAndSettle();
    // ignore: avoid_print
    print('===DIAG-OVERPUBLISHED BEGIN===');
    _dump(rootSemanticsNodeOf(tester), 0, Matrix4.identity());
    // ignore: avoid_print
    print('===DIAG-OVERPUBLISHED END===');
    handle.dispose();
  });
}

void _dump(SemanticsNode node, int depth, Matrix4 inherited) {
  final SemanticsData data = node.getSemanticsData();
  Matrix4 composed = inherited;
  final Matrix4? own = node.transform;
  if (own != null) {
    composed = composed.multiplied(own);
  }
  final Rect global = MatrixUtils.transformRect(composed, node.rect);
  final List<String> actions = <String>[
    for (final SemanticsAction a in SemanticsAction.values)
      if (data.hasAction(a)) a.name,
  ];
  // ignore: avoid_print
  print(
    '${'  ' * depth}#${node.id} identifier="${data.identifier}" '
    'label="${data.label}" rect=${node.rect} global=$global '
    'merge=${node.mergeAllDescendantsIntoThisNode} '
    'isButton=${data.hasFlag(SemanticsFlag.isButton)} '
    'actions=$actions',
  );
  node.visitChildren((SemanticsNode child) {
    _dump(child, depth + 1, composed);
    return true;
  });
}

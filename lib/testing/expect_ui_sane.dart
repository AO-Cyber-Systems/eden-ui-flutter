/// The UI Oracle's single callable assertion.
///
/// TEST-ONLY. This library imports `package:flutter_test` and must be imported
/// from a consumer's `test/` directory only, via the public entry point:
///
/// ```dart
/// import 'package:eden_ui_flutter/testing.dart';
/// ```
///
/// Importing it from production code pulls `flutter_test` into the release
/// graph and breaks the build. Nothing in `lib/eden_ui.dart` or `lib/src/`
/// references it, and a grep gate in TRD 23-02 keeps it that way.
library;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
// `flutter_test` is a dev_dependency and is imported here DELIBERATELY — see
// the note in semantics_geometry.dart.
// ignore: depend_on_referenced_packages
import 'package:flutter_test/flutter_test.dart';

import 'semantics_geometry.dart';

/// Asserts that the surface currently pumped into [tester] is not visibly
/// broken, and fails NAMING the offending widget when it is.
///
/// Add one line after the final pump of an existing screen test:
///
/// ```dart
/// await tester.pumpWidget(const MyScreen());
/// await tester.pumpAndSettle();
/// await expectUiSane(tester);
/// ```
///
/// Checks, in order:
///
/// 1. **No escaped exception.** A `RenderFlex overflowed by N pixels` is
///    reported through `FlutterError` during layout/paint, not thrown at the
///    call site, so a screen test can be green while the screen is visibly
///    broken. `tester.takeException()` is called EXACTLY ONCE here; a second
///    call anywhere returns null and the overflow disappears.
/// 2. **Viewport containment.** Every identified control's semantics rect lies
///    inside the view.
/// 3. **Disjointness.** No two identified controls' rects intersect. On web the
///    semantics node — not the widget — receives the click, so an overlap means
///    one control silently eats the other's taps. [allowOverlap] lists the
///    identifiers permitted to intersect (a deliberate overlay, a badge sitting
///    on its host); it is the escape hatch that makes adoption across 600+
///    consumer screens possible without editing the screens.
/// 4. **One tap action per control.** A control that declares `tap` on its own
///    node AND again on a non-identified descendant fires twice.
///
/// Violations are AGGREGATED: one run lists everything wrong with the surface,
/// so a consumer fixing a screen does not play whack-a-mole.
///
/// A surface with no identified controls is not a failure — it has nothing to
/// check. `expectUiSane` must be adoptable without a triage backlog.
///
/// Note on `container: true`: a nested `Semantics` WITHOUT `container: true` is
/// not published as its own node at all (Flutter 3.41.9; pinned by TRD 23-01
/// case 7). Its identifier vanishes and the enclosing node's identifier wins,
/// so this oracle cannot see it. Give every control you want checked
/// `container: true`.
Future<void> expectUiSane(
  WidgetTester tester, {
  Set<String> allowOverlap = const <String>{},
}) async {
  final List<String> violations = <String>[];

  // (1) Exactly one takeException() call. Keep the value and re-report it.
  final Object? escaped = tester.takeException();
  if (escaped != null) {
    violations.add(_describeEscapedException(tester, escaped));
  }

  // The handle is disposed in a `finally` before returning, NOT via
  // addTearDown: flutter_test verifies handle disposal BEFORE addTearDown
  // callbacks run (TRD 23-01, Deviation 1).
  final SemanticsHandle handle = tester.ensureSemantics();
  try {
    final List<SemanticsGeometryNode> nodes = identifiedNodes(tester);

    violations.addAll(_viewportViolations(tester, nodes));
    violations.addAll(_overlapViolations(nodes, allowOverlap));
    violations.addAll(_tapRouteViolations(tester));
  } finally {
    handle.dispose();
  }

  if (violations.isNotEmpty) {
    throw TestFailure(
      'expectUiSane found ${violations.length} violation(s) on this surface:\n'
      '${violations.map((String v) => '  - $v').join('\n')}',
    );
  }
}

// -----------------------------------------------------------------------------
// Checks
// -----------------------------------------------------------------------------

String _describeEscapedException(WidgetTester tester, Object escaped) {
  final String text = escaped.toString();
  final RegExp overflow = RegExp(
    r'A (\w+) overflowed by ([\d.]+) pixels on the (\w+)',
  );
  final RegExpMatch? match = overflow.firstMatch(text);
  if (match == null) {
    return 'an exception escaped during layout/paint: $text';
  }

  // CRITICAL: the exception itself is ONLY the summary line. The creator chain
  // that names the offending widget lives in the FlutterErrorDetails'
  // `informationCollector`, which `tester.takeException()` throws away — so a
  // naive re-report says "A RenderFlex overflowed by 215 pixels" and never
  // tells the consumer WHICH Row. Recover the name from the render tree
  // instead: RenderFlex.toStringShort() appends ' OVERFLOWING' while it is
  // overflowing, so the element that owns it can be found and asked for its
  // creator chain.
  final List<String> culprits = _overflowingCreatorChains(tester);
  final String named = culprits.isEmpty
      ? 'the overflowing render object could not be located in the tree'
      : culprits.map((String c) => '\n      $c').join();
  return '${match.group(1)} overflow of ${match.group(2)} pixels on the '
      '${match.group(3)}. Offending widget(s):$named';
}

/// Creator chains of every render object currently reporting an overflow.
///
/// Dedupes by render object and keeps the DEEPEST element that owns it —
/// `Element.renderObject` walks down to the nearest descendant render object,
/// so a whole stack of ancestor elements answers the same RenderFlex.
List<String> _overflowingCreatorChains(WidgetTester tester) {
  final Map<RenderObject, String> byRenderObject = <RenderObject, String>{};

  void visit(Element element) {
    final RenderObject? renderObject = element.renderObject;
    if (renderObject != null &&
        renderObject.toStringShort().contains('OVERFLOWING')) {
      byRenderObject[renderObject] = element.debugGetCreatorChain(6);
    }
    element.visitChildren(visit);
  }

  tester.binding.rootElement?.visitChildren(visit);
  return byRenderObject.values.toList();
}

List<String> _viewportViolations(
  WidgetTester tester,
  List<SemanticsGeometryNode> nodes,
) {
  final Size viewport =
      tester.view.physicalSize / tester.view.devicePixelRatio;
  final Rect viewportRect = Offset.zero & viewport;
  final List<String> out = <String>[];
  for (final SemanticsGeometryNode node in nodes) {
    final Rect r = node.globalRect;
    final bool inside = r.left >= viewportRect.left - _epsilon &&
        r.top >= viewportRect.top - _epsilon &&
        r.right <= viewportRect.right + _epsilon &&
        r.bottom <= viewportRect.bottom + _epsilon;
    if (!inside) {
      out.add(
        'control "${node.identifier}" is outside the viewport: its rect is $r, '
        'the viewport is $viewportRect',
      );
    }
  }
  return out;
}

List<String> _overlapViolations(
  List<SemanticsGeometryNode> nodes,
  Set<String> allowOverlap,
) {
  final List<String> out = <String>[];
  for (int i = 0; i < nodes.length; i++) {
    for (int j = i + 1; j < nodes.length; j++) {
      final SemanticsGeometryNode a = nodes[i];
      final SemanticsGeometryNode b = nodes[j];
      final String aId = a.identifier ?? '';
      final String bId = b.identifier ?? '';
      if (allowOverlap.contains(aId) || allowOverlap.contains(bId)) {
        continue;
      }
      if (rectsOverlap(a.globalRect, b.globalRect)) {
        out.add(
          'controls "$aId" and "$bId" overlap: "$aId" is ${a.globalRect}, '
          '"$bId" is ${b.globalRect}, they share '
          '${a.globalRect.intersect(b.globalRect)}. On web the semantics node '
          'is the click target, so one of these eats the other\'s taps. Pass '
          'allowOverlap: {\'$aId\'} if the overlap is deliberate.',
        );
      }
    }
  }
  return out;
}

List<String> _tapRouteViolations(WidgetTester tester) {
  final SemanticsNode root = rootSemanticsNodeOf(tester);
  final List<String> out = <String>[];

  void walk(SemanticsNode node) {
    final String identifier = node.getSemanticsData().identifier;
    if (identifier.isNotEmpty) {
      final int routes = _countTapRoutes(node, isOwner: true);
      if (routes > 1) {
        out.add(
          'control "$identifier" declares $routes tap actions (its own '
          'semantics node plus ${routes - 1} unidentified descendant node(s) '
          'that also advertise SemanticsAction.tap). A tap fires every route. '
          'Wrap the inner widget in ExcludeSemantics, or drop the outer '
          'Semantics(onTap:).',
        );
      }
    }
    node.visitChildren((SemanticsNode child) {
      walk(child);
      return true;
    });
  }

  walk(root);
  return out;
}

/// Counts `SemanticsAction.tap` on [node] and on its descendants, stopping at
/// any descendant that carries its own identifier — that node is a separate
/// control and owns its own routes.
int _countTapRoutes(SemanticsNode node, {required bool isOwner}) {
  final SemanticsData data = node.getSemanticsData();
  if (!isOwner && data.identifier.isNotEmpty) {
    return 0;
  }
  int count = data.hasAction(SemanticsAction.tap) ? 1 : 0;
  node.visitChildren((SemanticsNode child) {
    count += _countTapRoutes(child, isOwner: false);
    return true;
  });
  return count;
}

/// Sub-pixel slack for the viewport containment check: a control laid out flush
/// against the right edge can land at 1280.0000000001 after a matrix compose.
const double _epsilon = 0.01;

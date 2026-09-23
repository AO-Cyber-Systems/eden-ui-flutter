// The UI Oracle semantics-geometry helper.
//
// IMPORT CONVENTION (changed in TRD 23-02): this implementation moved out of
// `test_support/ui_oracle/` and into `lib/testing/`, so it now ships to
// consumers. Reach it through the public entry point:
//
//     import 'package:eden_ui_flutter/testing.dart';
//
// `test_support/ui_oracle/semantics_geometry.dart` remains as a one-line
// re-export shim so 23-01's tests keep their relative import unmodified.
//
// TEST-ONLY: this library imports `package:flutter_test`. It must never be
// reachable from `lib/eden_ui.dart` or anything under `lib/src/`, or two
// consumer apps drag flutter_test into their release graph on the next pin
// bump.
//
// WHY THIS EXISTS: `tester.getRect(find.byX)` answers a different question —
// the RENDER OBJECT's box. On web it is the semantics node, not the widget,
// that receives the click (memory note
// `flutter-web-semantics-node-is-the-click-target`), so the rect that matters
// is the one the accessibility tree publishes. Those two answers can disagree,
// and when they do the accessibility one is what a user actually hits.
//
// The transform walk below composes the ancestor chain root -> node and
// transforms THE NODE'S OWN rect last. A root-down shortcut that stops at the
// nearest container ancestor returns the PARENT's rect and quietly turns every
// downstream geometry assertion into a green test that proves nothing.
library;

import 'package:flutter/rendering.dart';
// `flutter_test` is a dev_dependency (see pubspec.yaml) and is imported here
// DELIBERATELY: this library is test-only and never reaches a consumer's
// production graph, because `lib/eden_ui.dart` does not export it. Promoting
// flutter_test to `dependencies:` would push it into eden-biz's and aodex's
// release resolve, which is exactly what must not happen.
// ignore: depend_on_referenced_packages
import 'package:flutter_test/flutter_test.dart';

/// One semantics node, with the rect the accessibility tree publishes for it
/// resolved into global (screen) coordinates.
class SemanticsGeometryNode {
  const SemanticsGeometryNode({
    required this.id,
    required this.identifier,
    required this.globalRect,
    required this.actions,
  });

  /// The `SemanticsNode.id` this was read from.
  final int id;

  /// The node's semantics identifier, or null when it carries none.
  final String? identifier;

  /// The node's own rect, in global coordinates.
  final Rect globalRect;

  /// The actions the node advertises (tap, scroll, ...).
  final Set<SemanticsAction> actions;

  @override
  String toString() =>
      'SemanticsGeometryNode(id: $id, identifier: $identifier, '
      'globalRect: $globalRect, actions: $actions)';
}

/// Every node in the current semantics tree that carries a non-empty
/// identifier, sorted by `(top, left, identifier)`.
///
/// Sorting is deliberate: `visitChildren` order is an implementation detail and
/// must never be asserted on directly.
List<SemanticsGeometryNode> identifiedNodes(WidgetTester tester) {
  // The handle is disposed before this function returns, NOT via addTearDown:
  // flutter_test asserts "a SemanticsHandle was active at the end of the test"
  // during its end-of-test verification, which runs BEFORE addTearDown
  // callbacks. A deferred dispose therefore fails every test that reads
  // geometry.
  final SemanticsHandle handle = tester.ensureSemantics();
  try {
    return _collect(tester);
  } finally {
    handle.dispose();
  }
}

/// The root [SemanticsNode] of the currently pumped tree.
///
/// Semantics must already be enabled — either inside an [identifiedNodes] call
/// or under a live [WidgetTester.ensureSemantics] handle. Throws a named
/// [StateError] when no root node exists.
///
/// Exposed so callers that need the TREE (parent/child relationships), not just
/// the flattened geometry list, do not reimplement the root accessor.
SemanticsNode rootSemanticsNodeOf(WidgetTester tester) {
  // `PipelineOwner.semanticsOwner` is deprecated in favour of the
  // SemanticsBinding, but the binding exposes no root SemanticsNode, and the
  // root PipelineOwner does not own semantics (its per-view children do). This
  // is the only reachable handle on the root node at the declared SDK floor.
  // ignore: deprecated_member_use
  final SemanticsOwner? owner = tester.binding.pipelineOwner.semanticsOwner;
  final SemanticsNode? root = owner?.rootSemanticsNode;
  if (root == null) {
    throw StateError(
      'SemanticsGeometry: no root semantics node. Pump a widget (e.g. via '
      'wrap()) before asking for semantics geometry.',
    );
  }
  return root;
}

List<SemanticsGeometryNode> _collect(WidgetTester tester) {
  final SemanticsNode root = rootSemanticsNodeOf(tester);

  final List<SemanticsGeometryNode> found = <SemanticsGeometryNode>[];

  void visit(SemanticsNode node, List<SemanticsNode> ancestors) {
    final SemanticsData data = node.getSemanticsData();
    final String identifier = data.identifier;
    if (identifier.isNotEmpty) {
      found.add(
        SemanticsGeometryNode(
          id: node.id,
          identifier: identifier,
          globalRect: _globalRectOfNode(node, ancestors),
          actions: _actionsOf(data),
        ),
      );
    }

    final List<SemanticsNode> children = <SemanticsNode>[];
    node.visitChildren((SemanticsNode child) {
      children.add(child);
      return true;
    });
    final List<SemanticsNode> nextAncestors = <SemanticsNode>[
      ...ancestors,
      node,
    ];
    for (final SemanticsNode child in children) {
      visit(child, nextAncestors);
    }
  }

  visit(root, const <SemanticsNode>[]);

  found.sort((SemanticsGeometryNode a, SemanticsGeometryNode b) {
    final int byTop = a.globalRect.top.compareTo(b.globalRect.top);
    if (byTop != 0) {
      return byTop;
    }
    final int byLeft = a.globalRect.left.compareTo(b.globalRect.left);
    if (byLeft != 0) {
      return byLeft;
    }
    return (a.identifier ?? '').compareTo(b.identifier ?? '');
  });

  return found;
}

/// The global rect of the node carrying [identifier].
///
/// Throws a named [StateError] when no such node exists, listing the
/// identifiers that were found — an absent identifier is almost always a
/// missing `container: true`, not a missing widget.
Rect globalRectOf(WidgetTester tester, String identifier) {
  final List<SemanticsGeometryNode> nodes = identifiedNodes(tester);
  for (final SemanticsGeometryNode node in nodes) {
    if (node.identifier == identifier) {
      return node.globalRect;
    }
  }
  throw StateError(
    'SemanticsGeometry: no semantics node with identifier "$identifier". '
    'Identifiers present: '
    '${nodes.map((SemanticsGeometryNode n) => n.identifier).toList()}',
  );
}

/// True when [a] and [b] share any area.
///
/// Touching edges do not count as overlapping: two 40-wide controls laid out
/// side by side with no gap are adjacent, not overlapping.
bool rectsOverlap(Rect a, Rect b) {
  final Rect intersection = a.intersect(b);
  return intersection.width > 0 && intersection.height > 0;
}

// -----------------------------------------------------------------------------
// Internals
// -----------------------------------------------------------------------------

/// Composes [ancestors] (root-first, excluding [node]) and then [node]'s own
/// transform, and applies the result to [node]'s OWN rect.
///
/// CRITICAL: `node.rect` is transformed, never an ancestor's rect. That is the
/// single property that makes the `container: true` omission observable.
Rect _globalRectOfNode(SemanticsNode node, List<SemanticsNode> ancestors) {
  // GOTCHA: SemanticsNode.transform is null when it is the identity.
  Matrix4 composed = Matrix4.identity();
  for (final SemanticsNode ancestor in ancestors) {
    final Matrix4? transform = ancestor.transform;
    if (transform != null) {
      composed = composed.multiplied(transform);
    }
  }
  final Matrix4? own = node.transform;
  if (own != null) {
    composed = composed.multiplied(own);
  }
  return MatrixUtils.transformRect(composed, node.rect);
}

Set<SemanticsAction> _actionsOf(SemanticsData data) {
  final Set<SemanticsAction> actions = <SemanticsAction>{};
  for (final SemanticsAction action in SemanticsAction.values) {
    if (data.hasAction(action)) {
      actions.add(action);
    }
  }
  return actions;
}

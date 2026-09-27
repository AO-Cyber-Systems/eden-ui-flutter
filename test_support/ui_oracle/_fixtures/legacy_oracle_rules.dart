// The tap-route rules `expectUiSane` USED TO HAVE, kept executable.
//
// WHY. A catalogue entry that records only the passing state cannot tell a
// reader whether the fixture would have caught the original defect — which is
// the whole reason the fixtures exist. "This fixture is caught" is worth very
// little on its own: a fixture the PREVIOUS oracle also caught proves the
// enumeration was already wide enough there, and a fixture only the CURRENT
// oracle catches is a regression pin for a specific fix.
//
// The two predicates below are the two prior shapes of the tap-route rule,
// reconstructed from the reasons recorded in `expect_ui_sane.dart` itself:
//
//   * [legacyRoutesGreaterThanOne] — the rule before the lower bound existed.
//     It fired only on `routes > 1` and was silent on zero, which is how
//     replacing `ExcludeSemantics` with `IgnorePointer` in the mobile nav row
//     killed four buttons and turned the whole story oracle GREEN.
//   * [legacyOwnerAnywhereInPath] — the reachability rule before
//     `_pathEntersOwner` asked whether a STRICT DESCENDANT of the owner was
//     in the hit path. It asked only whether the owner appeared in the path
//     at all, and `RenderAbsorbPointer` walks straight through that: it
//     returns true without adding itself or anything below it, the enclosing
//     `RenderSemanticsAnnotations` sees a hit child and adds ITSELF, and the
//     owner is in the path on a control no finger can touch.
//
// These are DELIBERATELY not imported from the oracle — they are the code
// that was deleted from it. They exist so the catalogue can state, per
// fixture and with a run behind it, whether the fixture discriminates between
// the two versions. Nothing outside the catalogue should call them.
library;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
// ignore: depend_on_referenced_packages
import 'package:flutter_test/flutter_test.dart';

/// Whether the node carrying [identifier] would have been reported by the
/// tap-route rule as it stood BEFORE the zero arm was added: a violation only
/// when the control declares more than one route.
///
/// Returns false when the control is not on the surface at all — the old rule
/// was silent on an absent control, exactly as the current one is.
bool legacyRoutesGreaterThanOne(WidgetTester tester, String identifier) {
  final SemanticsHandle handle = tester.ensureSemantics();
  try {
    final SemanticsNode? node = _nodeFor(tester, identifier);
    if (node == null) {
      return false;
    }
    return _countTapRoutes(node, isOwner: true) > 1;
  } finally {
    handle.dispose();
  }
}

/// Whether a pointer dropped in the middle of [identifier]'s rect reaches it
/// under the PRE-REWRITE reachability rule: the owner appearing ANYWHERE in
/// the hit-test path counted as reached.
///
/// True means "the old rule saw nothing wrong", which is the answer the
/// catalogue wants: a fixture where this is true and the oracle now reports a
/// violation is a fixture that discriminates between the two versions.
///
/// Returns true — no accusation — for a control that is not on the surface,
/// for the same reason the oracle does: a rule that cannot establish the fact
/// must stay silent rather than name a control it did not measure.
bool legacyOwnerAnywhereInPath(WidgetTester tester, String identifier) {
  final SemanticsHandle handle = tester.ensureSemantics();
  try {
    final SemanticsNode? node = _nodeFor(tester, identifier);
    if (node == null) {
      return true;
    }
    final RenderObject? owner = _ownerOf(tester, node.id);
    if (owner == null) {
      return true;
    }
    final double ratio = tester.view.devicePixelRatio;
    final Rect rect = _globalRectOf(node);
    final Offset location = rect.center / ratio;
    final Size viewport = tester.view.physicalSize / ratio;
    if (location.dx < 0 ||
        location.dy < 0 ||
        location.dx > viewport.width ||
        location.dy > viewport.height) {
      return true;
    }
    final HitTestResult result = tester.hitTestOnBinding(location);
    return result.path
        .any((HitTestEntry entry) => identical(entry.target, owner));
  } finally {
    handle.dispose();
  }
}

SemanticsNode? _nodeFor(WidgetTester tester, String identifier) {
  // ignore: deprecated_member_use
  final SemanticsNode? root =
      // ignore: deprecated_member_use
      tester.binding.pipelineOwner.semanticsOwner?.rootSemanticsNode;
  if (root == null) {
    return null;
  }
  SemanticsNode? found;
  void walk(SemanticsNode node) {
    if (node.getSemanticsData().identifier == identifier) {
      found ??= node;
    }
    node.visitChildren((SemanticsNode child) {
      walk(child);
      return true;
    });
  }

  walk(root);
  return found;
}

RenderObject? _ownerOf(WidgetTester tester, int semanticsId) {
  RenderObject? owner;
  void visit(Element element) {
    final RenderObject? renderObject = element.renderObject;
    if (owner == null &&
        renderObject != null &&
        renderObject.debugSemantics?.id == semanticsId) {
      owner = renderObject;
    }
    element.visitChildren(visit);
  }

  tester.binding.rootElement?.visitChildren(visit);
  return owner;
}

Rect _globalRectOf(SemanticsNode node) {
  Matrix4 composed = Matrix4.identity();
  final List<SemanticsNode> chain = <SemanticsNode>[];
  for (SemanticsNode? walk = node; walk != null; walk = walk.parent) {
    chain.insert(0, walk);
  }
  for (final SemanticsNode step in chain) {
    final Matrix4? transform = step.transform;
    if (transform != null) {
      composed = composed.multiplied(transform);
    }
  }
  return MatrixUtils.transformRect(composed, node.rect);
}

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

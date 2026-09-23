// The VM-testable core of the runtime probe.
//
// CRITICAL: this file imports NO `dart:js_interop` and no web types. It runs
// under `flutter test` on the Dart VM, which is what makes a green widget test
// here evidence about the SHIPPED bridge rather than about a parallel code
// path: the JS shim in `probe_bridge_web.dart` calls these same four entries
// and does nothing but convert their plain maps to `JSAny`.
library;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/semantics.dart';

/// One probe hit: an element or semantics node the probe matched.
class EdenProbeHit {
  const EdenProbeHit({
    required this.id,
    required this.rect,
    required this.actions,
    this.identifier,
  });

  /// Stable within a single call: 'hit-0', 'hit-1', ...
  final String id;

  /// The matched object's OWN rect, in global (screen) coordinates.
  final Rect rect;

  /// The semantics identifier, when the hit carries one.
  final String? identifier;

  /// The semantics actions the hit advertises, as plain strings.
  final List<String> actions;

  /// JSON-shaped, so the same value serialises for the JS shim and reads
  /// cleanly in a widget test.
  Map<String, Object?> toJson() => <String, Object?>{
        'id': id,
        'rect': <String, Object?>{
          'x': rect.left,
          'y': rect.top,
          'w': rect.width,
          'h': rect.height,
        },
        if (identifier != null) 'identifier': identifier,
        'actions': actions,
      };

  @override
  String toString() =>
      'EdenProbeHit(id: $id, rect: $rect, identifier: $identifier, '
      'actions: $actions)';
}

/// The probe's four questions, in pure Dart over the widget binding.
abstract final class EdenProbeApi {
  /// Requests a consumer's HTTP layer has told the probe are in flight.
  ///
  /// Opt-in rather than guessed: §7.1 wants "no HTTP requests in flight" in
  /// [settled], but the library cannot see a consumer's client. A consumer
  /// increments/decrements this; it defaults to 0 and [settled] then answers
  /// purely on frame scheduling.
  static int inFlightRequests = 0;

  static List<EdenProbeHit> find({
    String? key,
    String? text,
    String? type,
    String? identifier,
  }) {
    // A driver bug must not crash the app under test: no criteria means no
    // hits, never a full-tree dump and never a throw.
    if (key == null && text == null && type == null && identifier == null) {
      return const <EdenProbeHit>[];
    }

    final List<EdenProbeHit> hits = <EdenProbeHit>[];

    // `identifier:` is a SEMANTICS question, not a widget-tree one: it is the
    // accessibility node that receives the click on web, and its rect can
    // disagree with the render box's.
    if (identifier != null) {
      for (final _ProbeSemanticsNode node in _identifiedSemanticsNodes()) {
        if (node.identifier != identifier) {
          continue;
        }
        hits.add(EdenProbeHit(
          id: 'hit-${hits.length}',
          rect: node.globalRect,
          identifier: node.identifier,
          actions: node.actions,
        ));
      }
      return hits;
    }

    for (final Element element in _elements()) {
      if (key != null && !_matchesKey(element, key)) {
        continue;
      }
      if (text != null && !_matchesText(element, text)) {
        continue;
      }
      if (type != null &&
          element.widget.runtimeType.toString() != type) {
        continue;
      }
      final Rect? rect = _globalRect(element);
      if (rect == null) {
        continue;
      }
      hits.add(EdenProbeHit(
        id: 'hit-${hits.length}',
        rect: rect,
        actions: const <String>[],
      ));
    }

    return hits;
  }

  /// Every element in the live tree, root first.
  static List<Element> _elements() {
    final Element? root = WidgetsBinding.instance.rootElement;
    if (root == null) {
      return const <Element>[];
    }
    final List<Element> out = <Element>[];
    void visit(Element element) {
      out.add(element);
      element.visitChildren(visit);
    }

    visit(root);
    return out;
  }

  /// Keys are matched by their `toString()` carrying the requested string:
  /// `ValueKey<String>('probe-target')` prints as `[<'probe-target'>]`, and a
  /// driver knows the string it put in the source, not Flutter's rendering of
  /// the wrapper type.
  static bool _matchesKey(Element element, String key) {
    final Key? k = element.widget.key;
    return k != null && k.toString().contains(key);
  }

  /// Text is matched against what the user READS.
  static bool _matchesText(Element element, String text) {
    final Widget widget = element.widget;
    if (widget is Text) {
      final String? data = widget.data;
      if (data != null) {
        return data.contains(text);
      }
      final InlineSpan? span = widget.textSpan;
      return span != null && span.toPlainText().contains(text);
    }
    if (widget is RichText) {
      return widget.text.toPlainText().contains(text);
    }
    return false;
  }

  /// The element's OWN render box, in global coordinates.
  ///
  /// CRITICAL: never an ancestor's. A probe that walked up to the nearest
  /// sized ancestor would report a 360x200 parent for a 120x40 control and
  /// every downstream geometry assertion would be green and meaningless.
  static Rect? _globalRect(Element element) {
    final RenderObject? object = element.renderObject;
    if (object is! RenderBox || !object.attached || !object.hasSize) {
      return null;
    }
    return object.localToGlobal(Offset.zero) & object.size;
  }

  /// Every identified semantics node, with its own rect and the actions it
  /// declares.
  ///
  /// This is what makes a double-declared tap visible from OUTSIDE the app:
  /// two overlapping nodes that both advertise `tap` are reported as two
  /// nodes, not silently merged into one.
  static Map<String, Object?> tree() {
    return <String, Object?>{
      'route': _currentRoute(),
      'nodes': <Map<String, Object?>>[
        for (final _ProbeSemanticsNode node in _identifiedSemanticsNodes())
          <String, Object?>{
            'id': node.id,
            'identifier': node.identifier,
            'rect': <String, Object?>{
              'x': node.globalRect.left,
              'y': node.globalRect.top,
              'w': node.globalRect.width,
              'h': node.globalRect.height,
            },
            'actions': node.actions,
          },
      ],
    };
  }

  /// The name of the route currently on top.
  ///
  /// GOTCHA: there is no binding-level "current route" in Flutter. The deepest
  /// element that sits under a [ModalRoute] is the one on top, so the walk
  /// keeps the LAST non-null answer.
  static String? _currentRoute() {
    String? name;
    for (final Element element in _elements()) {
      if (!element.mounted) {
        continue;
      }
      final ModalRoute<Object?>? route = ModalRoute.of(element);
      if (route != null) {
        name = route.settings.name ?? name;
      }
    }
    return name;
  }

  /// True when nothing is animating and nothing the consumer declared is in
  /// flight — so a driver can wait on truth instead of a sleep.
  ///
  /// `transientCallbackCount` is the ticker count: a running
  /// [AnimationController] keeps it above zero even between scheduled frames.
  static bool settled() {
    final SchedulerBinding scheduler = SchedulerBinding.instance;
    return !scheduler.hasScheduledFrame &&
        scheduler.transientCallbackCount == 0 &&
        inFlightRequests == 0;
  }

  static Map<String, Object?> state() => const <String, Object?>{};
}

// -----------------------------------------------------------------------------
// Semantics walk
// -----------------------------------------------------------------------------

/// One identified semantics node, with its OWN rect resolved to global
/// coordinates.
class _ProbeSemanticsNode {
  const _ProbeSemanticsNode({
    required this.id,
    required this.identifier,
    required this.globalRect,
    required this.actions,
  });

  final int id;
  final String identifier;
  final Rect globalRect;
  final List<String> actions;
}

/// Every semantics node carrying a non-empty identifier, sorted by
/// `(top, left, identifier)` — `visitChildren` order is an implementation
/// detail and must never leak into a driver's expectations.
List<_ProbeSemanticsNode> _identifiedSemanticsNodes() {
  // `PipelineOwner.semanticsOwner` is deprecated in favour of the
  // SemanticsBinding, but the binding exposes no root SemanticsNode. This is
  // the only reachable handle on the root node at the declared SDK floor.
  // ignore: deprecated_member_use
  final SemanticsOwner? owner = WidgetsBinding.instance.pipelineOwner.semanticsOwner;
  final SemanticsNode? root = owner?.rootSemanticsNode;
  if (root == null) {
    return const <_ProbeSemanticsNode>[];
  }

  final List<_ProbeSemanticsNode> found = <_ProbeSemanticsNode>[];

  void visit(SemanticsNode node, List<SemanticsNode> ancestors) {
    final SemanticsData data = node.getSemanticsData();
    if (data.identifier.isNotEmpty) {
      found.add(_ProbeSemanticsNode(
        id: node.id,
        identifier: data.identifier,
        globalRect: _globalRectOfNode(node, ancestors),
        actions: _actionNames(data),
      ));
    }

    final List<SemanticsNode> children = <SemanticsNode>[];
    node.visitChildren((SemanticsNode child) {
      children.add(child);
      return true;
    });
    final List<SemanticsNode> next = <SemanticsNode>[...ancestors, node];
    for (final SemanticsNode child in children) {
      visit(child, next);
    }
  }

  visit(root, const <SemanticsNode>[]);

  found.sort((_ProbeSemanticsNode a, _ProbeSemanticsNode b) {
    final int byTop = a.globalRect.top.compareTo(b.globalRect.top);
    if (byTop != 0) {
      return byTop;
    }
    final int byLeft = a.globalRect.left.compareTo(b.globalRect.left);
    if (byLeft != 0) {
      return byLeft;
    }
    return a.identifier.compareTo(b.identifier);
  });

  return found;
}

/// Composes [ancestors] (root-first, excluding [node]) then [node]'s own
/// transform, and applies the result to [node]'s OWN rect.
///
/// CRITICAL: never an ancestor's rect — that is the single property that makes
/// a missing `container: true` observable from outside the app.
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
  final Rect physical = MatrixUtils.transformRect(composed, node.rect);

  // GOTCHA: the ROOT semantics node's transform is the view's devicePixelRatio
  // scale, so a raw composition returns PHYSICAL pixels -- a 100x48 control
  // reads as 300x144 at dpr 3. Every other rect this probe returns is a render
  // box's LOGICAL rect, and a driver compares the two. Normalise here so the
  // two answers are in one coordinate system; on web, logical pixels are CSS
  // pixels, which is what a CDP driver works in.
  final double dpr =
      WidgetsBinding.instance.platformDispatcher.implicitView?.devicePixelRatio ??
          1.0;
  if (dpr == 1.0) {
    return physical;
  }
  return Rect.fromLTRB(
    physical.left / dpr,
    physical.top / dpr,
    physical.right / dpr,
    physical.bottom / dpr,
  );
}

/// Action names as plain strings ('tap', 'scrollLeft', ...) so the shim can
/// hand them to JS without a mapping table on the far side.
List<String> _actionNames(SemanticsData data) {
  final List<String> names = <String>[];
  for (final SemanticsAction action in SemanticsAction.values) {
    if (data.hasAction(action)) {
      names.add(action.toString().replaceFirst('SemanticsAction.', ''));
    }
  }
  return names;
}

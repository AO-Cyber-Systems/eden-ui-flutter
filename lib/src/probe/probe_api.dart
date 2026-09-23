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

    for (final Element element in _elements()) {
      if (key != null && !_matchesKey(element, key)) {
        continue;
      }
      if (text != null && !_matchesText(element, text)) {
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

  static Map<String, Object?> tree() => const <String, Object?>{};

  static bool settled() => false;

  static Map<String, Object?> state() => const <String, Object?>{};
}

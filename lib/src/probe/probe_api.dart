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
    return const <EdenProbeHit>[];
  }

  static Map<String, Object?> tree() => const <String, Object?>{};

  static bool settled() => false;

  static Map<String, Object?> state() => const <String, Object?>{};
}

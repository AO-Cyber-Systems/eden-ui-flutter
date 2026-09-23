// The web shim — DELIBERATELY THIN.
//
// `flutter test` runs on the Dart VM, so nothing in this file can be reached
// by a widget test. That is exactly why it contains no logic: every answer is
// computed in `probe_api.dart` (which IS VM-testable) and this file does
// nothing but call it and convert the resulting plain maps to `JSAny`. A green
// widget test over `EdenProbeApi` is therefore evidence about the SHIPPED
// bridge rather than about a parallel code path.
//
// Anything added here that is not a conversion is untested by construction.
library;

import 'dart:js_interop';

import 'probe_api.dart';

@JS('window')
external JSObject get _window;

extension type _EdenProbeJs._(JSObject _) implements JSObject {
  external factory _EdenProbeJs({
    JSFunction find,
    JSFunction tree,
    JSFunction settled,
    JSFunction state,
  });
}

/// Installs `window.__edenProbe.{find,tree,settled,state}`.
void installProbeBridge() {
  _window.setProperty(
    '__edenProbe'.toJS,
    _EdenProbeJs(
      find: ((JSObject? criteria) {
        final Map<String, Object?>? c = criteria == null
            ? null
            : (criteria.dartify() as Map<Object?, Object?>?)
                ?.map<String, Object?>(
                (Object? k, Object? v) => MapEntry<String, Object?>('$k', v),
              );
        final List<Map<String, Object?>> hits = EdenProbeApi.find(
          key: c?['key'] as String?,
          text: c?['text'] as String?,
          type: c?['type'] as String?,
          identifier: c?['identifier'] as String?,
        ).map((EdenProbeHit h) => h.toJson()).toList();
        return hits.jsify();
      }).toJS,
      tree: (() => EdenProbeApi.tree().jsify()).toJS,
      settled: (() => EdenProbeApi.settled().toJS).toJS,
      state: (() => EdenProbeApi.state().jsify()).toJS,
    ),
  );
}

// tool/emit_component_manifest.dart
//
// Emits agent-components.json — the authoritative list of `component_id`s
// this package can RENDER, for a headless agent to check its intents against.
//
// WHY THIS EXISTS. A headless agent names a surface by `component_id` and
// this package draws it. eden-biz carries 15 recorded fixtures using 10
// distinct ids, and its own integrity test
// (`go/internal/agentintent/fixtures_integrity_test.go`) asserts only that
// the field is NON-EMPTY. Neither side declared the valid set. So an agent
// could emit `summary/pipeline`, the Go fixture test would pass, and nothing
// anywhere knew the renderer cannot draw it — an unknown `component_id` was
// an UNDETECTABLE condition. This manifest is what makes it detectable.
//
// TWO ENTRIES TODAY. Eight of eden-biz's ten ids have no renderer here, and
// publishing an honest two is the point: `error/refusal` is the declared
// destination for an id that is not in the list, and it is already the
// second-most-used id in eden-biz's own fixtures (4 of 15). A
// hand-maintained list of ten would be eight lies.
//
// DIRECTION. This declares what eden-ui CAN RENDER; eden-biz checks its
// fixtures against it. Hard-coding eden-biz's fixture ids here would invert
// the dependency and make the component library track the agent's test data.
//
// SCHEMA — LOCKED. A JSON array, sorted by `component_id` ascending, of
// objects with EXACTLY these two keys:
//
//   { "component_id": <string>, "widget": <string> }
//
// Any drift breaks the consumer, so the schema is asserted key-for-key in
// `test/tool/emit_component_manifest_test.dart` rather than described here
// and hoped for. Sorted so the output is byte-stable across runs and a diff
// shows only what actually changed.
//
// HOW TO RUN — via the flutter test runner, NOT plain `dart`:
//
//   flutter test tool/emit_component_manifest.dart
//
// The declaration transitively imports package:flutter/material.dart (the
// widgets it names are Widgets), so this only compiles against the Flutter
// engine that `flutter test` provides; a bare `dart run` fails to resolve
// dart:ui. Running it as a single test gives a clean exit 0 and lets the
// engine load. Same constraint, same reason, as tool/emit_flutter_manifest.dart.
//
// 0-new-deps: dart:convert + dart:io + the already-present flutter_test only.
// The list-building is factored into [buildComponentManifestEntries] so it is
// unit-testable in isolation, exactly as buildFlutterManifestEntries() is.
library;

import 'dart:convert';
import 'dart:io';

import 'package:eden_ui_flutter/eden_ui.dart';
import 'package:flutter_test/flutter_test.dart';

/// Default output path (relative to the package root) for the emitted
/// manifest. `flutter test` runs with the package root as the working
/// directory.
const String defaultEmitOut = 'build/agent-components.json';

/// The two keys the locked schema permits, in emission order.
///
/// Named here rather than left implicit in the map literal so the test can
/// assert the emitted keys against this list instead of restating them — a
/// second copy of a schema is how a schema drifts.
const List<String> kComponentManifestKeys = <String>[
  'component_id',
  'widget',
];

/// Builds the sorted manifest entries from [kDataDisplayComponents].
///
/// Pure: no I/O, no registry mutation, same output every call — so the test
/// can exercise it directly.
///
/// Sorted by `component_id` so the emitted bytes are stable regardless of
/// declaration order, and a diff of the manifest shows only real changes.
/// `compareTo` on the id is a total order (ids are unique — the closed
/// partition test proves it), so the sort needs no tiebreak.
List<Map<String, Object>> buildComponentManifestEntries() {
  final List<Map<String, Object>> entries = <Map<String, Object>>[
    for (final (String id, Type widget) in kDataDisplayComponents)
      <String, Object>{
        'component_id': id,
        'widget': widget.toString(),
      },
  ];
  entries.sort((Map<String, Object> a, Map<String, Object> b) =>
      (a['component_id']! as String).compareTo(b['component_id']! as String));
  return entries;
}

/// Serializes to pretty-printed JSON with a trailing newline, matching the
/// convention `tool/emit_flutter_manifest.dart` already established for the
/// Go side's `MarshalManifest` output.
String encodeComponentManifest(List<Map<String, Object>> entries) =>
    '${const JsonEncoder.withIndent('  ').convert(entries)}\n';

void main() {
  // Wrapped in a single test() so `flutter test tool/emit_component_manifest
  // .dart` exits 0 — a plain main() reports "No tests ran" and exits
  // non-zero, which would break any chain that calls this. The body is the
  // emit, not an assertion-only test. Same device, same reason, as
  // tool/emit_flutter_manifest.dart.
  test('emit agent-components.json', () {
    const String emitOut =
        String.fromEnvironment('EMIT_OUT', defaultValue: defaultEmitOut);
    final List<Map<String, Object>> entries = buildComponentManifestEntries();
    final File file = File(emitOut);
    file.parent.createSync(recursive: true);
    file.writeAsStringSync(encodeComponentManifest(entries));
    stdout.writeln('emit_component_manifest: wrote ${entries.length} '
        'component(s) → $emitOut');

    // NOT a tautology: an empty manifest would mean the declaration is empty,
    // which would make the closed-partition test vacuous at the same time.
    // Two gates, one failure mode — this is the cheap half.
    expect(entries, isNotEmpty);
  });
}

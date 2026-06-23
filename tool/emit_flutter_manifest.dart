// tool/emit_flutter_manifest.dart
//
// Emits flutter-stories.json — the Flutter explorer's slice of the unified
// eden-docs portal search manifest (38-06).
//
// It registers every story (registerAllStories from 38-05) then writes a sorted
// JSON array of objects shaped EXACTLY like eden-docs's portal.ManifestEntry for
// flutter entries:
//
//   { "explorer": "flutter", "id": <story id>, "component": <component>,
//     "name": <name>, "path": "/flutter/#/story/<id>" }      // status OMITTED
//
// The eden-docs portal merges these in place of the single planned /flutter/
// placeholder (see eden-docs/portal/manifest.go BuildManifestWithFlutter). The
// schema is LOCKED: explorer/id/component/name/path only, status omitted — any
// drift breaks the Go-side merge.
//
// Order: StoryRegistry.all() is already sorted by (component, name), which is the
// same key the Go sortManifest uses, so the emitted array order == the golden
// manifest order.
//
// HOW TO RUN — via the flutter test runner, NOT plain `dart`:
//
//   flutter test tool/emit_flutter_manifest.dart
//
// (The justfile `build-flutter-explorer` target does this.) The story registry
// transitively imports package:flutter/material.dart (EdenStory.icon is an
// IconData, screens build Widgets), so the entry-building only compiles against
// the Flutter engine that `flutter test` provides — a bare `dart run` fails to
// resolve dart:ui. Running it as a single test gives a clean exit 0 and lets the
// engine load; main() writes the manifest to <emitOut> (default build/web/
// flutter-stories.json, overridable via --dart-define=EMIT_OUT=...).
//
// 0-new-deps: dart:convert + dart:io + the already-present flutter_test only. The
// entry-building is factored into buildFlutterManifestEntries() so it is also
// unit-testable in isolation (test/tool/emit_flutter_manifest_test.dart).

import 'dart:convert';
import 'dart:io';

import 'package:eden_ui_flutter/dev_app/registry/register_all.dart';
import 'package:eden_ui_flutter/dev_app/registry/story_registry.dart';
import 'package:flutter_test/flutter_test.dart';

/// Default output path (relative to the eden-ui-flutter project root) for the
/// emitted manifest. The eden-docs portal reads it as --flutter-manifest.
const String defaultEmitOut = 'build/web/flutter-stories.json';

/// Registers all stories (on a clean registry) and builds the sorted list of
/// flutter ManifestEntry-shaped maps.
///
/// Each entry omits `status` (live entries carry no status marker) and uses the
/// hash route form `/flutter/#/story/<id>` from 38-03. The returned list is in
/// StoryRegistry.all() order — sorted by (component, name).
List<Map<String, Object>> buildFlutterManifestEntries() {
  StoryRegistry.instance.clear();
  registerAllStories();
  return StoryRegistry.instance
      .all()
      .map<Map<String, Object>>((s) => {
            'explorer': 'flutter',
            'id': s.id,
            'component': s.component,
            'name': s.name,
            'path': '/flutter/#/story/${s.id}',
          })
      .toList();
}

/// Serializes the flutter manifest entries to pretty-printed JSON with a trailing
/// newline (matching the Go-side MarshalManifest output convention).
String encodeFlutterManifest(List<Map<String, Object>> entries) =>
    '${const JsonEncoder.withIndent('  ').convert(entries)}\n';

void main() {
  // Wrapped in a single test() so `flutter test tool/emit_flutter_manifest.dart`
  // exits 0 (a plain main() reports "No tests ran" → non-zero, breaking the
  // justfile chain). The body is the emit, not an assertion-only test.
  test('emit flutter-stories.json', () {
    const emitOut =
        String.fromEnvironment('EMIT_OUT', defaultValue: defaultEmitOut);
    final entries = buildFlutterManifestEntries();
    final file = File(emitOut);
    file.parent.createSync(recursive: true);
    file.writeAsStringSync(encodeFlutterManifest(entries));
    stdout.writeln(
        'emit_flutter_manifest: wrote ${entries.length} entries → $emitOut');
    expect(entries, isNotEmpty);
  });
}

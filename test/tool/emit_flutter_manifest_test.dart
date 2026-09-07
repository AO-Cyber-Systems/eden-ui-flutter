// test/tool/emit_flutter_manifest_test.dart
//
// Unit test for the flutter-stories.json emitter (38-06).
//
// The emit tool factors the entry-building into `buildFlutterManifestEntries()`
// so this test can import and exercise it WITHOUT running `main()` (which writes
// to stdout). The test pins the eden-docs ManifestEntry contract that the Go
// portal merges in: explorer=='flutter', non-empty id/component/name/path,
// path == '/flutter/#/story/<id>', NO 'status' key, sorted by (component, name),
// and one entry per registered story (45 from 38-05).

import 'dart:convert';

import 'package:eden_ui_flutter/dev_app/registry/story_registry.dart';
import 'package:flutter_test/flutter_test.dart';

// The tool under test lives at ../../tool/emit_flutter_manifest.dart relative to
// this file; import it directly (it is plain library code outside lib/).
import '../../tool/emit_flutter_manifest.dart';

void main() {
  setUp(() {
    StoryRegistry.instance.clear();
  });

  test('buildFlutterManifestEntries registers all stories and emits one per story', () {
    final entries = buildFlutterManifestEntries();
    expect(
      entries.length,
      StoryRegistry.instance.all().length,
      reason: 'one manifest entry per registered story',
    );
    expect(entries.length, 45, reason: '38-05 registers 45 stories');
  });

  test('every entry matches the eden-docs flutter ManifestEntry contract', () {
    final entries = buildFlutterManifestEntries();
    for (final e in entries) {
      expect(e['explorer'], 'flutter');
      expect(e.containsKey('status'), isFalse, reason: 'status must be OMITTED');
      expect((e['id'] as String), isNotEmpty);
      expect((e['component'] as String), isNotEmpty);
      expect((e['name'] as String), isNotEmpty);
      expect(e['path'], '/flutter/#/story/${e['id']}');
    }
  });

  test('entries are sorted by (component, name) matching StoryRegistry.all()', () {
    final entries = buildFlutterManifestEntries();
    final sorted = [...entries]..sort((a, b) {
        final cmp = (a['component'] as String).compareTo(b['component'] as String);
        if (cmp != 0) return cmp;
        return (a['name'] as String).compareTo(b['name'] as String);
      });
    expect(entries, sorted, reason: 'emit order == registry sort order');

    // And the order matches the canonical registry order (id-for-id).
    final ids = entries.map((e) => e['id']).toList();
    final registryIds = StoryRegistry.instance.all().map((s) => s.id).toList();
    expect(ids, registryIds);
  });

  test('encoded output parses back to the same JSON list', () {
    final entries = buildFlutterManifestEntries();
    final json = const JsonEncoder.withIndent('  ').convert(entries);
    final decoded = jsonDecode(json);
    expect(decoded, isA<List<dynamic>>());
    expect((decoded as List).length, entries.length);
  });
}

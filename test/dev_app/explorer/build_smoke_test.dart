// test/dev_app/explorer/build_smoke_test.dart
//
// Build-smoke assertion gate for TRD 38-07 (Wave 6 verification).
//
// This test ASSERTS the artifacts produced by `just build-flutter-explorer`
// (i.e. `flutter build web --base-href /flutter/` + emit_flutter_manifest.dart).
// It does NOT run the build itself — that is the job of the `just test-flutter-build`
// justfile recipe (which runs the build first, then this test).
//
// When build/web is absent (e.g. plain `flutter test` in CI without a prior build),
// the test SKIPS cleanly with an actionable message — keeping `just test` fast and
// never forcing a heavy 2-min+ Flutter web build inside the unit-test runner.
//
// Assertions (when build/web IS present):
//   1. build/web/index.html contains <base href="/flutter/"> — mandatory for the
//      eden-docs portal to serve the explorer at /flutter/ without 404 asset errors.
//   2. build/web/flutter-stories.json parses as a JSON array with >= 39 entries
//      (6 interactive + the gallery + static stories registered in registerAllStories).
//   3. Every manifest entry carries explorer=="flutter" and a path that starts with
//      "/flutter/#/story/" — the hash-URL contract (TRD 38-03).
//
// ANTI-PATTERNS (enforced here):
//   - Never call `flutter build web` from inside this file — too slow for a unit test.
//   - Never bind or reference :8080 (permanently occupied; all previews use :8091).

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  // Resolve relative to the package root (where `flutter test` runs from).
  // `flutter test` sets the cwd to the package root (eden-ui-flutter/).
  final indexFile = File('build/web/index.html');
  final manifestFile = File('build/web/flutter-stories.json');

  test('build/web/index.html contains <base href="/flutter/">', () {
    if (!indexFile.existsSync()) {
      markTestSkipped(
        'build/web not found — run `just build-flutter-explorer` first, '
        'then re-run this test via `just test-flutter-build`.',
      );
      return;
    }

    final content = indexFile.readAsStringSync();
    expect(
      content,
      contains('<base href="/flutter/">'),
      reason:
          'index.html must carry <base href="/flutter/"> so the portal '
          'serves the explorer at /flutter/ without hashed-asset 404s.',
    );
  });

  test(
    'build/web/flutter-stories.json is valid JSON with >= 39 flutter entries',
    () {
      if (!manifestFile.existsSync()) {
        markTestSkipped(
          'build/web/flutter-stories.json not found — run '
          '`just build-flutter-explorer` first, then re-run via '
          '`just test-flutter-build`.',
        );
        return;
      }

      final List<dynamic> entries =
          jsonDecode(manifestFile.readAsStringSync()) as List<dynamic>;

      expect(
        entries.length,
        greaterThanOrEqualTo(39),
        reason:
            'Expected at least 39 stories (6 interactive + galleries + static). '
            'If fewer, check that registerAllStories() in dev_app.dart registers '
            'the full set (TRD 38-05).',
      );

      for (final raw in entries) {
        final e = raw as Map<String, dynamic>;

        expect(
          e['explorer'],
          equals('flutter'),
          reason: 'Every manifest entry must have explorer=="flutter".',
        );

        final path = e['path'] as String;
        expect(
          path,
          startsWith('/flutter/#/story/'),
          reason:
              'Every manifest path must start with /flutter/#/story/ '
              '(hash-URL contract from TRD 38-03). Got: $path',
        );
      }
    },
  );
}

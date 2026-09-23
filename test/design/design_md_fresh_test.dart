// test/design/design_md_fresh_test.dart
//
// Staleness gate for DESIGN.md's generated token block (23-10). Regenerates
// the block IN MEMORY from lib/src/tokens/ and compares against the committed
// DESIGN.md — it never writes. A stale doc (edited by hand) or an added token
// (Dart edited without regeneration) both fail this test, by name, with the
// regeneration command in the message.
//
// See tool/gen_design_md.dart for the generator this mirrors.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../tool/gen_design_md.dart';

/// Resolves the eden_ui_flutter package root from the CURRENT working
/// directory rather than a hardcoded absolute path
/// (`edenbiz-website-tests-gated-on-absolute-paths`), asserting the
/// resolution up front with a clear message.
String _repoRoot() {
  final root = Directory.current.path;
  final pubspec = File('$root/pubspec.yaml');
  if (!pubspec.existsSync()) {
    fail('design_md_fresh_test: expected to run from the eden_ui_flutter '
        'package root (pubspec.yaml not found under Directory.current='
        '"$root"). Run `flutter test` from the package root.');
  }
  return root;
}

/// Splits [designMd] into (before, block, after) at the marker span, so tests
/// can inspect the prose independently of the generated block.
(String, String, String) _splitAtMarkers(String designMd) {
  final beginIdx = designMd.indexOf(kBeginMarker);
  final endMarkerIdx = designMd.indexOf(kEndMarker, beginIdx);
  final endIdx = endMarkerIdx + kEndMarker.length;
  return (
    designMd.substring(0, beginIdx),
    designMd.substring(beginIdx, endIdx),
    designMd.substring(endIdx),
  );
}

void main() {
  test(
      'DESIGN.md token block matches lib/src/tokens/ '
      '(cases 5 & 6: staleness fails from either direction)', () {
    final root = _repoRoot();
    final designMdFile = File('$root/DESIGN.md');
    final existing = designMdFile.readAsStringSync();

    final freshBlock = generateTokenBlock(root);
    final expectedFull = spliceIntoMarkers(existing, freshBlock);

    if (expectedFull != existing) {
      final expectedLines = expectedFull.split('\n');
      final existingLines = existing.split('\n');
      var i = 0;
      while (i < expectedLines.length &&
          i < existingLines.length &&
          expectedLines[i] == existingLines[i]) {
        i++;
      }
      fail("DESIGN.md's token block is stale.\n"
          '  first difference: line ${i + 1}\n'
          '  expected: ${i < expectedLines.length ? expectedLines[i] : '<EOF>'}\n'
          '  found:    ${i < existingLines.length ? existingLines[i] : '<EOF>'}\n'
          'Regenerate with: flutter test tool/gen_design_md.dart');
    }
  });

  test('case 7: the prose outside the markers is preserved by regeneration',
      () {
    final root = _repoRoot();
    final designMdFile = File('$root/DESIGN.md');
    final existing = designMdFile.readAsStringSync();

    final (beforeBefore, _, beforeAfter) = _splitAtMarkers(existing);

    final freshBlock = generateTokenBlock(root);
    final regenerated = spliceIntoMarkers(existing, freshBlock);
    final (afterBefore, _, afterAfter) = _splitAtMarkers(regenerated);

    expect(afterBefore, beforeBefore,
        reason: 'prose before the BEGIN marker must be byte-identical');
    expect(afterAfter, beforeAfter,
        reason: 'prose after the END marker must be byte-identical');
  });

  test('case 8: the test does not write DESIGN.md', () {
    final root = _repoRoot();
    // Run the same regenerate+compare the main test does, then assert the
    // working tree is untouched — the freshness check must never write.
    final designMdFile = File('$root/DESIGN.md');
    final existing = designMdFile.readAsStringSync();
    final freshBlock = generateTokenBlock(root);
    spliceIntoMarkers(existing, freshBlock); // computed, never written

    final result = Process.runSync(
      'git',
      ['status', '--short', 'DESIGN.md'],
      workingDirectory: root,
    );
    expect(result.exitCode, 0, reason: 'git status must succeed');
    expect((result.stdout as String).trim(), isEmpty,
        reason: 'DESIGN.md must be clean after the freshness test runs — '
            'it compares, it never writes');
  });
}

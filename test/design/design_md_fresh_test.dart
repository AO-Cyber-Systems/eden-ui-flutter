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

  // ---------------------------------------------------------------------------
  // Token-file COVERAGE, which the freshness test above cannot see.
  //
  // Everything above regenerates from `kScannedTokenFiles` and compares. That
  // proves the four listed files are documented and current. It says nothing
  // about a FIFTH file, because a file the generator never opens cannot make
  // the output stale — so the gate stays green and the header's promise
  // ("generated straight from lib/src/tokens/*.dart so it can never quietly
  // drift from the code") quietly stops being true. That is exactly what
  // happened: `glyph_ink.dart` landed as a new public token file in #55 with
  // this suite green and no row anywhere (eden-ui-flutter#58 review).
  //
  // The rule below closes it by making the DECISION mandatory rather than the
  // documentation: every file in the directory is either scanned or listed as
  // deliberately unscanned WITH a reason. Adding a token file and skipping
  // that choice is the failure.
  // ---------------------------------------------------------------------------
  group('token-file coverage', () {
    test(
        'kScannedTokenFiles and kUnscannedTokenFiles are a closed partition of '
        'lib/src/tokens/', () {
      final root = _repoRoot();
      final tokensDir = Directory('$root/lib/src/tokens');
      // RECURSIVE (eden-ui-flutter#58 second follow-up review, lower-9):
      // `listSync()` defaults to non-recursive, so a file in a SUBDIRECTORY
      // of lib/src/tokens/ escaped this partition in BOTH directions — it
      // was neither scanned by the generator (which also only walks the
      // directory it is pointed at) nor named on the unscanned list, and
      // this gate stayed green regardless. `recursive: true`, with each
      // path made relative to the REPO ROOT (not just the file name, which
      // would collapse `foo/bar.dart` and a top-level `bar.dart` into the
      // same partition key) so it still matches the flat
      // `lib/src/tokens/<file>.dart` strings kScannedTokenFiles and
      // kUnscannedTokenFiles use today.
      final String tokensRoot = tokensDir.path.replaceAll(r'\', '/');
      final onDisk = tokensDir
          .listSync(recursive: true, followLinks: false)
          .whereType<File>()
          .map((f) => f.path.replaceAll(r'\', '/'))
          .where((p) => p.endsWith('.dart'))
          .map((p) {
            var rel = p.substring(tokensRoot.length);
            if (rel.startsWith('/')) rel = rel.substring(1);
            return 'lib/src/tokens/$rel';
          })
          .toSet();

      expect(onDisk, isNotEmpty,
          reason: 'lib/src/tokens/ resolved to nothing — if this directory '
              'moved, this whole gate is vacuous and the partition below '
              'would pass trivially');

      final scanned = kScannedTokenFiles.map((e) => e.$1).toSet();
      final unscanned = kUnscannedTokenFiles.keys.toSet();

      final overlap = scanned.intersection(unscanned);
      expect(overlap, isEmpty,
          reason: 'a token file is listed as BOTH scanned and unscanned: '
              '$overlap');

      final accounted = scanned.union(unscanned);

      final undecided = onDisk.difference(accounted);
      expect(undecided, isEmpty,
          reason: 'new token file(s) with no decision recorded: $undecided\n'
              'A file the generator does not read cannot make DESIGN.md '
              'stale, so the freshness test above will NOT catch this.\n'
              'Either add it to kScannedTokenFiles (and regenerate DESIGN.md '
              'with `dart run tool/gen_design_md.dart`), or add it to '
              'kUnscannedTokenFiles with the reason it is out of scope.');

      final ghosts = accounted.difference(onDisk);
      expect(ghosts, isEmpty,
          reason: 'token file(s) listed but not on disk: $ghosts — renamed '
              'or deleted without updating gen_design_md.dart');
    });

    test('every unscanned entry carries a real reason, not a placeholder', () {
      for (final entry in kUnscannedTokenFiles.entries) {
        expect(entry.value.trim().length, greaterThanOrEqualTo(40),
            reason: '${entry.key} is excluded with a reason too short to '
                'describe a mechanism. "TODO"/"n/a" is how an exclusion '
                'outlives the thing that justified it.');
      }
    });
  });
}

import 'dart:io';

import 'package:eden_lints/eden_lints.dart';
import 'package:test/test.dart';

/// The wave-1 enforced scope, mirroring `analysis_options.yaml`.
const List<String> kShellScope = <String>['lib/src/widgets/eden_layout/**'];

/// A file inside that scope.
const String kInScopePath = 'lib/src/widgets/eden_layout/eden_shell.dart';

/// A file outside it -- a widget, but not a shell widget.
const String kOutOfScopePath = 'lib/src/widgets/eden_button.dart';

/// Where raw colours, raw sizes and raw spacing BELONG.
const String kTokensPath = 'lib/src/tokens/colors.dart';

/// Everything, used only to isolate the tokens exemption from the scope check.
const List<String> kWholeLib = <String>['lib/**'];

String fixture(String name) =>
    File('test/fixtures/$name').readAsStringSync();

/// Lines carrying a trailing `// EXPECT: <rule>` marker.
///
/// Hand-placed in the fixture next to the offending expression, so the test
/// asserts real line numbers without a second hand-maintained list that can
/// drift away from the file it describes.
List<int> expectedLines(String source, String rule) {
  final lines = source.split('\n');
  final out = <int>[];
  for (var i = 0; i < lines.length; i++) {
    if (lines[i].contains('// EXPECT: $rule')) out.add(i + 1);
  }
  return out;
}

List<EdenLintHit> run(
  String fixtureName,
  String rule, {
  required String path,
  required List<String> scope,
}) =>
    scanSource(
      source: fixture(fixtureName),
      path: path,
      enforcedPaths: scope,
      rules: <String>{rule},
    );

void main() {
  group('no_raw_color', () {
    test('case 1: fires on a raw Color literal under an enforced path, '
        'naming the rule and the line', () {
      final source = fixture('no_raw_color_fires.dart');
      final marked = expectedLines(source, kNoRawColor);
      expect(marked, hasLength(2),
          reason: 'fixture must carry two EXPECT markers');

      final hits = run('no_raw_color_fires.dart', kNoRawColor,
          path: kInScopePath, scope: kShellScope);

      expect(hits.map((h) => h.line).toList(), marked);
      expect(hits.every((h) => h.rule == kNoRawColor), isTrue);
      expect(hits.first.message, contains('Color'));
    });

    test('case 2: does NOT fire on EdenColors tokens in the same file', () {
      final hits = run('no_raw_color_quiet.dart', kNoRawColor,
          path: kInScopePath, scope: kShellScope);
      expect(hits, isEmpty, reason: hits.join('\n'));
    });

    test('case 3: does NOT fire inside lib/src/tokens/ -- raw colours belong '
        'there', () {
      final hits = run('no_raw_color_fires.dart', kNoRawColor,
          path: kTokensPath, scope: kWholeLib);
      expect(hits, isEmpty, reason: hits.join('\n'));
    });

    test('case 4: does NOT fire outside the enforced paths', () {
      final hits = run('no_raw_color_fires.dart', kNoRawColor,
          path: kOutOfScopePath, scope: kShellScope);
      expect(hits, isEmpty, reason: hits.join('\n'));
    });
  });

  group('text_style_needs_family', () {
    test('case 5: fires on a TextStyle with no fontFamily under an enforced '
        'path', () {
      final source = fixture('text_style_fires.dart');
      final marked = expectedLines(source, kTextStyleNeedsFamily);
      expect(marked, hasLength(2));

      final hits = run('text_style_fires.dart', kTextStyleNeedsFamily,
          path: kInScopePath, scope: kShellScope);

      expect(hits.map((h) => h.line).toList(), marked);
      expect(hits.every((h) => h.rule == kTextStyleNeedsFamily), isTrue);
      expect(hits.first.message, contains('fontFamily'));
    });

    test('case 6: does NOT fire when fontFamily is named', () {
      final hits = run('text_style_quiet.dart', kTextStyleNeedsFamily,
          path: kInScopePath, scope: kShellScope);
      expect(hits, isEmpty, reason: hits.join('\n'));
    });

    test('case 7: does NOT fire inside lib/src/tokens/', () {
      final hits = run('text_style_fires.dart', kTextStyleNeedsFamily,
          path: kTokensPath, scope: kWholeLib);
      expect(hits, isEmpty, reason: hits.join('\n'));
    });
  });

  group('no_magic_spacing', () {
    test('case 8: fires on EdgeInsets.all(13) and SizedBox(height: 13) under '
        'an enforced path', () {
      final source = fixture('magic_spacing_fires.dart');
      final marked = expectedLines(source, kNoMagicSpacing);
      expect(marked, hasLength(3));

      final hits = run('magic_spacing_fires.dart', kNoMagicSpacing,
          path: kInScopePath, scope: kShellScope);

      expect(hits.map((h) => h.line).toList(), marked);
      expect(hits.every((h) => h.rule == kNoMagicSpacing), isTrue);
      expect(hits.first.message, contains('spacing'));
    });

    test('case 9: does NOT fire on EdgeInsets.all(EdenSpacing.md)', () {
      final hits = run('magic_spacing_quiet.dart', kNoMagicSpacing,
          path: kInScopePath, scope: kShellScope);
      expect(hits, isEmpty, reason: hits.join('\n'));
    });

    test('case 10: does NOT fire inside lib/src/tokens/', () {
      final hits = run('magic_spacing_fires.dart', kNoMagicSpacing,
          path: kTokensPath, scope: kWholeLib);
      expect(hits, isEmpty, reason: hits.join('\n'));
    });
  });
}

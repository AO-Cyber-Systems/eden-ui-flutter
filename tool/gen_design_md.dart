// tool/gen_design_md.dart
//
// Generates the token block of DESIGN.md from lib/src/tokens/*.dart (23-10 /
// PROPOSAL §5). DESIGN.md is otherwise hand-written prose; only the region
// between the BEGIN/END markers below is owned by this tool.
//
// SCHEMA IS LOCKED: this tool documents exactly four token groups — Colors,
// Type scale, Spacing, Radii — scoped to row 1a-10. `shadows.dart` and
// `springs.dart` hold structured (non-scalar) values and are deliberately NOT
// generated; the block ends with a one-line note saying so instead of silently
// omitting them.
//
// Extraction is by a STRICT, asserted shape per group (see the `_...Pattern`
// RegExps below) — a declaration inside the scanned class that does not match
// any accepted or explicitly-named "skip" shape raises
// UnrecognizedTokenDeclaration naming the file and line, rather than being
// silently dropped. This is deliberate: a stale/unnoticed token is exactly the
// bug row 1a-10 removes.
//
// Each source file is scanned ONLY inside its single named "token class" body
// (EdenColors / EdenSpacing / EdenRadii / EdenTypography), found by a simple
// column-0-brace heuristic that matches this repo's dartfmt output. Other
// classes bundled in the same file (`AOHealthGradients`, `AOHealthColors` in
// colors.dart) are app-specific bonus tokens, not shared Eden design tokens,
// and are out of scope for this doc by design — never scanned, so never
// silently skipped.
//
// HOW TO RUN — via the flutter test runner, NOT plain `dart` (same reason as
// tool/emit_flutter_manifest.dart: transitively needs the Flutter engine):
//
//   flutter test tool/gen_design_md.dart
//
// 0-new-deps: dart:io only, plus the already-present flutter_test.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Which documented table a [TokenEntry] belongs to.
enum TokenGroup { colors, typography, spacing, radii }

String _groupHeading(TokenGroup g) {
  switch (g) {
    case TokenGroup.colors:
      return 'Colors';
    case TokenGroup.typography:
      return 'Type scale';
    case TokenGroup.spacing:
      return 'Spacing';
    case TokenGroup.radii:
      return 'Radii';
  }
}

/// One documented design token: a name, its rendered value, and which table it
/// belongs in.
class TokenEntry {
  final String name;
  final String value;
  final TokenGroup group;
  const TokenEntry(
      {required this.name, required this.value, required this.group});

  @override
  bool operator ==(Object other) =>
      other is TokenEntry &&
      other.name == name &&
      other.value == value &&
      other.group == group;

  @override
  int get hashCode => Object.hash(name, value, group);

  @override
  String toString() => 'TokenEntry($group $name=$value)';
}

/// Thrown when a `static` declaration inside a scanned token class body does
/// not match any accepted (or explicitly-named skip) shape for its group.
class UnrecognizedTokenDeclaration implements Exception {
  final String path;
  final int line; // 1-based
  final String text;
  UnrecognizedTokenDeclaration(this.path, this.line, this.text);

  @override
  String toString() => 'UnrecognizedTokenDeclaration: $path:$line does not '
      'match any accepted token shape for this group:\n  $text';
}

// ---------------------------------------------------------------------------
// Accepted shapes
// ---------------------------------------------------------------------------

final RegExp _colorPattern =
    RegExp(r'^\s*static const Color (\w+) = Color\((0x[0-9A-Fa-f]{8})\);');

final RegExp _materialColorStartPattern = RegExp(
    r'^\s*static const MaterialColor (\w+) = MaterialColor\((0x[0-9A-Fa-f]{8}), <int, Color>\{\s*$');

final RegExp _mapSkipStartPattern =
    RegExp(r'^\s*static const Map<String, MaterialColor> \w+ = \{\s*$');

final RegExp _doublePattern =
    RegExp(r'^\s*static const double (\w+) = ([\d.]+);');

final RegExp _borderRadiusSkipPattern = RegExp(
    r'^\s*static final BorderRadius \w+ = BorderRadius\.circular\(\w+\);');

final RegExp _typographyFamilySkipPattern =
    RegExp(r'^\s*static TextStyle get \w+ => GoogleFonts\.\w+\(\);');

final RegExp _typographyScaleStartPattern =
    RegExp(r'^\s*static TextStyle (\w+)\(BuildContext context\) =>\s*$');

final RegExp _typographyScaleBodyPattern = RegExp(
    r'^\s*GoogleFonts\.(\w+)\(fontSize: (\d+), fontWeight: FontWeight\.(\w+), height: ([\d.]+)\);\s*$');

bool _isNonDeclarationLine(String trimmed) =>
    trimmed.isEmpty || trimmed.startsWith('//') || trimmed.startsWith('///');

/// Extracts [TokenEntry] values of [group] from [source] (the FULL contents
/// of one token file, or a minimal hand-built fixture).
///
/// When [className] is given, scanning is restricted to that class's body
/// (from `class $className {` to the closing `}` at column 0) — see file
/// header. When omitted, the whole [source] is scanned as-is; hand-built
/// fixtures in tests rely on this to avoid needing a class wrapper.
///
/// Declaration order within the scanned region is preserved.
List<TokenEntry> extractTokens(
  String source, {
  required String path,
  required TokenGroup group,
}) {
  final allLines = source.split('\n');
  final entries = <TokenEntry>[];

  var i = 0;
  while (i < allLines.length) {
    final rawLine = allLines[i];
    final trimmed = rawLine.trim();
    final lineNumber = i + 1;

    switch (group) {
      case TokenGroup.colors:
        {
          final colorMatch = _colorPattern.firstMatch(rawLine);
          if (colorMatch != null) {
            entries.add(TokenEntry(
                name: colorMatch.group(1)!,
                value: colorMatch.group(2)!,
                group: group));
            i++;
            continue;
          }
          final swatchMatch = _materialColorStartPattern.firstMatch(rawLine);
          if (swatchMatch != null) {
            entries.add(TokenEntry(
                name: swatchMatch.group(1)!,
                value: swatchMatch.group(2)!,
                group: group));
            i = _consumeUntil(allLines, i + 1, '});', path);
            continue;
          }
          if (_mapSkipStartPattern.hasMatch(rawLine)) {
            // `presets` is a derived index over swatches already extracted
            // above — not a new token. Named, documented skip.
            i = _consumeUntil(allLines, i + 1, '};', path);
            continue;
          }
          break;
        }
      case TokenGroup.spacing:
      case TokenGroup.radii:
        {
          final doubleMatch = _doublePattern.firstMatch(rawLine);
          if (doubleMatch != null) {
            entries.add(TokenEntry(
                name: doubleMatch.group(1)!,
                value: doubleMatch.group(2)!,
                group: group));
            i++;
            continue;
          }
          if (_borderRadiusSkipPattern.hasMatch(rawLine)) {
            // Derived helper (BorderRadius.circular(x)) wrapping a base radii
            // value already extracted above — not a new token.
            i++;
            continue;
          }
          break;
        }
      case TokenGroup.typography:
        {
          if (_typographyFamilySkipPattern.hasMatch(rawLine)) {
            // Font-family exposure only (no size) — not part of the type
            // SCALE. Named, documented skip.
            i++;
            continue;
          }
          final startMatch = _typographyScaleStartPattern.firstMatch(rawLine);
          if (startMatch != null && i + 1 < allLines.length) {
            final bodyMatch =
                _typographyScaleBodyPattern.firstMatch(allLines[i + 1]);
            if (bodyMatch != null) {
              final font = bodyMatch.group(1)!;
              final size = bodyMatch.group(2)!;
              final weight = bodyMatch.group(3)!;
              final height = bodyMatch.group(4)!;
              entries.add(TokenEntry(
                  name: startMatch.group(1)!,
                  value: '${size}px, $weight, line-height $height '
                      '(${_capitalize(font)})',
                  group: group));
              i += 2;
              continue;
            }
          }
          break;
        }
    }

    if (_isNonDeclarationLine(trimmed)) {
      i++;
      continue;
    }
    if (trimmed.startsWith('static')) {
      throw UnrecognizedTokenDeclaration(path, lineNumber, trimmed);
    }
    i++;
  }

  return entries;
}

String _capitalize(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

/// Advances past lines until (and including) the first line whose trimmed
/// content equals [closer]; throws if the file ends first (an unterminated
/// block is itself a shape violation worth failing loudly on).
int _consumeUntil(List<String> lines, int start, String closer, String path) {
  var i = start;
  while (i < lines.length) {
    if (lines[i].trim() == closer) {
      return i + 1;
    }
    i++;
  }
  throw UnrecognizedTokenDeclaration(
      path, start + 1, 'unterminated block (expected a line "$closer")');
}

/// Restricts [source] to the body of the top-level class named [className]
/// (from `class $className {` to the closing `}` at column 0), exclusive of
/// both boundary lines. Throws [StateError] if the class or its close cannot
/// be found — a clear signal rather than silently scanning the whole file.
String classBody(String source, String className) {
  final lines = source.split('\n');
  final startPattern = RegExp('^class $className\\b');
  var start = -1;
  for (var i = 0; i < lines.length; i++) {
    if (startPattern.hasMatch(lines[i])) {
      start = i;
      break;
    }
  }
  if (start == -1) {
    throw StateError('gen_design_md: class $className not found in source');
  }
  var end = -1;
  for (var i = start + 1; i < lines.length; i++) {
    if (lines[i] == '}') {
      end = i;
      break;
    }
  }
  if (end == -1) {
    throw StateError(
        'gen_design_md: closing brace for class $className not found');
  }
  return lines.sublist(start + 1, end).join('\n');
}

// ---------------------------------------------------------------------------
// Rendering
// ---------------------------------------------------------------------------

const String kBeginMarker =
    '<!-- BEGIN GENERATED TOKENS — do not edit by hand; run: flutter test tool/gen_design_md.dart -->';
const String kEndMarker = '<!-- END GENERATED TOKENS -->';

/// Renders [tokens] into the full marker-bounded block (markers included).
/// Pure and stable: the same input list renders to byte-identical markdown
/// every time (no dependency on wall-clock time, map iteration order, etc).
String renderTokenBlock(List<TokenEntry> tokens) {
  final buffer = StringBuffer()
    ..writeln(kBeginMarker)
    ..writeln();

  for (final group in TokenGroup.values) {
    final rows = tokens.where((t) => t.group == group).toList();
    if (rows.isEmpty) continue;
    buffer
      ..writeln('## ${_groupHeading(group)}')
      ..writeln()
      ..writeln('| Token | Value |')
      ..writeln('|---|---|');
    for (final row in rows) {
      buffer.writeln('| `${row.name}` | `${row.value}` |');
    }
    buffer.writeln();
  }

  buffer
    ..writeln('_Not generated: shadows, springs (structured values)._')
    ..writeln()
    ..write(kEndMarker);

  return buffer.toString();
}

/// Thrown by [spliceIntoMarkers] when either marker is missing from the
/// target markdown — the generator refuses to append or rewrite from scratch.
class MissingTokenMarkersError extends StateError {
  MissingTokenMarkersError(String which)
      : super('DESIGN.md is missing the $which marker — add both markers by '
            'hand first; the generator never appends or rewrites the whole '
            'file.');
}

/// Replaces the marker-bounded span in [existingMarkdown] with [block]
/// (which itself starts with [kBeginMarker] and ends with [kEndMarker]).
/// Prose before/after the span is untouched. Throws [MissingTokenMarkersError]
/// if either marker is absent — never falls back to appending.
String spliceIntoMarkers(String existingMarkdown, String block) {
  final beginIdx = existingMarkdown.indexOf(kBeginMarker);
  if (beginIdx == -1) {
    throw MissingTokenMarkersError('BEGIN GENERATED TOKENS');
  }
  final endMarkerIdx = existingMarkdown.indexOf(kEndMarker, beginIdx);
  if (endMarkerIdx == -1) {
    throw MissingTokenMarkersError('END GENERATED TOKENS');
  }
  final endIdx = endMarkerIdx + kEndMarker.length;
  return existingMarkdown.substring(0, beginIdx) +
      block +
      existingMarkdown.substring(endIdx);
}

// ---------------------------------------------------------------------------
// Whole-repo generation (shared by main() and the freshness test)
// ---------------------------------------------------------------------------

/// The four (path, class, group) inputs generation is scoped to for row
/// 1a-10. `durations.dart`, `shadows.dart` and `springs.dart` are not read at
/// all (see file header).
const List<(String, String, TokenGroup)> kScannedTokenFiles = [
  ('lib/src/tokens/colors.dart', 'EdenColors', TokenGroup.colors),
  ('lib/src/tokens/typography.dart', 'EdenTypography', TokenGroup.typography),
  ('lib/src/tokens/spacing.dart', 'EdenSpacing', TokenGroup.spacing),
  ('lib/src/tokens/radii.dart', 'EdenRadii', TokenGroup.radii),
];

/// Every `lib/src/tokens/*.dart` this generator DOES NOT read, each with the
/// reason it is out of scope.
///
/// WHY A LIST AND NOT A GLOB. DESIGN.md's header promises the token
/// reference is generated from `lib/src/tokens/*.dart` "so it can never
/// quietly drift from the code". [kScannedTokenFiles] is four hardcoded
/// paths, so the promise was only true of those four: `glyph_ink.dart`
/// landed as a new PUBLIC token file in eden-ui-flutter#55 and the freshness
/// gate stayed green with no documentation row for it, because a file the
/// generator never looks at cannot make the output stale. That is the same
/// failure shape the gate exists to prevent.
///
/// Globbing the directory is NOT the fix. [TokenGroup] is a closed enum of
/// four, `extractTokens` switches exhaustively over it, and an unmatched
/// declaration raises `UnrecognizedTokenDeclaration` — so a glob throws on
/// the first run for four of the eight files here. `EdenGlyphInk`'s members
/// are `static Color success(Brightness)` METHODS, which no token pattern
/// matches anyway.
///
/// So coverage is ASSERTED instead of derived: this list and
/// [kScannedTokenFiles] must together account for every file in the
/// directory, exactly once. Adding a token file and not deciding which side
/// it belongs on is what fails, which is the decision that was skipped
/// before. `design_md_fresh_test.dart` holds the partition.
const Map<String, String> kUnscannedTokenFiles = {
  'lib/src/tokens/durations.dart':
      'Motion durations. Not a visual token with a renderable value — a row '
          'reading "160ms" documents nothing a designer can check against a '
          'rendered surface.',
  'lib/src/tokens/shadows.dart':
      'Elevation shadows. Multi-part BoxShadow lists; the single-value row '
          'shape this generator emits cannot represent one without lying '
          'about it.',
  'lib/src/tokens/springs.dart':
      'Spring curves. Same reason as durations — a physics constant is not '
          'a swatch.',
  'lib/src/tokens/glyph_ink.dart':
      'Semantic glyph ink (eden-ui-flutter#55). Deliberately excluded: its '
          'members are METHODS taking a Brightness, not constants, so there '
          'is no single value to tabulate — each tone is a PAIR, and which '
          'one applies depends on the theme. Its contrast ratios are '
          'documented in the class dartdoc and pinned by '
          'test/ui_oracle/, which measures them on rendered frames rather '
          'than restating them in a table nothing checks.',
};

/// Regenerates the full marker-bounded token block by reading the current
/// `lib/src/tokens/*.dart` files under [repoRoot]. Pure with respect to
/// DESIGN.md — this never touches the markdown file, only the token sources.
String generateTokenBlock(String repoRoot) {
  final tokens = <TokenEntry>[];
  for (final (relPath, className, group) in kScannedTokenFiles) {
    final file = File('$repoRoot/$relPath');
    if (!file.existsSync()) {
      throw StateError(
          'gen_design_md: expected token file not found at ${file.path} — '
          'resolved from repoRoot="$repoRoot"; run flutter test from the '
          'package root.');
    }
    final source = file.readAsStringSync();
    final scoped = classBody(source, className);
    tokens.addAll(extractTokens(scoped, path: relPath, group: group));
  }
  return renderTokenBlock(tokens);
}

void main() {
  // Wrapped in a single test() so `flutter test tool/gen_design_md.dart`
  // exits 0 (see tool/emit_flutter_manifest.dart for why a bare main() would
  // not). The body performs the write; it is the generator, not an
  // assertion-only test.
  test('generate DESIGN.md token block', () {
    final repoRoot = Directory.current.path;
    final designMdPath = '$repoRoot/DESIGN.md';
    final designMdFile = File(designMdPath);
    if (!designMdFile.existsSync()) {
      fail('gen_design_md: DESIGN.md not found at $designMdPath — resolved '
          'from Directory.current="$repoRoot"; run `flutter test '
          'tool/gen_design_md.dart` from the eden_ui_flutter package root.');
    }
    final block = generateTokenBlock(repoRoot);
    final updated =
        spliceIntoMarkers(designMdFile.readAsStringSync(), block);
    designMdFile.writeAsStringSync(updated);
    stdout.writeln('gen_design_md: wrote token block → $designMdPath');
    expect(block, contains(kBeginMarker));
  });
}

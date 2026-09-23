// test/tool/gen_design_md_test.dart
//
// Unit tests for the pure extract/render/splice core of tool/gen_design_md.dart
// (23-10). Hand-built fixtures only — no generated/LLM-invented token lists.
//
// These test the PRIMITIVES in isolation with minimal hand-written source
// snippets; test/design/design_md_fresh_test.dart separately proves the whole
// pipeline stays in sync with the real lib/src/tokens/ files.

import 'package:flutter_test/flutter_test.dart';

import '../../tool/gen_design_md.dart';

void main() {
  test('case 1: extracts static const Color declarations in declaration order',
      () {
    const source = '''
  static const Color primary = Color(0xFFD4A853);
  static const Color secondary = Color(0xFF3B82F6);
  static const Color tertiary = Color(0xFF10B981);
''';

    final tokens = extractTokens(source,
        path: 'fixture.dart', group: TokenGroup.colors);

    expect(tokens.map((t) => t.name).toList(),
        ['primary', 'secondary', 'tertiary']);
    expect(tokens.map((t) => t.value).toList(),
        ['0xFFD4A853', '0xFF3B82F6', '0xFF10B981']);
    expect(tokens.every((t) => t.group == TokenGroup.colors), isTrue);
  });

  test(
      'case 2: an unmatched declaration raises a named error carrying file and line',
      () {
    const source = '''
  static const Color primary = Color(0xFFD4A853);
  static const int notAToken = 5;
''';

    expect(
      () => extractTokens(source,
          path: 'lib/src/tokens/fixture.dart', group: TokenGroup.colors),
      throwsA(
        isA<UnrecognizedTokenDeclaration>()
            .having((e) => e.path, 'path', 'lib/src/tokens/fixture.dart')
            .having((e) => e.line, 'line', 2)
            .having((e) => e.text, 'text', contains('notAToken')),
      ),
    );
  });

  test('case 3: rendering the same tokens twice is byte-identical (stability)',
      () {
    const tokens = [
      TokenEntry(name: 'primary', value: '0xFFD4A853', group: TokenGroup.colors),
      TokenEntry(name: 'space1', value: '4', group: TokenGroup.spacing),
    ];

    final first = renderTokenBlock(tokens);
    final second = renderTokenBlock(tokens);

    expect(first, second);
  });

  test('case 4: the rendered block is bounded by the exact markers and '
      'contains nothing outside them', () {
    const tokens = [
      TokenEntry(name: 'primary', value: '0xFFD4A853', group: TokenGroup.colors),
    ];

    final block = renderTokenBlock(tokens);

    expect(block.startsWith(kBeginMarker), isTrue,
        reason: 'block must start with the exact BEGIN marker');
    expect(block.endsWith(kEndMarker), isTrue,
        reason: 'block must end with the exact END marker');
    expect(
        kBeginMarker,
        '<!-- BEGIN GENERATED TOKENS — do not edit by hand; '
        'run: flutter test tool/gen_design_md.dart -->');
    expect(kEndMarker, '<!-- END GENERATED TOKENS -->');
  });

  test('spliceIntoMarkers replaces only the marker-bounded span', () {
    const existing = 'prose before\n'
        '$kBeginMarker\nold block\n$kEndMarker\n'
        'prose after';
    const newBlock = '$kBeginMarker\nnew block\n$kEndMarker';

    final result = spliceIntoMarkers(existing, newBlock);

    expect(result, 'prose before\n$newBlock\nprose after');
  });

  test('spliceIntoMarkers throws MissingTokenMarkersError when a marker is absent',
      () {
    expect(
      () => spliceIntoMarkers('no markers here', '$kBeginMarker\nx\n$kEndMarker'),
      throwsA(isA<MissingTokenMarkersError>()),
    );
  });
}

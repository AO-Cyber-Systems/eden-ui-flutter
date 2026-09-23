// tool/gen_stories.dart
//
// Discovers co-located `<widget>.stories.dart` files under `lib/` and emits
// `lib/dev_app/registry/register_stories.g.dart` — the FIFTH registration
// group, called by `registerAllStories()` after the four hand-written groups.
//
// HOW TO RUN — via the flutter test runner, NOT plain `dart`:
//
//   flutter test tool/gen_stories.dart
//
// (The story registry transitively imports package:flutter/material.dart, so a
// bare `dart run` fails to resolve dart:ui. Wrapping the write in a single
// test() also gives a clean exit 0 — a plain main() reports "No tests ran".)
//
// CONTRACT a co-located story file must honour, asserted by discovery:
//   * the file is named `<snake_name>.stories.dart`
//   * it declares a top-level `List<EdenStory> <camelName>Stories`
// A file that does not is a StoryFileContractError naming the path — a clear
// error beats a regex that silently skips the file.
//
// DETERMINISM: discovery sorts by path and generation sorts by import path, so
// filesystem iteration order can never leak into the committed bytes. The
// drift test (test/stories/registry_drift_test.dart) compares the committed
// bytes to a fresh generation, so an unstable generator would be a random CI
// failure.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Path (relative to the package root) of the file this tool writes.
const String kGeneratedRegistrationPath =
    'lib/dev_app/registry/register_stories.g.dart';

/// The command that regenerates [kGeneratedRegistrationPath]. Quoted verbatim
/// in the drift test's failure message so the remedy is in the log.
const String kRegenerateCommand = 'flutter test tool/gen_stories.dart';

/// One discovered co-located story file.
class StoryFile {
  const StoryFile({required this.importPath, required this.symbol});

  /// Import URI as written INSIDE `lib/dev_app/registry/` — i.e. relative to
  /// that directory, which sits two levels below `lib/`.
  final String importPath;

  /// The `List<EdenStory>` symbol the file must export, e.g.
  /// `edenNavItemStories`.
  final String symbol;

  @override
  String toString() => 'StoryFile($importPath -> $symbol)';
}

/// Thrown when a discovered `*.stories.dart` file does not declare the
/// `List<EdenStory> <name>Stories` symbol the generator registers.
class StoryFileContractError implements Exception {
  const StoryFileContractError(this.path, this.expectedSymbol);

  final String path;
  final String expectedSymbol;

  @override
  String toString() =>
      'StoryFileContractError: $path does not declare a top-level '
      '`List<EdenStory> $expectedSymbol`. Every co-located story file must '
      'export a list named after the file so tool/gen_stories.dart can '
      'register it. Add it, then run: $kRegenerateCommand';
}

/// `eden_nav_item.stories.dart` -> `edenNavItemStories`.
String storySymbolForFileName(String fileName) {
  final base = fileName.replaceAll('.stories.dart', '');
  final parts = base.split('_').where((p) => p.isNotEmpty).toList();
  if (parts.isEmpty) return 'Stories';
  final buffer = StringBuffer(parts.first);
  for (final part in parts.skip(1)) {
    buffer.write(part[0].toUpperCase());
    buffer.write(part.substring(1));
  }
  buffer.write('Stories');
  return buffer.toString();
}

/// Builds a [StoryFile] from a path relative to `lib/`, e.g.
/// `src/widgets/eden_layout/eden_nav_item.stories.dart`.
///
/// The generated file lives at `lib/dev_app/registry/`, two directories below
/// `lib/`, so the emitted import is prefixed `../../`.
StoryFile storyFileFromRelativePath(String relativeToLib) {
  final normalized = relativeToLib.replaceAll(r'\', '/');
  final fileName = normalized.split('/').last;
  return StoryFile(
    importPath: '../../$normalized',
    symbol: storySymbolForFileName(fileName),
  );
}

/// Walks [libDir] for `*.stories.dart` files, asserts each honours the
/// contract, and returns them sorted by import path.
///
/// Throws [StoryFileContractError] for the FIRST non-conforming file, in sorted
/// order, so the error is deterministic too.
List<StoryFile> discoverStoryFiles(Directory libDir) {
  if (!libDir.existsSync()) return const [];

  final rootPath = libDir.path.replaceAll(r'\', '/');
  final paths = <String>[];
  for (final entity in libDir.listSync(recursive: true, followLinks: false)) {
    if (entity is! File) continue;
    final p = entity.path.replaceAll(r'\', '/');
    if (!p.endsWith('.stories.dart')) continue;
    var rel = p.substring(rootPath.length);
    if (rel.startsWith('/')) rel = rel.substring(1);
    paths.add(rel);
  }
  paths.sort();

  final files = <StoryFile>[];
  for (final rel in paths) {
    final storyFile = storyFileFromRelativePath(rel);
    final source = File('$rootPath/$rel').readAsStringSync();
    final declares =
        RegExp('List<EdenStory>\\s+${storyFile.symbol}\\b').hasMatch(source);
    if (!declares) {
      throw StoryFileContractError(rel, storyFile.symbol);
    }
    files.add(storyFile);
  }
  return files;
}

/// PURE. Emits the source of [kGeneratedRegistrationPath] for [files].
///
/// Sorted by import path, fixed header, trailing newline. With zero story files
/// the emitted body registers nothing AND imports nothing — an unused import or
/// an unused `registry` local would be an analyzer finding on a committed file.
String generateRegistrationSource(List<StoryFile> files) {
  final sorted = [...files]..sort((a, b) => a.importPath.compareTo(b.importPath));

  final b = StringBuffer()
    ..writeln('// GENERATED by tool/gen_stories.dart — DO NOT EDIT.')
    ..writeln('// Regenerate: $kRegenerateCommand')
    ..writeln('//')
    ..writeln(
        '// Registration for co-located `<widget>.stories.dart` files. This is the')
    ..writeln(
        '// FIFTH story group; the four hand-written groups in register_all.dart are')
    ..writeln('// untouched by this generator.')
    ..writeln(
        '// Drift between this file and a fresh generation fails test/stories/registry_drift_test.dart.');

  if (sorted.isEmpty) {
    b
      ..writeln()
      ..writeln('void registerGeneratedStories() {')
      ..writeln(
          '  // no co-located `<widget>.stories.dart` files discovered under lib/ yet.')
      ..writeln('}');
    return b.toString();
  }

  b
    ..writeln()
    ..writeln("import 'story_registry.dart';");
  for (final f in sorted) {
    b.writeln("import '${f.importPath}';");
  }
  b
    ..writeln()
    ..writeln('void registerGeneratedStories() {')
    ..writeln('  final registry = StoryRegistry.instance;');
  for (final f in sorted) {
    b
      ..writeln('  for (final s in ${f.symbol}) {')
      ..writeln('    registry.register(s);')
      ..writeln('  }');
  }
  b.writeln('}');
  return b.toString();
}

void main() {
  test('generate lib/dev_app/registry/register_stories.g.dart', () {
    final files = discoverStoryFiles(Directory('lib'));
    final source = generateRegistrationSource(files);
    File(kGeneratedRegistrationPath).writeAsStringSync(source);
    stdout.writeln(
        'gen_stories: wrote ${files.length} co-located story file(s) → '
        '$kGeneratedRegistrationPath');
    expect(source, endsWith('\n'));
  });
}

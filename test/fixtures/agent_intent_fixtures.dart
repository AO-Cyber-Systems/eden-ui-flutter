// Loader for the vendored eden-biz agent-intent recordings.
//
// These 14 files are a byte-identical copy of
// `go/internal/agentintent/testdata/` on eden-biz `origin/main`. They are the
// SINGLE SOURCE for every decoder and dispatcher test in this layer: a test
// written against an invented payload proves the decoder agrees with
// whoever invented it, which is nobody.
//
// `fixture_set_integrity_test.dart` is the gate that keeps this copy honest.
// Read its header before changing anything here.
library;

import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';

/// Where the recordings live, relative to the package root.
///
/// `flutter test` runs with the package root as its working directory, the
/// same assumption `golden_uniqueness_test.dart` makes of
/// `test/stories/_generated/goldens/ci`.
const String kAgentIntentFixtureDir = 'test/fixtures/agentintent';

/// eden-biz `origin/main`'s `manifest.json` `set_sha256`, pinned.
///
/// Verified against eden-biz on 2026-10-08. This is the value that makes the
/// copy falsifiable; see case 4 of the integrity test for why it is a
/// SECOND assertion rather than a replacement for comparing against the
/// vendored manifest.
const String kAgentIntentFixtureSetSha256 =
    '9c4520d9e07e54fe29d0a19016bbac3b6c91d271159985d57dd201a2bd508fd2';

Directory get _dir {
  final Directory d = Directory(kAgentIntentFixtureDir);
  if (!d.existsSync()) {
    // A MISSING DIRECTORY IS A FAILURE, NEVER AN EMPTY SET. Returning no
    // fixtures would make every `for (name in names)` test pass by covering
    // nothing — an unmeasurable state that reads as green is how a gate
    // dies.
    throw StateError(
      'agent-intent fixtures: $kAgentIntentFixtureDir does not exist. '
      'Tests that iterate the set would otherwise pass over zero files. '
      'Re-vendor from eden-biz origin/main '
      'go/internal/agentintent/testdata/.',
    );
  }
  return d;
}

/// The recording file names, sorted bytewise, EXCLUDING `manifest.json`.
///
/// Bytewise (`compareTo` on the raw string) rather than locale-aware,
/// because the manifest's recipe says `LC_ALL=C` and the hash depends on it.
List<String> agentIntentFixtureNames() {
  final List<String> names = _dir
      .listSync()
      .whereType<File>()
      .map((File f) => f.uri.pathSegments.last)
      .where((String n) => n.endsWith('.json') && n != 'manifest.json')
      .toList()
    ..sort();
  return names;
}

/// Raw bytes of one recording. The hash is over BYTES, never over a
/// re-encoded parse — a round trip through `jsonDecode`/`jsonEncode` would
/// reorder keys and change the digest.
List<int> readAgentIntentFixtureBytes(String name) =>
    File('$kAgentIntentFixtureDir/$name').readAsBytesSync();

/// One recording, parsed.
///
/// Throws [ArgumentError] naming the miss and listing what is available. A
/// `null` return would let a test with a typo'd filename assert nothing and
/// still report green.
Map<String, dynamic> loadAgentIntentFixture(String name) {
  final File f = File('$kAgentIntentFixtureDir/$name');
  if (!f.existsSync()) {
    throw ArgumentError(
      'no vendored agent-intent recording named "$name". Available:\n'
      '  ${agentIntentFixtureNames().join('\n  ')}',
    );
  }
  return jsonDecode(f.readAsStringSync()) as Map<String, dynamic>;
}

/// `manifest.json`, parsed.
Map<String, dynamic> loadAgentIntentManifest() =>
    jsonDecode(File('$kAgentIntentFixtureDir/manifest.json').readAsStringSync())
        as Map<String, dynamic>;

/// Recompute the set hash by the manifest's own stated recipe.
///
///   *.json except manifest.json, names sorted bytewise (LC_ALL=C), one line
///   per file `"<sha256 hex of the file bytes><two spaces><filename>\n"`,
///   set hash = sha256 hex of the concatenated lines.
///
/// Reimplemented here rather than trusted, because the point of the gate is
/// to reproduce a number another repo's Go code produced.
String computeAgentIntentSetHash() {
  final StringBuffer lines = StringBuffer();
  for (final String name in agentIntentFixtureNames()) {
    final String digest =
        sha256.convert(readAgentIntentFixtureBytes(name)).toString();
    lines.write('$digest  $name\n');
  }
  return sha256.convert(utf8.encode(lines.toString())).toString();
}

/// One recording's `intent` object.
Map<String, dynamic> agentIntentOf(String name) =>
    loadAgentIntentFixture(name)['intent'] as Map<String, dynamic>;

/// A DEEP COPY of a recording's `intent`, for a test that needs a payload no
/// recording contains.
///
/// MUTATION, NOT INVENTION. A malformed payload has to come from somewhere,
/// and starting from the real one keeps every other field honest — only the
/// thing under test differs. Every caller states which recording it mutated
/// and what it changed.
Map<String, dynamic> mutatedIntent(
  String name,
  void Function(Map<String, dynamic> intent) mutate,
) {
  final Map<String, dynamic> copy =
      jsonDecode(jsonEncode(agentIntentOf(name))) as Map<String, dynamic>;
  mutate(copy);
  return copy;
}

// TRD 23-03, case 5 — the registry-drift GATE.
//
// Compares the COMMITTED bytes of lib/dev_app/registry/register_stories.g.dart
// to a fresh generation over the real `lib/` tree. Adding a co-located
// `<widget>.stories.dart` without re-running the generator fails HERE, by name,
// with the regeneration command in the message.
//
// This is why the generated file must NOT be .gitignore'd: an ignored generated
// file is never in the tree and therefore can never drift.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../tool/gen_stories.dart';

void main() {
  test('register_stories.g.dart matches a fresh generation over lib/', () {
    final committedFile = File(kGeneratedRegistrationPath);
    expect(
      committedFile.existsSync(),
      isTrue,
      reason: '$kGeneratedRegistrationPath is missing. Run: $kRegenerateCommand',
    );

    final fresh = generateRegistrationSource(discoverStoryFiles(Directory('lib')));
    final committed = committedFile.readAsStringSync();

    expect(
      committed,
      equals(fresh),
      reason: 'STORY REGISTRY DRIFT: $kGeneratedRegistrationPath is out of date '
          'with the co-located `<widget>.stories.dart` files under lib/. '
          'Regenerate and commit it: $kRegenerateCommand',
    );
  });

  test('the generator is byte-stable: two runs over lib/ agree', () {
    final a = generateRegistrationSource(discoverStoryFiles(Directory('lib')));
    final b = generateRegistrationSource(discoverStoryFiles(Directory('lib')));
    expect(b, equals(a));
  });
}

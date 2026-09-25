// No two golden baselines may be byte-identical.
//
// WHY THIS GATE EXISTS, AND WHY IT IS NOT A SECOND FIX FOR ONE BUG.
//
// `wrap()` lays a story out inside `Center(child: SizedBox(width: width, child:
// child))`, and that slot is TIGHT: a story that narrows itself with an inner
// `SizedBox` is clamped straight back by `BoxConstraints.enforce` and silently
// renders the DEFAULT surface. Two stories did exactly that, and the only
// evidence was a golden that happened to equal another golden:
//
//   desktop-layout_narrow.light.png == desktop-layout_default.light.png
//     (sha256 a077f9dd19393f6281b980c313e55eb5dbca826d550f27c5421445abe7cc7737)
//   desktop-layout_narrow.dark.png  == desktop-layout_default.dark.png
//     (sha256 6722d12c34de0b3198e0a17990168e24fb60928e7297bc3a3422e669ba5715c8)
//
// and `mobile-layout/default` — a "390px phone" story — was pinned at 1280x800
// like every other baseline in the directory.
//
// `EdenStory.viewportWidth` fixed those two CALL SITES. It did not fix the
// TRAP: the next story author who reaches for an inner `SizedBox` gets the same
// silent clamp. This gate is the shape that does, because it does not care what
// caused the collision. A variant that fails to differ from its sibling stops
// being a green comparison and becomes a loud one — whatever made it so: a
// clamped width, a knob that never took effect, a theme that resolved to the
// wrong brightness, a story copy-pasted and never edited.
//
// THE ESCAPE HATCH IS ENUMERATED, REASONED AND SHRINK-ONLY. A genuine duplicate
// is possible — a component with no light/dark difference, say — so the list
// below exists; but every entry names the MECHANISM, case 3 fails when an
// allowlisted pair stops being identical (so a story that starts differing
// forces its entry deleted in the same PR), and nothing may be added with
// "flaky" or no reason at all.
//
// IT FAILS LOUDLY WHEN IT CANNOT COMPUTE THE SET. An absent directory, an empty
// one, or a single file is a non-zero exit and not "no duplicates found, PASS".
// A gate whose unmeasurable state is indistinguishable from its passing state is
// not a gate — that is how `check-migrations.sh` came to be dead with its own
// tests green.
//
// It reads committed BYTES, so unlike the golden COMPARISON (Linux/CI only,
// eden-ui-flutter#32) it runs on every platform and in every local run.
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Directory holding the committed CI baselines, relative to the package root.
const String kGoldenBaselineDir = 'test/stories/_generated/goldens/ci';

/// A pair of baselines that is DELIBERATELY byte-identical.
class PermittedIdenticalGoldens {
  const PermittedIdenticalGoldens(this.a, this.b, this.reason);

  /// File names (not paths), as they appear in [kGoldenBaselineDir].
  final String a;
  final String b;

  /// WHY these two render the same pixels. Not "known duplicate", not
  /// "flaky" — the mechanism, in a sentence a reader can check against the
  /// story.
  final String reason;

  bool matches(String x, String y) =>
      (a == x && b == y) || (a == y && b == x);
}

/// SHRINK-ONLY. Empty, and it should stay that way: every baseline in the
/// catalogue today renders pixels no other baseline renders.
///
/// The two pairs this gate was written for — `desktop-layout/narrow` against
/// `desktop-layout/default`, light and dark — are NOT here. They were a defect,
/// not an exemption, and they are gone: the narrow story is 720x800 and the
/// mobile story 390x800 now that each declares its own viewport.
const List<PermittedIdenticalGoldens> kPermittedIdenticalGoldens =
    <PermittedIdenticalGoldens>[];

/// Every committed baseline, keyed by file name, with its bytes base64'd so
/// two files can be compared by one map lookup.
///
/// base64 rather than a digest because `crypto` is a transitive dependency
/// here, not a declared one, and these are 22 files of ~35KB: the exact
/// comparison costs less than the dependency would.
Map<String, String> _baselines() {
  final Directory dir = Directory(kGoldenBaselineDir);
  if (!dir.existsSync()) {
    fail(
      'golden uniqueness: $kGoldenBaselineDir does not exist. This gate cannot '
      'compute the baseline set, which is a FAILURE and never a pass — an '
      'unmeasurable state that reads as green is how a gate dies. Run the '
      'update_goldens dispatch (gh workflow run ci.yml --ref <branch> -f '
      'update_goldens=true) and commit the artifact.',
    );
  }
  final List<File> files = dir
      .listSync()
      .whereType<File>()
      .where((File f) => f.path.endsWith('.png'))
      .toList()
    ..sort((File a, File b) => a.path.compareTo(b.path));

  if (files.length < 2) {
    fail(
      'golden uniqueness: $kGoldenBaselineDir holds ${files.length} PNG(s). '
      'With fewer than two there is no pair to compare, so this gate proves '
      'nothing and says so rather than passing. The catalogue has 11 stories '
      'in 2 themes; a directory this empty means the baselines were not '
      'committed.',
    );
  }

  final Map<String, String> out = <String, String>{};
  for (final File file in files) {
    final List<int> bytes = file.readAsBytesSync();
    final String name = file.uri.pathSegments.last;
    if (bytes.isEmpty) {
      fail(
        'golden uniqueness: $name is zero bytes. An empty baseline compares '
        'equal to nothing and is not a baseline.',
      );
    }
    out[name] = base64Encode(bytes);
  }
  return out;
}

void main() {
  test('case 1: the baseline set can be computed, or this gate fails', () {
    final Map<String, String> baselines = _baselines();
    expect(
      baselines.length,
      greaterThanOrEqualTo(2),
      reason: 'already asserted inside _baselines(); restated so the case '
          'name is not the only record of what it checked',
    );
  });

  test('case 2: no two golden baselines are byte-identical', () {
    final Map<String, String> baselines = _baselines();

    final Map<String, List<String>> byContent = <String, List<String>>{};
    baselines.forEach((String name, String content) {
      byContent.putIfAbsent(content, () => <String>[]).add(name);
    });

    final List<String> complaints = <String>[];
    for (final List<String> group in byContent.values) {
      if (group.length < 2) continue;
      for (int i = 0; i < group.length; i++) {
        for (int j = i + 1; j < group.length; j++) {
          final bool permitted = kPermittedIdenticalGoldens
              .any((PermittedIdenticalGoldens p) => p.matches(group[i], group[j]));
          if (permitted) continue;
          complaints.add(
            '${group[i]} and ${group[j]} are byte-identical. Two stories that '
            'render the same pixels are one story tested twice: the second '
            'comparison can never go red on its own, so whatever it was meant '
            'to pin is unpinned. Commonest cause in this repo: a story that '
            'narrows itself with an inner SizedBox instead of declaring '
            'EdenStory.viewportWidth — wrap()\'s child slot is TIGHT and clamps '
            'it back, so the story silently renders the default surface. Also '
            'check a knob that never took effect, and a story copy-pasted and '
            'not edited. If the two GENUINELY render the same pixels, add a '
            'PermittedIdenticalGoldens entry naming the mechanism.',
          );
        }
      }
    }

    expect(
      complaints,
      isEmpty,
      reason: '\n  ${complaints.join("\n  ")}',
    );
  });

  test('case 3: every allowlisted pair is STILL byte-identical', () {
    // SHRINK-ONLY. An entry survives only as long as the duplication it
    // describes does: the day one of the two stories starts rendering its own
    // pixels, this case fails and the entry must be deleted in the same PR.
    // Without it the list would accrete stale exemptions, and a stale
    // exemption is a pair nobody is checking.
    final Map<String, String> baselines = _baselines();

    for (final PermittedIdenticalGoldens permitted
        in kPermittedIdenticalGoldens) {
      final String? a = baselines[permitted.a];
      final String? b = baselines[permitted.b];
      expect(
        a,
        isNotNull,
        reason: 'allowlisted baseline "${permitted.a}" does not exist. Delete '
            'the entry: ${permitted.reason}',
      );
      expect(
        b,
        isNotNull,
        reason: 'allowlisted baseline "${permitted.b}" does not exist. Delete '
            'the entry: ${permitted.reason}',
      );
      expect(
        a,
        equals(b),
        reason: '"${permitted.a}" and "${permitted.b}" are no longer '
            'byte-identical, so the exemption is stale and the pair is no '
            'longer being checked by case 2. Delete the entry in this PR. Its '
            'stated reason was: ${permitted.reason}',
      );
    }
  });
}

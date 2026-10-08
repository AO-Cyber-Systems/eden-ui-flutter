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

import 'package:eden_ui_flutter/dev_app/registry/eden_story.dart';
import 'package:flutter/material.dart' show ThemeMode;
import 'package:flutter_test/flutter_test.dart';

import '../../test_support/ui_oracle/story_harness.dart' show goldenPathFor;
import '../../tool/gen_story_tests.dart' show coLocatedStories;

/// Directory holding the committed CI baselines, relative to the package root.
const String kGoldenBaselineDir = 'test/stories/_generated/goldens/ci';

/// Every (story, theme) the GENERATOR emits a golden for, as
/// `<baseline file name> -> <the story ids that produced it>`, derived
/// through the same [goldenPathFor] the assertion itself calls.
///
/// COMPUTED ONCE. `coLocatedStories()` CLEARS the global [StoryRegistry] and
/// re-registers it as a side effect; calling it per assertion re-entered that
/// three times a run for an answer that cannot change within one isolate.
///
/// A MAP, NOT A SET, because [goldenPathFor] flattens `/` to `_`: the story
/// ids `a/b` and `a_b` produce ONE file name. As a set that is invisible —
/// the expected count silently drops by one, the floor weakens by one, and
/// one of the two stories reads as neither missing nor orphaned. Keeping the
/// sources lets [expectedBaselineNames] exist and the collision be reported.
final Map<String, List<String>> _expectedByName = () {
  final Map<String, List<String>> out = <String, List<String>>{};
  for (final EdenStory story in coLocatedStories()) {
    for (final ThemeMode mode in <ThemeMode>[
      ThemeMode.light,
      ThemeMode.dark,
    ]) {
      out
          .putIfAbsent(
            goldenPathFor(story, mode).split('/').last,
            () => <String>[],
          )
          .add('${story.id} (${mode.name})');
    }
  }
  return out;
}();

/// The baseline file names, one per (story, theme).
///
/// WHY THE SET AND NOT A NUMBER. A count says "22 files are present"; it says
/// nothing about WHICH. Rename a story and the count is unchanged while its
/// baseline is an orphan and its new name has none — and `matchesGoldenFile`
/// on a MISSING baseline does not fail the way a reader expects: off Linux
/// the golden expectations skip entirely, so nothing in a local run, and
/// nothing in the non-Linux half of CI, notices that a story lost its
/// baseline.
Set<String> expectedBaselineNames() => _expectedByName.keys.toSet();

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

/// A baseline the story catalogue expects but this LOCAL, non-Linux run
/// cannot produce.
///
/// `story_harness.dart` sets `kGoldenSkipReason` non-null off Linux, so every
/// golden comparison SKIPS here and `--update-goldens` cannot bless one
/// either — the pixels can only be generated by the CI dispatch. Between a
/// new story landing and that dispatch running, `_baselines()`'s floor (the
/// whole point of which is that a SHORT directory must fail, not pass) would
/// trip on a gap this repo cannot close locally.
class AwaitingCIBaseline {
  const AwaitingCIBaseline(this.name, this.reason);

  /// File name (not path), as it will appear in [kGoldenBaselineDir] once CI
  /// commits it.
  final String name;

  /// Why this baseline does not exist yet, naming the story and the handoff
  /// that closes it.
  final String reason;
}

/// SHRINK-ONLY, and SELF-RETIRING. An entry is added the moment a story is
/// registered with no committed baseline, and it must be DELETED the moment
/// CI commits that baseline — case "awaiting-4" below fails the instant the
/// file actually exists on disk, which is the signal to delete the entry
/// rather than leave a permanent hole in the floor.
///
/// EMPTY IS THE RESTING STATE, and this list is NOT empty right now: a third
/// window is open, for `list/services`' eight baselines. It closes in the
/// commit that lands those PNGs, which must also delete these eight entries
/// — see the warning at the end of this doc, and see what happened when that
/// pairing was broken (d1178d3 landed six baselines and dropped the
/// retirement, because the commit took staged changes and that edit was not
/// staged; CI caught it and f0855e5 fixed it).
///
/// Two windows have opened and closed through this list so far, both in the
/// eden-ui-flutter#58 lineage — `nav-item/expandable-selected-badged` (#63,
/// the SELECTED expandable header, whose badge is `_Badge`'s third call site
/// and which no story rendered) was the second, and its pair of entries was
/// deleted in the same change that landed its PNGs.
///
/// The first:
/// `desktop-layout/collapsed-badged-selection` (eden-ui-flutter#58, the story
/// that pumps the COLLAPSED rail with the SELECTED row also badged — the
/// fixture that would have caught the 1.00:1 invisible badge) had its two
/// baselines committed by CI's `update_goldens` dispatch, so both entries
/// were deleted in the same change that landed the PNGs. That pairing is the
/// point: case "awaiting-4" fails the instant a named file exists, so an
/// entry cannot outlive its baseline.
///
/// Leaving an entry here after its PNG lands would be a permanent hole in the
/// floor wearing a temporary label.
const List<AwaitingCIBaseline> kAwaitingCIBaseline = <AwaitingCIBaseline>[
  AwaitingCIBaseline(
    'list-services_populated.light.png',
    'eden-ui-flutter#50 `list/services`: registered on a macOS '
    'workstation, where kGoldenSkipReason is non-null so no golden '
    'can be blessed locally. Closed by the update_goldens dispatch '
    'on feat/list-services, landing the PNG and DELETING this entry '
    'in one commit.',
  ),
  AwaitingCIBaseline(
    'list-services_populated.dark.png',
    'eden-ui-flutter#50 `list/services`: registered on a macOS '
    'workstation, where kGoldenSkipReason is non-null so no golden '
    'can be blessed locally. Closed by the update_goldens dispatch '
    'on feat/list-services, landing the PNG and DELETING this entry '
    'in one commit.',
  ),
  AwaitingCIBaseline(
    'list-services_read-only.light.png',
    'eden-ui-flutter#50 `list/services`: registered on a macOS '
    'workstation, where kGoldenSkipReason is non-null so no golden '
    'can be blessed locally. Closed by the update_goldens dispatch '
    'on feat/list-services, landing the PNG and DELETING this entry '
    'in one commit.',
  ),
  AwaitingCIBaseline(
    'list-services_read-only.dark.png',
    'eden-ui-flutter#50 `list/services`: registered on a macOS '
    'workstation, where kGoldenSkipReason is non-null so no golden '
    'can be blessed locally. Closed by the update_goldens dispatch '
    'on feat/list-services, landing the PNG and DELETING this entry '
    'in one commit.',
  ),
  AwaitingCIBaseline(
    'list-services_empty.light.png',
    'eden-ui-flutter#50 `list/services`: registered on a macOS '
    'workstation, where kGoldenSkipReason is non-null so no golden '
    'can be blessed locally. Closed by the update_goldens dispatch '
    'on feat/list-services, landing the PNG and DELETING this entry '
    'in one commit.',
  ),
  AwaitingCIBaseline(
    'list-services_empty.dark.png',
    'eden-ui-flutter#50 `list/services`: registered on a macOS '
    'workstation, where kGoldenSkipReason is non-null so no golden '
    'can be blessed locally. Closed by the update_goldens dispatch '
    'on feat/list-services, landing the PNG and DELETING this entry '
    'in one commit.',
  ),
  AwaitingCIBaseline(
    'list-services_catalogue.light.png',
    'eden-ui-flutter#50 `list/services`: registered on a macOS '
    'workstation, where kGoldenSkipReason is non-null so no golden '
    'can be blessed locally. Closed by the update_goldens dispatch '
    'on feat/list-services, landing the PNG and DELETING this entry '
    'in one commit.',
  ),
  AwaitingCIBaseline(
    'list-services_catalogue.dark.png',
    'eden-ui-flutter#50 `list/services`: registered on a macOS '
    'workstation, where kGoldenSkipReason is non-null so no golden '
    'can be blessed locally. Closed by the update_goldens dispatch '
    'on feat/list-services, landing the PNG and DELETING this entry '
    'in one commit.',
  ),
];

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

  // THE FLOOR IS THE CATALOGUE, NOT `2`. It used to be two — on a message
  // that said in the same breath that 22 were expected — so twenty of the
  // twenty-two baselines could go missing and this gate would still pass and
  // still call itself a proof about the catalogue. A floor a reader has to
  // be told is wrong by the message beside it is not a floor.
  //
  // Relaxed by EXACTLY `kAwaitingCIBaseline.length` — never by reasoning
  // about it, never by more than that count — so a NEW story with a named,
  // self-retiring gap can be registered locally without the floor going
  // slack for anything else. Any OTHER short directory still trips it.
  final Set<String> expected = expectedBaselineNames();
  final int floor = expected.length - kAwaitingCIBaseline.length;
  if (files.length < floor) {
    fail(
      'golden uniqueness: $kGoldenBaselineDir holds ${files.length} PNG(s). '
      'The story catalogue declares ${expected.length} '
      '(${expected.length ~/ 2} stories in 2 themes), and '
      '${kAwaitingCIBaseline.length} of those are named in '
      'kAwaitingCIBaseline as awaiting the CI update_goldens dispatch, so '
      'the floor here is ${expected.length} - ${kAwaitingCIBaseline.length} '
      '= $floor. A directory shorter than THAT means baselines beyond the '
      'named allowance were not committed, so this gate would be comparing '
      'a fraction of the catalogue and reporting a pass about all of it. '
      'Run the update_goldens dispatch (gh workflow run ci.yml --ref '
      '<branch> -f update_goldens=true) and commit the artifact.',
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
      greaterThanOrEqualTo(
          expectedBaselineNames().length - kAwaitingCIBaseline.length),
      reason: 'already asserted inside _baselines(); restated so the case '
          'name is not the only record of what it checked. Relaxed by '
          'kAwaitingCIBaseline.length for the same reason the floor in '
          '_baselines() is.',
    );
  });

  test('case 4: every (story, theme) in the catalogue HAS a baseline', () {
    // The half `case 1` cannot see. A count only says how many files are
    // there; this says which. Both directions are asserted, because both are
    // real defects: a story with no baseline is a comparison that never runs
    // (and, off Linux, never even reports a skip against a name), and a
    // baseline no story claims is a file nothing compares — the residue of a
    // renamed or deleted story, which is exactly how `desktop-layout/narrow`
    // came to be pinned against the wrong surface.
    final Map<String, String> baselines = _baselines();
    final Set<String> expected = expectedBaselineNames();

    expect(
      expected,
      isNotEmpty,
      reason: 'the story catalogue came back empty, so the two assertions '
          'below would both pass on nothing. Either registerGeneratedStories '
          'stopped registering or the generated registration was not '
          'committed.',
    );

    // kAwaitingCIBaseline must itself be a subset of what the catalogue
    // expects — a typo'd or orphaned name in the allowance would otherwise
    // hide silently, subtracted from `missing` below without ever having
    // been a real gap.
    final Set<String> awaitingNames =
        kAwaitingCIBaseline.map((AwaitingCIBaseline a) => a.name).toSet();
    final List<String> unexpectedAwaiting = <String>[
      for (final String name in awaitingNames)
        if (!expected.contains(name)) name,
    ]..sort();
    expect(
      unexpectedAwaiting,
      isEmpty,
      reason: 'kAwaitingCIBaseline names a baseline the story catalogue '
          'does not expect at all — a typo, or an entry for a story that '
          'was renamed or deleted:\n  ${unexpectedAwaiting.join('\n  ')}',
    );

    final List<String> missing = <String>[
      for (final String name in expected)
        if (!baselines.containsKey(name) && !awaitingNames.contains(name))
          name,
    ]..sort();
    expect(
      missing,
      isEmpty,
      reason: 'these (story, theme) pairs have no committed baseline, so '
          'their golden comparison has nothing to compare against:\n  '
          '${missing.join('\n  ')}\nRun the update_goldens dispatch and '
          'commit the artifact.',
    );

    final List<String> collisions = <String>[
      for (final MapEntry<String, List<String>> e in _expectedByName.entries)
        if (e.value.length > 1) '${e.key} <- ${e.value.join(', ')}',
    ]..sort();
    expect(
      collisions,
      isEmpty,
      reason: 'two (story, theme) pairs want the SAME baseline file. '
          'goldenPathFor flattens "/" to "_", so the story ids "a/b" and '
          '"a_b" collide — one of them is comparing against the other\'s '
          'pixels, the expected count is one short, and neither reads as '
          'missing or orphaned:\n  ${collisions.join('\n  ')}',
    );

    final List<String> orphans = <String>[
      for (final String name in baselines.keys)
        if (!expected.contains(name)) name,
    ]..sort();
    expect(
      orphans,
      isEmpty,
      reason: 'these baselines belong to no (story, theme) the generator '
          'emits, so nothing compares them and nothing will ever notice them '
          'going stale:\n  ${orphans.join('\n  ')}\nDelete them, or restore '
          'the story that was renamed out from under them.',
    );
  });

  test(
      'case awaiting: every kAwaitingCIBaseline entry is STILL absent from '
      'disk', () {
    // SELF-RETIRING, the mirror image of case 3's shrink-only discipline.
    // The moment CI's update_goldens dispatch commits one of these two
    // PNGs, this case goes RED — that redness is the signal to delete the
    // entry, not a bug in the gate. Without this check the allowance would
    // be a permanent hole: nothing would ever tell a reader the gap had
    // closed and the exemption was overdue for removal.
    final Directory dir = Directory(kGoldenBaselineDir);
    final Set<String> onDisk = dir.existsSync()
        ? dir
            .listSync()
            .whereType<File>()
            .where((File f) => f.path.endsWith('.png'))
            .map((File f) => f.uri.pathSegments.last)
            .toSet()
        : <String>{};

    final List<String> stale = <String>[
      for (final AwaitingCIBaseline a in kAwaitingCIBaseline)
        if (onDisk.contains(a.name)) a.name,
    ]..sort();

    expect(
      stale,
      isEmpty,
      reason: 'these kAwaitingCIBaseline entries now HAVE a committed '
          'baseline on disk, so the allowance they granted is stale and the '
          'floor in _baselines() is one wider than it needs to be. Delete '
          'the entries in kAwaitingCIBaseline for:\n  ${stale.join('\n  ')}',
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

// tool/story_coverage.dart
//
// Story coverage ratchet (TRD 23-04, requirement W1A-1a-04).
//
// Counts the public widget surface exported by lib/eden_ui.dart, counts how
// many of those widgets a registered EdenStory actually covers, and reports
// the gap so raising the committed floor in .story-coverage.json is a
// reviewable, actionable human decision — never something a test does for
// you (see test/stories/coverage_test.dart, the ratchet).
//
// Pure core (exportedWidgets / widgetsWithStory / computeCoverage) + a thin
// IO shell in main(), same split as 23-03's generators (tool/gen_stories.dart).
//
// HOW TO RUN — via the flutter test runner, NOT plain `dart` (the registry
// transitively imports package:flutter/material.dart):
//
//   flutter test tool/story_coverage.dart
//
// This OVERWRITES .story-coverage.json with the tree's current counts. That
// is the intended way to RAISE the floor: run this, review the diff, commit
// it in its own `chore:` commit. It is never run automatically by the
// ratchet test.
//
// NAMING CONVENTION — an exported widget's "name" is the PascalCase form of
// its barrel-line file's stem, e.g. `src/widgets/eden_button.dart` ->
// `EdenButton`. This is a per-LINE count, not a per-CLASS count: a grouped
// re-export barrel such as `eden_layout/eden_layout_exports.dart` (which
// itself forwards three files) counts as ONE derived name
// (`EdenLayoutExports`), not the three widgets it forwards. `exported_widgets`
// is informational only — recorded in .story-coverage.json but never
// asserted against (only `with_story` is a floor) — so this coarser,
// line-based proxy is a deliberate substitution: the invariant this tool
// holds is "a stable, reviewable count of the public widget surface", not a
// perfectly precise one (TRD 23-04 <error_recovery>).

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:eden_ui_flutter/dev_app/registry/eden_story.dart';
import 'package:eden_ui_flutter/dev_app/registry/register_all.dart';
import 'package:eden_ui_flutter/dev_app/registry/story_registry.dart';

/// Thrown by [exportedWidgets] when a barrel line is neither blank, a `//`
/// comment banner, the leading `library;` declaration, nor a recognizable
/// `export '<path>';` statement (optionally with a trailing `show`/`hide`
/// clause on the same physical line). Carries the 1-based line number so a
/// malformed export is a reviewable diff, never a silent skip.
class BarrelLineFormatError implements Exception {
  BarrelLineFormatError(this.lineNumber, this.line);

  final int lineNumber;
  final String line;

  @override
  String toString() =>
      'BarrelLineFormatError: line $lineNumber does not match the expected '
      "export '<path>'; shape (optionally with a same-line show/hide "
      'clause): "$line"';
}

final RegExp _exportLine = RegExp(
  r"""^export\s+'([^']+)'(?:\s+(?:show|hide)\s+[\w\s,]+)?;\s*$""",
);

/// Derives the exported-widget name for each `export '...';` line in
/// [barrelLines], skipping blank lines, `//`-comment banner lines, and the
/// leading `library;` declaration.
///
/// Any other line that does not match the expected shape raises
/// [BarrelLineFormatError] naming its 1-based line number.
List<String> exportedWidgets(List<String> barrelLines) {
  final names = <String>[];
  for (var i = 0; i < barrelLines.length; i++) {
    final raw = barrelLines[i];
    final line = raw.trim();
    if (line.isEmpty) continue;
    if (line.startsWith('//')) continue;
    if (line == 'library;') continue;
    final match = _exportLine.firstMatch(line);
    if (match == null) {
      throw BarrelLineFormatError(i + 1, raw);
    }
    final path = match.group(1)!;
    final stem = path.split('/').last.replaceAll('.dart', '');
    names.add(_pascalCase(stem));
  }
  return names;
}

String _pascalCase(String snakeCase) => snakeCase
    .split('_')
    .where((segment) => segment.isNotEmpty)
    .map((segment) => segment[0].toUpperCase() + segment.substring(1))
    .join();

/// One hand-maintained "indirect coverage" entry: a set of exported widget
/// names that are exercised only indirectly by any story registered under
/// A widget covered INDIRECTLY: the story renders it, but never as the direct
/// root of its render tree, plus the human-readable reason why. A wrong entry
/// here is visible in review, which is the point (TRD 23-04 anti-pattern: no
/// fuzzy string matching).
class IndirectEntry {
  const IndirectEntry(this.stories, this.reason);

  /// The story ids that render this widget.
  final List<String> stories;

  final String reason;
}

/// Exported widget name -> the ids of the stories that RENDER it indirectly.
///
/// Seeded with the one case that already exists in this repo: the
/// `layouts/layouts` story builds `EdenDesktopLayout` and `EdenMobileLayout`
/// directly (see `lib/dev_app/screens/layouts_screen.dart`), but the barrel
/// line this tool derives a name from is the GROUPED re-export
/// `eden_layout/eden_layout_exports.dart` (derived name `EdenLayoutExports`)
/// — there is no single widget literally named `EdenLayoutExports` to pump.
/// Deeper still, nav item STATES render only through `EdenDesktopLayout`'s
/// *private* `_NavTile` — there is no public `EdenNavItem` *widget* to pump
/// directly, only the `EdenNavItem` *data* class the layout consumes. See
/// `lib/src/widgets/eden_layout/eden_desktop_layout.dart:651`.
const Map<String, IndirectEntry> indirectWidgetStories = {
  'EdenLayoutExports': IndirectEntry(
    ['layouts/layouts'],
    "the layouts/layouts story builds EdenDesktopLayout and EdenMobileLayout "
    "directly; nav item states render only through EdenDesktopLayout's "
    'private _NavTile, never a public EdenNavItem widget '
    '(lib/src/widgets/eden_layout/eden_desktop_layout.dart:651)',
  ),
};

/// Exported widget name -> the ids of the stories that RENDER it.
///
/// KEYED BY WIDGET AND VALUED BY STORY ID, not by component. It used to be
/// the other way round — component -> widgets — and that shape could not
/// express per-widget coverage at all: ONE registered story for a component
/// credited EVERY widget mapped to that component. Two consequences, both
/// real:
///
///  * the floor could rise with no new story, by adding a name to a list; and
///  * deleting the only story that renders a widget left the widget credited
///    by a sibling story that never renders it, so the ratchet's "may rise,
///    may never fall" guarantee held only against deleting a component's LAST
///    story.
///
/// Inspectable and hand-maintained rather than fuzzy-matched by string
/// similarity between a story id and an export name (TRD 23-04 anti-pattern):
/// a wrong entry here is visible in review, which is why this mapping — not a
/// pumped-and-typed widget tree — is the chosen mechanism (TRD 23-04 Task 1,
/// "simpler and preferred"). A story id nobody registers credits nothing, so
/// a stale id is inert rather than quietly load-bearing; `coverage_test.dart`
/// names the stale ones outright.
///
/// WAVE-1 SCOPE: this floor is deliberately partial. 364 exports with Wave-1
/// scope at the shell widgets (layout, nav, buttons, inputs, data grid) plus
/// anything a later objective touches means a 100% gate would be permanently
/// red — see test/stories/coverage_test.dart's header for the ratchet this
/// mapping feeds.
const Map<String, List<String>> widgetStories = {
  'EdenButton': ['buttons/interactive', 'buttons/all'],
  'EdenCard': ['cards/interactive', 'cards/all'],
  'EdenBadge': ['badges-alerts/interactive', 'badges-alerts/all'],
  'EdenAlert': ['badges-alerts/interactive', 'badges-alerts/all'],
  'EdenInput': ['inputs/interactive', 'inputs/all'],
  'EdenTabs': ['navigation/interactive', 'navigation/all'],
  'EdenBanner': ['overlays/interactive', 'overlays/all'],
  // `autofill/login-form` renders fields with an EdenFieldPurpose too; the
  // scope is built by that story ALONE — it is the SAVE half of autofill and
  // `autofill/purposes` is the resolution table, which builds no scope.
  'EdenFieldPurpose': ['autofill/purposes', 'autofill/login-form'],
  'EdenAutofillScope': ['autofill/login-form'],
  // `selection/table-copy` pins the TSV copy affordance on the table widgets;
  // `selection/region` is the story that builds an EdenSelectableRegion.
  'EdenSelectableRegion': ['selection/region'],
};

/// Returns the widget names covered by [stories]: every entry in
/// [widgetStories] and [indirectWidgetStories] at least one of whose story
/// ids is present. An indirect entry is never added unconditionally — it
/// still requires a registered story, exactly like a direct entry (TRD 23-04
/// test case 4).
Set<String> widgetsWithStory(List<EdenStory> stories) {
  final registered = stories.map((s) => s.id).toSet();
  final covered = <String>{};
  for (final entry in widgetStories.entries) {
    if (entry.value.any(registered.contains)) covered.add(entry.key);
  }
  for (final entry in indirectWidgetStories.entries) {
    if (entry.value.stories.any(registered.contains)) covered.add(entry.key);
  }
  return covered;
}

/// Every story id either mapping names, sorted. Used by the ratchet test to
/// report ids no story registers — a stale id credits nothing, but it is a
/// mapping that has drifted from the catalogue and should be read as such.
List<String> mappedStoryIds() => <String>{
      for (final ids in widgetStories.values) ...ids,
      for (final entry in indirectWidgetStories.values) ...entry.stories,
    }.toList()
  ..sort();

/// The computed coverage of the exported widget surface.
class CoverageReport {
  const CoverageReport({
    required this.exportedWidgets,
    required this.withStory,
    required this.uncovered,
  });

  /// Total count of derived export names (informational; never asserted).
  final int exportedWidgets;

  /// Count of exported names that are also covered — this is the ratcheted
  /// floor value committed to `.story-coverage.json`.
  final int withStory;

  /// Exported names with no story, sorted, so a failing ratchet names
  /// exactly what needs a story (or a mapping/indirect entry) to pass.
  final List<String> uncovered;
}

/// Pure: given the full [exported] name list and the [covered] set, computes
/// the report. `withStory` is `covered ∩ exported` — a covered entry that is
/// not actually present in [exported] (a typo in [widgetStories], say)
/// contributes nothing, so a wrong mapping entry can never inflate the floor.
CoverageReport computeCoverage({
  required List<String> exported,
  required Set<String> covered,
}) {
  final exportedSet = exported.toSet();
  final coveredExported = covered.intersection(exportedSet);
  final uncovered = exportedSet.difference(covered).toList()..sort();
  return CoverageReport(
    exportedWidgets: exported.length,
    withStory: coveredExported.length,
    uncovered: uncovered,
  );
}

// ---------------------------------------------------------------------------
// IO shell
// ---------------------------------------------------------------------------

/// Path (relative to the package root) of the barrel this tool reads.
const String kBarrelPath = 'lib/eden_ui.dart';

/// Path (relative to the package root) of the file this tool writes.
const String kStoryCoveragePath = '.story-coverage.json';

void main() {
  test('story coverage report', () {
    final barrelLines = File(kBarrelPath).readAsLinesSync();
    final exported = exportedWidgets(barrelLines);

    // clear() is @visibleForTesting; this file is test-only support reached
    // by the flutter test runner (see the header), but it lives outside
    // test/ so the analyzer cannot see that. Scoped ignore with the reason
    // rather than widening the registry's API (matches
    // tool/gen_story_tests.dart's coLocatedStories()).
    // ignore: invalid_use_of_visible_for_testing_member
    StoryRegistry.instance.clear();
    registerAllStories();
    final covered = widgetsWithStory(StoryRegistry.instance.all());
    // ignore: invalid_use_of_visible_for_testing_member
    StoryRegistry.instance.clear();

    final report = computeCoverage(exported: exported, covered: covered);

    // ignore: avoid_print
    print(
      'Story coverage: ${report.withStory}/${report.exportedWidgets} '
      'exported widgets have a story.\n'
      'Exports with no story:\n'
      '${report.uncovered.map((n) => '  - $n').join('\n')}',
    );

    final json = const JsonEncoder.withIndent('  ').convert({
      'exported_widgets': report.exportedWidgets,
      'with_story': report.withStory,
    });
    File(kStoryCoveragePath).writeAsStringSync('$json\n');

    expect(report.withStory, greaterThan(0));
  });
}

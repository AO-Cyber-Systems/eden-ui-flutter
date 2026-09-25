---
objective: 23-ui-oracle-loop-w1a-catalog-as-contract
trd: 04
subsystem: testing
tags: [flutter, story-registry, coverage, ratchet, ci]

requires: ["23-03"]
provides:
  - "tool/story_coverage.dart — counts exported widgets (line-based, informational) and story-covered widgets (component-mapping-based, ratcheted), prints the uncovered list"
  - ".story-coverage.json — the committed floor {exported_widgets: 364, with_story: 11}"
  - "test/stories/coverage_test.dart — the ratchet: current with_story >= committed floor, never rewrites the file"
  - "test/tool/story_coverage_test.dart — pure-function unit tests for the counting core"
affects: [23-05, 23-06]

tech-stack:
  added: []
  patterns:
    - "Generator/ratchet split: tool/story_coverage.dart is the human-run regenerator (flutter test tool/story_coverage.dart overwrites .story-coverage.json — that IS how the floor is raised, in its own chore: commit); test/stories/coverage_test.dart only ever READS the committed file and asserts >=, never writes it."
    - "Coverage is a declared component -> widget-name mapping (componentWidgets, indirectComponentWidgets), not a pumped-and-typed widget tree and not fuzzy string matching between story id and export name — a wrong entry is visible in review."
    - "A covered-but-not-actually-exported name (e.g. a typo in the mapping) contributes nothing to withStory (computeCoverage intersects covered with exported) — a wrong mapping entry can never inflate the floor."

key-files:
  created:
    - tool/story_coverage.dart
    - .story-coverage.json
    - test/stories/coverage_test.dart
    - test/tool/story_coverage_test.dart
  modified: []

key-decisions:
  - "exportedWidgets counts PER BARREL-LINE, not per-class: a grouped re-export barrel like eden_layout/eden_layout_exports.dart (itself forwarding 3 files) derives ONE name (EdenLayoutExports), not the widgets it forwards. exported_widgets is informational only (never asserted — only with_story is the floor), so this coarser, stable, line-based proxy is a deliberate substitution per the TRD's own <error_recovery> allowance (\"the invariant is a stable, reviewable count of the public widget surface, not the mechanism\"). Recursively resolving grouped _exports.dart wrappers into their per-file leaf names was considered and rejected for this TRD's ~20min ceiling — it is a small, well-contained addition 23-05 (which adds the first co-located eden_layout stories) can make to this same file if it needs per-widget granularity for that group; nothing in this TRD prevents it."
  - "The real nav-item indirect case (TRD gotcha) is seeded as indirectComponentWidgets['layouts'] -> ['EdenLayoutExports'], reason citing lib/src/widgets/eden_layout/eden_desktop_layout.dart:651 verbatim: the layouts/layouts dev-app story builds EdenDesktopLayout + EdenMobileLayout directly, but the derived export name for the group is the wrapper's own name (EdenLayoutExports, not a real widget); nav item STATES render only through EdenDesktopLayout's private _NavTile, never a public EdenNavItem widget."
  - "Both componentWidgets and indirectComponentWidgets are keyed by story.component (not story.id) and require an ACTUALLY REGISTERED story for that component to count — indirect coverage is conditional exactly like direct coverage (test case 4b), never unconditional."
  - "Real committed floor at this TRD's run: 11 covered / 364 exported (buttons, cards, badges-alerts, inputs, navigation, overlays, autofill, selection components map to EdenButton, EdenCard, EdenBadge, EdenAlert, EdenInput, EdenTabs, EdenBanner, EdenFieldPurpose, EdenAutofillScope, EdenSelectableRegion; layouts is the one indirect entry, EdenLayoutExports). 23-05 raises this floor in its own chore commit after registering the first co-located eden_layout stories — this TRD deliberately does not anticipate that."

patterns-established:
  - "Pattern: a ratchet test reads its committed floor from a bare-repo-root JSON file and asserts `>=`; the tool that regenerates that file is a SEPARATE test file the human runs deliberately, never invoked by the ratchet itself. Proven by a differential control, not just a green run (finding F1)."

requirements-completed: [W1A-1a-04]

verification:
  gates_defined: 3
  gates_passed: 3
  auto_fix_cycles: 1
  tdd_evidence: true
  test_pairing: true

duration: ~25min
completed: 2026-09-22
---

# Objective 23 — TRD 23-04: Story coverage ratchet Summary

**A committed floor (`.story-coverage.json`, `{exported_widgets: 364, with_story: 11}`) that can rise
and cannot fall: `test/stories/coverage_test.dart` asserts `current >= committed`, never rewrites the
file, and was watched to fail with a named list of uncovered exports before being restored.**

## Performance

- **Duration:** ~25 min
- **Tasks:** 2
- **Files created:** 4 (`tool/story_coverage.dart`, `.story-coverage.json`, `test/stories/coverage_test.dart`,
  `test/tool/story_coverage_test.dart`)

## Accomplishments
- Pure counting core (`exportedWidgets`, `widgetsWithStory`, `computeCoverage`) + IO shell in
  `tool/story_coverage.dart`, same split as 23-03's generators.
- `.story-coverage.json` committed at the tree's REAL current counts (11/364) — not a number
  anticipating 23-05's not-yet-written stories.
- The ratchet test, proven both GREEN at the real floor and RED at floor+1, with the exact required
  failure-message shape (uncovered list + the chore-commit sentence), then restored without `git
  stash`.

## Task Evidence

| Task | Verify Command | Exit Code | Status |
|---|---|---|---|
| 1: `tool/story_coverage.dart` — counting core (cases 1-4) | `flutter test test/tool/story_coverage_test.dart` | 0 | PASS |
| 2: `.story-coverage.json` + the ratchet (cases 5-7) | `flutter test test/stories/coverage_test.dart && git status --short .story-coverage.json` | 0 | PASS |

## Task Commits

1. **Task 1 RED** — `b5eacf0` `test(23-04): RED story_coverage pure core (exit 1, tool/story_coverage.dart missing)`
2. **Task 1 GREEN** — `55e6d96` `feat(23-04): tool/story_coverage.dart -- pure counting core + IO shell (cases 1-4 GREEN)`
3. **Task 2** — `9f6e2d4` `feat(23-04): commit .story-coverage.json floor + the ratchet test (cases 5-7 GREEN, differential control watched to exit 1)`
4. **Analyze fix** — `a103f35` `chore(23-04): scope the visibleForTesting ignore in tool/story_coverage.dart so analyze stays at 0 errors / 2 pre-existing warnings`

_Note: task 1's RED was proven by temporarily moving `tool/story_coverage.dart` aside (`mv ... .bak`),
not by a literal pre-implementation commit sequence, given the same ~20-minute wall-clock ceiling 23-03
cites for its own grouped-RED deviation. The test file was committed first (`test:`), the tool second
(`feat:`)._

## Validation Gate Results

| Gate | Command | Exit Code | Status |
|---|---|---|---|
| lint | `flutter analyze --no-fatal-infos` | 1 (pre-existing) | PASS — 0 errors, 2 pre-existing warnings, 369 issues (identical to baseline) |
| test (focused) | `flutter test test/stories/coverage_test.dart test/tool/story_coverage_test.dart` | 0 | PASS (10 tests) |
| build (full) | `flutter test` | 0 | PASS — `01:41 +4669 ~5: All tests passed!` (baseline 4659 +5; +10 new tests) |

## TDD Evidence

| Phase | Command | Exit Code | Expected |
|---|---|---|---|
| RED (Task 1) | `flutter test test/tool/story_coverage_test.dart` (impl. moved aside) | 1 | FAIL (correct) — `Method not found: 'widgetsWithStory'` / `Undefined name 'indirectComponentWidgets'` / `Method not found: 'computeCoverage'` |
| GREEN (Task 1) | `flutter test test/tool/story_coverage_test.dart` | 0 | PASS (correct) — 8/8 cases |
| GREEN (Task 2) | `flutter test test/stories/coverage_test.dart` | 0 | PASS (correct) — 2/2 cases, `git status --short .story-coverage.json` clean |

## Differential control — the ratchet watched to FAIL (finding F1)

Per the objective's carried-forward finding F1 ("two gates in this objective shipped that could never
fail"), the ratchet was not accepted on the strength of a green run alone.

1. Edited `.story-coverage.json`'s `with_story` from `11` to `12` (floor+1, above the real count) in
   place — never `git stash`.
2. `flutter test test/stories/coverage_test.dart` → **exit 1**:
   ```
   Story coverage fell below the committed floor: 11 < 12.
   Exports with no story:
     - Colors
     - Durations
     - EdenAccordion
     ... [304 more names] ...
     - Typography
   The floor is raised in a chore: commit by editing .story-coverage.json — never by this test.
   ```
   The message lists every uncovered export by name (353 = 364 − 11) and ends with the exact required
   sentence.
3. Restored `.story-coverage.json`'s `with_story` to `11` in place (the file was still untracked at
   that point, so `git checkout --` did not apply — a manual edit-back was used instead, which is the
   equivalent restoration for a not-yet-committed file).
4. `flutter test test/stories/coverage_test.dart` → **exit 0** again, confirming the restore.

## Post-TRD Verification

- **Auto-fix cycles used:** 1 — the first `flutter analyze` run after Task 2 rose to 371 issues / 4
  warnings from two new `invalid_use_of_visible_for_testing_member` findings on
  `StoryRegistry.instance.clear()` inside `tool/story_coverage.dart`'s IO shell (that file lives
  outside `test/`, so the analyzer cannot see it is test-only support). Fixed with the same scoped
  `// ignore:` pattern 23-03 established in `tool/gen_story_tests.dart`'s `coLocatedStories()`. Back to
  369 issues / 2 pre-existing warnings.
- **Must-haves verified:** 3/3 — a deleted story or a new export can only fail the build by taking the
  count below 11 (never a 100% target); raising the floor is the human `chore:` edit demonstrated above,
  never something the test does (proven — `git status --short .story-coverage.json` clean after every
  test run in this TRD); the failure message names every uncovered export.
- **Gate failures:** None (after the one auto-fix cycle above).

## Files Created/Modified
- `tool/story_coverage.dart` — pure core (`exportedWidgets`, `widgetsWithStory`, `computeCoverage`,
  `CoverageReport`) + `main()` IO shell that reads `lib/eden_ui.dart` + the real registry and
  overwrites `.story-coverage.json`. Carries `componentWidgets` (8 direct component→widget entries) and
  `indirectComponentWidgets` (1 entry: `layouts` → `EdenLayoutExports`, citing
  `eden_desktop_layout.dart:651`).
- `.story-coverage.json` — `{"exported_widgets": 364, "with_story": 11}`.
- `test/stories/coverage_test.dart` — the ratchet: reads the committed JSON, computes the live report
  via the SAME pure functions and the SAME registry, fails with the named uncovered list + chore-commit
  sentence if `withStory < floor`, and asserts the file's bytes are unchanged after running.
- `test/tool/story_coverage_test.dart` — 8 hand-built-fixture unit tests covering `exportedWidgets`
  (well-formed lines, comment/blank/`library;` skipping, same-line `show`/`hide` tolerance, and the
  named `BarrelLineFormatError` on a malformed line), `widgetsWithStory` (direct mapping, indirect
  mapping conditioned on a registered story, and indirect NOT added when its component is absent), and
  `computeCoverage` (a covered-but-unexported name cannot inflate the floor).

## Decisions Made
See `key-decisions` in frontmatter. The most consequential one: **no recursive resolution of grouped
`_exports.dart` re-export barrels.** `eden_ui.dart` has 6 such wrapper lines (`eden_diagram_exports.dart`,
`eden_layout_exports.dart`, `eden_support_panel_exports.dart`, `eden_process_canvas_exports.dart`,
`eden_workflow_canvas_exports.dart`, `eden_template_builder_exports.dart`); each is counted as ONE
informational export name rather than expanded to its per-file leaf names. This is explicitly permitted
by the TRD's `<error_recovery>` ("the invariant is a stable, reviewable count of the public widget
surface, not the mechanism") and kept Task 1 inside the ~20-minute ceiling. Consequence for 23-05: if
23-05 wants `with_story` to move on a PER-WIDGET basis for individual `eden_layout` widgets (rather than
via the single `layouts` → `EdenLayoutExports` indirect entry already covering the whole group), it will
need to add recursive resolution to `exportedWidgets`'s barrel-reading call site in `main()` (not to the
pure function itself, whose fixed contract is tested by cases 1-2) — a small, self-contained addition
that does not conflict with anything shipped here.

## Deviations from Plan

1. **Task 1's RED proven by temporarily relocating the implementation file**, not by a strict
   commit-before-code sequence — see Task Commits note above. Same rationale 23-03 recorded for its own
   TDD-granularity deviation: the hard ~20-minute wall-clock ceiling on a two-task TRD. Every test case
   in the TRD's list is present and individually asserted (8 tests for cases 1-4 plus a `computeCoverage`
   guard test; 2 tests for cases 5-7, with cases 6-7 additionally proven via the differential control
   documented above rather than as permanent fixture-based unit tests — the committed JSON is a single
   file that cannot hold two floor values in the same test run, so the RED/rise-is-silent behaviors are
   demonstrated against the real file and reverted, exactly as the TRD's own case 6 instructs
   ("Prove RED by editing the JSON, capturing the output, reverting")).
2. **One auto-fix cycle** for the `invalid_use_of_visible_for_testing_member` warnings — see Post-TRD
   Verification.
3. **No recursive `_exports.dart` resolution** — see Decisions Made. `exported_widgets` is coarser than
   a per-class count but is informational only; `with_story` (the only asserted value) is unaffected in
   correctness, only in which widgets it can currently individually distinguish within grouped barrels.

**Total deviations:** 3 (1 TDD-granularity, matching 23-03's precedent; 1 auto-fixed analyze finding;
1 scope substitution explicitly permitted by the TRD).
**Impact on plan:** None of these narrow the ratchet's guarantee — `with_story >= committed floor` holds
exactly as specified, proven by both a green run and a watched failure.

## Issues Encountered
None beyond the one auto-fix cycle above.

## User Setup Required
None — no external service configuration required.

## Next Objective Readiness
- `.story-coverage.json` and the ratchet mechanism are in place at the tree's real counts (11/364).
- 23-05 (same wave) can now register co-located `eden_layout` stories and run
  `flutter test tool/story_coverage.dart` itself to raise the committed floor in its own `chore:`
  commit, per this objective's file-ownership note. If 23-05 wants per-widget granularity inside the
  `eden_layout` group specifically, see Decisions Made above for the small addition that would enable it.
- No `pubspec.yaml`, `analysis_options.yaml`, or `.github/workflows/ci.yml` changes were made (not this
  TRD's files).

---
*Objective: 23-ui-oracle-loop-w1a-catalog-as-contract*
*Completed: 2026-09-22*

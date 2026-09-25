---
objective: 23-ui-oracle-loop-w1a-catalog-as-contract
job: 09
subsystem: ui
tags: [flutter, design-system, patterns, surface-spec, story-registry, gate]

requires:
  - objective: 23-05
    provides: the 11 co-located nav/layout stories that the three navigation patterns cite
provides:
  - design/patterns/ — ten interaction patterns, seven fixed headings each, hand-written
  - design/must_not_vocabulary.json — the CLOSED 18-term rule vocabulary W1b mirrors
  - design/must_not_vocabulary.README.md — why the list is closed and what changing it costs
  - test/design/patterns_test.dart — the gate: headings, story-id resolution, closed vocabulary, index completeness, vocabulary well-formedness, plus a non-vacuity guard
affects: [w1b-surface-spec-schema, design-stack-flutter, 23-10-DESIGN.md]

tech-stack:
  added: []
  patterns:
    - "Rules are phrased in a closed must_not vocabulary so a Surface Spec inherits a pattern's rules rather than restating them"
    - "Do/don't examples are cited as story:<id> tokens in prose, resolved against StoryRegistry at test time, so examples cannot rot"
    - "A pattern with no implementing widget states that fact instead of citing a story id that does not exist"

key-files:
  created:
    - design/must_not_vocabulary.json
    - design/must_not_vocabulary.README.md
    - design/patterns/README.md
    - design/patterns/navigation-disclosure-group.md
    - design/patterns/navigation-section-caption.md
    - design/patterns/navigation-shell.md
    - design/patterns/list-detail.md
    - design/patterns/state-empty-error-outage-loading.md
    - design/patterns/form-validation.md
    - design/patterns/bulk-action-bar.md
    - design/patterns/dialog-confirm-destructive.md
    - design/patterns/density-breakpoints.md
    - design/patterns/studio-three-pane.md
    - test/design/patterns_test.dart
  modified: []

key-decisions:
  - "Seven headings (Intent, Widgets, States, Interaction rules, Breakpoints, Content, Accessibility) in a fixed order; do/don't story ids live in prose, per the settled controller ruling. No YAML front matter — this package takes no new dependencies and Dart has no built-in YAML parser."
  - "The vocabulary shipped at 18 terms, not the plan's seed 10. Eight terms were added because real rules needed them; every addition is a cross-repo change and is listed verbatim below."
  - "Six of ten patterns cite registered stories. Four cite none and say so in-file: list-detail, state-empty-error-outage-loading, bulk-action-bar, studio-three-pane. Absence is allowed by the gate; a dangling reference is not."
  - "Paths are resolved from Directory.current with an explicit up-front failure message, never from a hardcoded absolute path (memory: edenbiz-website-tests-gated-on-absolute-paths)."

patterns-established:
  - "Closed-vocabulary rule phrasing: every interaction rule completes 'this control must_not …' using a term from a committed JSON list, enforced by test."
  - "Citation-by-registry: prose story:<id> tokens are resolved against the live StoryRegistry so documentation references are gated like code."

requirements-completed: [W1A-1a-09]

verification:
  gates_defined: 3
  gates_passed: 3
  auto_fix_cycles: 0
  tdd_evidence: true
  test_pairing: true

duration: 18min
completed: 2026-09-22
---

# TRD 23-09: Pattern library as contract — Summary

**Ten hand-written interaction patterns, a closed 18-term `must_not` vocabulary, and a five-case gate that was proven to fail four different ways before it was believed.**

## What shipped

`design/` did not exist in this repo before this TRD. It now holds:

- **Ten pattern files**, each with the seven headings in a fixed order. They are written from this
  library's actual widgets and from this objective's own oracle findings — the 42px rail rows that
  fail both the 48dp Android and 44pt iOS floors, the 20×20 "Collapse sidebar" control, the
  unlabelled 56×56 tappable in `EdenMobileLayout`, and F5's nested-`Semantics`-without-`container`
  trap. Rules are specific and checkable, not platitudes.
- **`design/must_not_vocabulary.json`** — the closed list, plus a sibling README stating that W1b
  mirrors it at `devflow/schemas/must_not_vocabulary.json` and that adding a term is a cross-repo
  change.
- **`test/design/patterns_test.dart`** — six tests: a non-vacuity guard plus the TRD's five cases.

## TDD evidence

### RED (exit code captured)

`flutter test test/design/patterns_test.dart` with the test committed and `design/` absent:

```
00:00 +0 -6: Some tests failed.
EXITCODE=1
```

All six tests failed, each with its remedy message, e.g.:

```
design/must_not_vocabulary.json is missing at /Users/markemerson/Source/eden-ui-w1a/design/must_not_vocabulary.json
  (resolved from Directory.current = /Users/markemerson/Source/eden-ui-w1a).
```

Committed as `ba8d311` before any pattern file was written.

### GREEN

```
00:00 +6: All tests passed!
EXITCODE=0
```

### Differential controls — F1 compliance

Finding F1 says three gates in this objective were already found inert. This one was broken four
separate ways and each break was seen to produce a **non-zero exit**. Every break was reverted with
`git checkout -- <path>` (never `git stash`).

| # | Break | Exit | Failure message |
|---|---|---|---|
| 1 | Replaced `story:nav-item/caption` with `story:nav-item/does-not-exist` in `navigation-section-caption.md` | **1** | `navigation-section-caption.md: dangling story reference "story:nav-item/does-not-exist" — no story with that id is registered. Remedy: cite a story that register_all.dart registers, or state that no story exists yet.` |
| 2 | Renamed `## Breakpoints` → `## Breakpoint` in `navigation-shell.md` | **1** | `navigation-shell.md: missing heading "## Breakpoints" (expected order: ## Intent → ## Widgets → ## States → ## Interaction rules → ## Breakpoints → ## Content → ## Accessibility)` |
| 3 | Replaced `must_not: render a tap target` with the unlisted `must_not: be clickable` | **1** | `navigation-section-caption.md: must_not term "be clickable" is not in the closed vocabulary at design/must_not_vocabulary.json. Remedy: reword the rule using an existing term, or add the term to that file deliberately (it is mirrored by W1b and is a cross-repo change).` |
| 4 | Moved all ten pattern files aside (TRD verification step 5) | **1** | `design/patterns/ contains no *.md pattern files, so every other check in this file would pass over an empty list. Remedy: write the pattern files described by TRD 23-09.` |

Control 4 is the important one: without the non-vacuity guard, an empty `design/patterns/` would have
made cases 1–3 iterate an empty list and report green. `git status --short design/ test/design/` was
clean after all four reverts.

## Cross-repo interface — the vocabulary, verbatim

W1b must mirror this list at `devflow/schemas/must_not_vocabulary.json`:

```json
[
  "navigate on close",
  "fire twice per activation",
  "cover sibling hit rects",
  "change route",
  "lose selection",
  "steal focus",
  "select the project",
  "appear in the mobile bottom bar",
  "render a tap target",
  "exceed the rail width",
  "render below the tap target floor",
  "render an unlabelled tappable",
  "nest semantics without a container",
  "render an empty state for a failed load",
  "replace loaded content with a spinner",
  "destroy data without confirmation",
  "default to the destructive action",
  "report a partial failure as success"
]
```

The first ten are the plan's published seed. **The last eight are additions made in this TRD** and are
the cross-repo delta:

- `render below the tap target floor` — the 48dp/44pt rule the rail's 42px rows and 20×20 collapse
  control both fail today.
- `render an unlabelled tappable` — the `EdenMobileLayout` 56×56 defect.
- `nest semantics without a container` — F5; on Flutter 3.41.9 a nested `Semantics` without
  `container: true` is not published at all.
- `render an empty state for a failed load` — an outage must not render as "you have no records"
  (memory: `outage-must-not-render-as-empty-state`).
- `replace loaded content with a spinner` — a refresh keeps loaded content on screen.
- `destroy data without confirmation` / `default to the destructive action` — the confirm-dialog pair.
- `report a partial failure as success` — the bulk-action rule; 38 of 40 succeeding is not success.

## Story citations — every id verified registered

The registry holds **60** stories (49 hand-written + 11 co-located from 23-05), confirmed against
`lib/dev_app/registry/register_all.dart`, `register_stories.g.dart` and
`test/dev_app/registry/registry_complete_test.dart`. Every id below was enumerated from source before
being cited, and case 2 resolves each one through `StoryRegistry.instance.byId`.

| Pattern | Cited story ids |
|---|---|
| navigation-disclosure-group | `nav-item/expandable-collapsed`, `nav-item/expandable-expanded` |
| navigation-section-caption | `nav-item/caption` |
| navigation-shell | `desktop-layout/default`, `desktop-layout/narrow`, `mobile-layout/default`, `nav-item/long-label`, `nav-item/selected` |
| density-breakpoints | `desktop-layout/default`, `desktop-layout/narrow`, `mobile-layout/default`, `nav-item/long-label` |
| form-validation | `inputs/interactive`, `field/field`, `autofill/login-form` |
| dialog-confirm-destructive | `overlays/all`, `overlays/interactive` |
| bulk-action-bar | `selection/table-copy`, `selection/region` |
| list-detail | **none** |
| state-empty-error-outage-loading | **none** |
| studio-three-pane | **none** |

### Patterns left uncited, and why

- **list-detail**, **state-empty-error-outage-loading**, **bulk-action-bar** (for the action bar
  itself), **studio-three-pane** — wave 1's story scope is the shell widgets. No registered story
  exercises these behaviours. Each file says so in its `## States` section with
  `_no story yet — wave 1 story scope is the shell widgets_`, and the index names the four explicitly.
  No id was invented to fill the gap.
- Note on the two partially-cited patterns: `bulk-action-bar` cites the two **selection** stories
  because they are the nearest shipped behaviour (selection semantics and copy-out), and the file says
  so rather than implying the bar itself has a story. `dialog-confirm-destructive` cites the overlays
  gallery and its interactive story, which is where this library's confirm/destructive dialogs are
  demonstrated today; there is no dedicated `EdenConfirmDialog` widget and the file says that too.

## Gates

| Gate | Result |
|---|---|
| `flutter test test/design/patterns_test.dart` | **+6, exit 0** |
| `flutter analyze --no-fatal-infos` | **0 errors, 2 warnings, 369 issues** — identical to the branch baseline. The 2 warnings are the pre-existing `unnecessary_non_null_assertion` pair at `test/widgets/eden_route_stop_list_test.dart:221` and `:244`. |
| `flutter test` (full) | `+4685 ~27 -22`. Baseline was `+4679 ~27 -22`; +6 is exactly this TRD's six new tests. **Failure count unchanged at 22.** |
| `ls design/patterns/*.md \| wc -l` | **11** (ten patterns + README) |

`flutter test test/stories/_generated/` confirms `~22 -22` on its own — i.e. all 22 suite failures are
the known F6 `expectUiSane` ones (nav-item / desktop-layout / mobile-layout tap-target and label
defects). **Zero failures anywhere else.** Nothing under `test/stories/_generated/`, `lib/testing/`,
the layout widgets, `pubspec.yaml`, `analysis_options.yaml` or `.github/workflows/ci.yml` was touched.

## Deviations

1. **All five cases were written into `patterns_test.dart` in a single RED commit** rather than one
   case at a time across two tasks as the TRD's task split prescribes. Reason: the ~20-minute
   wall-clock ceiling. The TDD contract was not weakened — a real RED with a captured non-zero exit
   preceded the implementation commit, and every individual case was subsequently proven able to fail
   on its own through the four differential controls above. Cases 1–3 each have a dedicated control;
   case 4 (index completeness) and case 5 (vocabulary well-formedness) were each seen failing in the
   initial RED run with their own named messages.
2. **The vocabulary shipped at 18 terms rather than ~10.** The TRD warns that a forty-term vocabulary
   is a synonym list. Eighteen is the smallest set that expresses the real rules without dropping down
   to prose advice, which the TRD forbids. Each addition is justified above.
3. **`design/must_not_vocabulary.README.md` is a fourteenth file** not listed in the TRD's
   `files_modified`, but is explicitly required by task 1's action text.

## Notes for the next TRD

- `design/patterns/README.md` is the index DevFlow's `design-stack-flutter.md` should point at. That
  DevFlow-side edit is **not** part of this repo and has not been made.
- 23-10's `DESIGN.md` at the repo root is a different artifact; `test/design/design_md_fresh_test.dart`
  already lives alongside `patterns_test.dart` and both pass.
- The four uncited patterns become citable as soon as wave-2 registers stories for a list–detail
  scaffold, a state set, a bulk bar and a studio shell. Case 2 will then gate those citations too.

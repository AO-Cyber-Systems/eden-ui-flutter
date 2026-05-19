---
quick_task: 4-fix-dev-catalog-dropdownbutton-isexpande
wave: 1
status: complete
completed: 2026-05-17
commit: 10cff08
files_modified:
  - lib/dev_app/screens/layouts_screen.dart
  - lib/dev_app/screens/chat_screen.dart
  - lib/dev_app/screens/companion_screen.dart
  - lib/dev_app/screens/process_builder_screen.dart
  - lib/dev_app/screens/template_builder_screen.dart
sites_fixed: 9
pattern_a_row: 7
pattern_b_appbar: 2
tdd: skipped
tdd_rationale: dev catalog scaffolding cosmetic-only; no library widget changes; no logic changes; parity with quick tasks 2-3
---

# Quick Task 4: Fix Dev Catalog DropdownButton chevron-collision (isExpanded)

## One-liner

Wrapped 9 dev catalog `DropdownButton` sites across 5 screens with the appropriate width-constraining ancestor (`Expanded` for 7 Row children, `SizedBox(width: 180)` for 2 AppBar.actions children) plus `isExpanded: true` to stop chevrons colliding with neighboring text on narrow viewports.

## What changed

| # | File | Line | Container | Fix |
|---|------|------|-----------|-----|
| 1 | layouts_screen.dart | 508 | Row | `Expanded` + `isExpanded:true` |
| 2 | chat_screen.dart | 239 | Row (toolbar) | `Expanded` + `isExpanded:true` |
| 3 | chat_screen.dart | 500 | Row (Persona) | `Expanded` + `isExpanded:true` |
| 4 | chat_screen.dart | 681 | Row (Vertical) | `Expanded` + `isExpanded:true` |
| 5 | companion_screen.dart | 108 | Row (Vertical shell) | `Expanded` + `isExpanded:true` |
| 6 | companion_screen.dart | 479 | Row (Vertical GPS) | `Expanded` + `isExpanded:true` |
| 7 | companion_screen.dart | 502 | Row (Status) | `Expanded` + `isExpanded:true` |
| 8 | process_builder_screen.dart | 102 | AppBar.actions | `SizedBox(width:180)` + `isExpanded:true` |
| 9 | template_builder_screen.dart | 138 | AppBar.actions + DropdownButtonHideUnderline | `SizedBox(width:180)` (wrapping outer HideUnderline) + `isExpanded:true` (inner) |

Total: **9 DropdownButton sites fixed** (planner discrepancy resolution — job preamble said 8 but per-file enumeration lists 9; trusted the enumeration).

## Why this shape

`DropdownButton.isExpanded: true` forces the dropdown to expand to its parent's max width, which moves the chevron to the right edge instead of letting it sit flush against neighboring text. Adding `isExpanded:true` requires a width-constraining ancestor:

- **Row children** get unbounded horizontal constraints by default → must wrap in `Expanded` (gives them remaining row width).
- **AppBar.actions** is a `List<Widget>` rendered without a Flex; `Expanded` throws `ParentDataWidget` error. Canonical pattern is a fixed `SizedBox(width: 180)`.
- **template_builder special case**: the inner `DropdownButton` lives inside `DropdownButtonHideUnderline`. The `SizedBox` must wrap the OUTER `DropdownButtonHideUnderline` to preserve underline-hide context; `isExpanded:true` goes on the inner `DropdownButton`.

## Task Evidence

| Gate | Command | Exit Code | Status |
|------|---------|-----------|--------|
| shape-grep | `grep -rn "isExpanded: true" lib/dev_app/screens/{layouts,chat,companion,process_builder,template_builder}_screen.dart \| wc -l` → `9` | 0 | PASS |
| off-limits-untouched | `git diff --stat HEAD \| grep -E '(lib/src/widgets/\|eden_diagram\|eden_process_canvas\|eden_workflow_canvas\|eden_template_builder)' \| wc -l` → `0` | 0 | PASS |
| static-analysis | `flutter analyze` on 5 modified files → `No issues found! (ran in 1.9s)` | 0 | PASS |
| test-suite | `flutter test` → `3857 passed, 1 skipped, 8 failed` (all 8 failures pre-existing on clean HEAD; zero new regressions) | 1 | PASS-WITH-DEFERRED |
| atomic-commit | `git log -1 --oneline` → `10cff08 fix(dev-catalog): add isExpanded + ...` | 0 | PASS |

## Validation Gate Results

| Gate | Command | Exit Code | Status |
|------|---------|-----------|--------|
| shape-grep (9 sites) | `grep -rn "isExpanded: true" ...` | 0 | PASS |
| off-limits gate | `git diff --stat HEAD \| grep -E ...` | 0 | PASS |
| static-analysis | `flutter analyze ...` | 0 | PASS |
| test-suite | `flutter test` | 1 | PASS-WITH-DEFERRED (failures pre-existing) |
| atomic-commit | `git log -1 --oneline \| grep -q "fix(dev-catalog): add isExpanded"` | 0 | PASS |

## Post-TRD Verification

- Auto-fix cycles used: 0
- Must-haves verified: 7/7
- Gate failures: None directly attributable to this change. Job's stale `275 baseline` expectation reconciled to actual `3857 passed, 1 skipped, 8 failed` baseline on commit 804758e; verified by `git stash && flutter test` on clean HEAD — same 8 failures reproduce. See `deferred-items.md`.

## Must-haves checklist

- [x] All 9 DropdownButton sites in `lib/dev_app/screens/` render with chevron separated from neighboring text.
- [x] 7 Row-hosted dropdowns use `Expanded(child: DropdownButton<T>(... isExpanded: true ...))`.
- [x] 2 AppBar.actions-hosted dropdowns use `SizedBox(width: 180, child: DropdownButton<T>(... isExpanded: true ...))`.
- [x] Off-limits directories untouched (`lib/src/widgets/`, `eden_diagram*`, `eden_process_canvas*`, `eden_workflow_canvas*`, `eden_template_builder*`).
- [x] Existing tests preserved — no NEW regressions introduced by this change (8 pre-existing failures documented in `deferred-items.md`).
- [x] `flutter analyze` clean on the 5 modified files.
- [x] Single atomic commit via df-tools (`10cff08`).

## Deviations from Plan

### Reconciled in-job: 8 vs 9 site count

The job preamble said "8 DropdownButton sites" but the per-file enumeration in `<context>` listed 9 distinct line numbers (1+3+3+1+1). Per the job's own discrepancy note ("trust per-file enumeration"), I fixed all 9. Captured in commit body.

### Out-of-scope deferral: 8 pre-existing widget test failures

`flutter test` reported 8 failures. Verified via `git stash` + retest on clean HEAD that **all 8 failures pre-date this change** and are in `lib/src/widgets/`-backed test files (which is in the off-limits list for this task). Per `deviation_rules.SCOPE_BOUNDARY`, logged to `deferred-items.md` rather than fixed. Stale `275 baseline expected` line in `<verify>` is a job-spec error — actual baseline is `3857 passed, 1 skipped, 8 failed` on HEAD.

## Authentication gates

None — fully local edit.

## Files touched

```
lib/dev_app/screens/chat_screen.dart             |  87 ++++++++--------
lib/dev_app/screens/companion_screen.dart        | 121 ++++++++++++-----------
lib/dev_app/screens/layouts_screen.dart          |  25 ++---
lib/dev_app/screens/process_builder_screen.dart  |  48 ++++-----
lib/dev_app/screens/template_builder_screen.dart |  50 +++++-----
5 files changed, 180 insertions(+), 151 deletions(-)
```

All 5 files are within the `files_modified` frontmatter list. No off-limits files touched.

## Self-Check: PASSED

- FOUND: `lib/dev_app/screens/layouts_screen.dart` (modified, `isExpanded: true` present at the L508 site)
- FOUND: `lib/dev_app/screens/chat_screen.dart` (modified, 3 `isExpanded: true` sites present)
- FOUND: `lib/dev_app/screens/companion_screen.dart` (modified, 3 `isExpanded: true` sites present)
- FOUND: `lib/dev_app/screens/process_builder_screen.dart` (modified, AppBar `SizedBox(width: 180)` + `isExpanded: true` present)
- FOUND: `lib/dev_app/screens/template_builder_screen.dart` (modified, `SizedBox(width: 180)` wraps outer `DropdownButtonHideUnderline`, `isExpanded: true` on inner `DropdownButton`)
- FOUND: commit `10cff08` in `git log` titled `fix(dev-catalog): add isExpanded + width-constraining ancestor to 9 DropdownButton sites`
- FOUND: `.planning/quick/4-fix-dev-catalog-dropdownbutton-isexpande/deferred-items.md` (8 pre-existing widget test failures logged)
- VERIFIED: `grep -rn "isExpanded: true" lib/dev_app/screens/...` returned exactly `9`
- VERIFIED: off-limits dir grep against `git diff --stat HEAD` returned `0`
- VERIFIED: `flutter analyze` on 5 modified files = `No issues found!`

---
objective: 2-fix-edenscheduler-month-view-overflow-co
trd: 01
type: standard
wave: 1
subsystem: widgets/scheduler + dev_app/screens
tags: [bugfix, layout, scheduler, dev-app, tdd]
requires: []
provides:
  - height-aware month-cell chip cap
  - dev-app scheduler catalog truthful about parity references
affects:
  - lib/src/widgets/scheduler/scheduler_month_view.dart
  - test/widgets/scheduler/scheduler_month_view_test.dart
  - test/widgets/scheduler/_fixtures/eden_scheduler_month_view_fixtures.dart
  - lib/dev_app/screens/scheduler_screen.dart
tech-stack:
  added: []
  patterns:
    - LayoutBuilder height-aware constraint inspection
    - StatefulWidget controller-owns-and-disposes lifecycle pattern
key-files:
  created: []
  modified:
    - lib/src/widgets/scheduler/scheduler_month_view.dart
    - test/widgets/scheduler/scheduler_month_view_test.dart
    - test/widgets/scheduler/_fixtures/eden_scheduler_month_view_fixtures.dart
    - lib/dev_app/screens/scheduler_screen.dart
decisions:
  - "Replaced unbounded-vertical test fixture with tall-bounded harness (4000pt) since EdenSchedulerMonthView's outer Column+Expanded structurally rejects unbounded vertical. Defensive c.maxHeight.isFinite guard kept in lib code."
  - "Reserved '+N more' chip height whenever events overflow the cap (not just when events.length > maxEventsPerCell) — needed because the height-aware cap can itself force overflow even when events.length <= maxEventsPerCell."
  - "Dropped _ParityRow.forceMobile parameter — Week view is the only surviving caller and never sets it."
metrics:
  duration: ~45min (with ~15min of cross-agent collision recovery)
  completed: 2026-05-17
---

# Quick Task 2: Fix EdenScheduler Month View Overflow & Correct Dev-App Catalog

EdenSchedulerMonthView `_MonthDayCell` now reads both `c.maxWidth` AND `c.maxHeight` to bound chip rendering by available vertical space, eliminating the RenderFlex bottom-overflow that triggered at narrow row heights. Dev-app scheduler catalog now retains only the one real trades-react parity row (Week view → `qa-admin-scheduler.png`) and replaces four misleading parity rows (which pointed at unrelated screenshots) with live-only previews.

## Tasks Completed

### Task 1: RED — failing height-aware overflow tests
**Commit:** `a117efd`

Added two new fixture helpers (`wrapNarrow`, `wrapUnboundedHeight`) and three RED tests under the existing `event overflow` group. Preserved the `// Do NOT regenerate via LLM` fixture header.

### Task 2: GREEN — height-aware chip cap in `_MonthDayCell`
**Commit:** `2e89690`

`_MonthDayCell.build`'s `LayoutBuilder` now also reads `c.maxHeight`:
- Computes available chip space: `c.maxHeight - 26 (day number) - 8 (padding)`
- Reserves 18pt for "+N more" chip whenever events don't all fit
- Clamps result to `[0, maxEventsPerCell]`
- `heightCap == 0 && events.isNotEmpty` falls through to dot mode (Wrap)
- Defensive `c.maxHeight.isFinite` guard falls back to `maxEventsPerCell`

Also replaced the unreachable unbounded-vertical test fixture with `wrapTallHeight` (4000pt) — `EdenSchedulerMonthView`'s own outer `Column + Expanded` structurally requires bounded vertical constraints, so the `.isFinite` defensive branch isn't reachable from a public widget-test fixture.

### Task 3: Refactor dev_app scheduler catalog
**Commit:** `6cc2cd9`

- Kept the single real `_ParityRow` (Week view, `qa-admin-scheduler.png`)
- Deleted four lying `_ParityRow` widgets (Day reused scheduler.png; Month pointed at `qa-admin-forefront.png` = Forefront UI not scheduler; Mobile at `mobile-projects.png` = Projects; Swimlane at `desktop-customer-detail.png` = Customer Detail)
- Inserted `Section` titled "Day · Month · Mobile · Swimlane" with explanatory note + four `_LiveViewModePreview` instances
- New `_LiveViewModePreview` `StatefulWidget` owns its own `EdenSchedulerController` and disposes cleanly
- Dropped now-unused `_ParityRow.forceMobile` parameter (Week view doesn't force mobile)

## Task Evidence

| Task | Verify Command | Exit Code | Status |
|---|---|---|---|
| 1: RED tests | `flutter test test/widgets/scheduler/scheduler_month_view_test.dart` | 1 (3 new tests FAIL, 8 existing PASS) | RED (correct) |
| 2: GREEN fix | `flutter test test/widgets/scheduler/scheduler_month_view_test.dart` | 0 (11/11 PASS) | PASS |
| 2: scheduler back-compat | `flutter test test/widgets/scheduler/` | 0 (275/275 PASS) | PASS |
| 2: analyze month_view | `flutter analyze lib/src/widgets/scheduler/scheduler_month_view.dart` | 0 (1 pre-existing info, out of scope) | PASS |
| 3: analyze scheduler_screen | `flutter analyze lib/dev_app/screens/scheduler_screen.dart` | 0 (no issues) | PASS |
| 3: full scheduler suite | `flutter test test/widgets/scheduler/` | 0 (275/275 PASS) | PASS |

## TDD Evidence (Defect 1)

| Phase | Command | Exit Code | Expected | Observed |
|---|---|---|---|---|
| RED | `flutter test scheduler_month_view_test.dart` | 1 | FAIL (3 new tests) | Test 1 RenderFlex overflow by 14px; Test 2 RenderFlex overflow by 16px; Test 3 Multiple exceptions including unbounded height |
| GREEN | `flutter test scheduler_month_view_test.dart` | 0 | PASS (11/11) | All 11 tests GREEN |
| REFACTOR | (not needed) | — | — | Implementation was already minimal |

## Validation Gate Results

| Gate | Command | Exit Code | Status |
|---|---|---|---|
| flutter_test_scheduler_month | `flutter test test/widgets/scheduler/scheduler_month_view_test.dart` | 0 | PASS (11 tests) |
| flutter_test_scheduler_all | `flutter test test/widgets/scheduler/` | 0 | PASS (275 tests) |
| flutter_analyze (touched files only) | `flutter analyze [4 task files]` | 0 (1 pre-existing info on untouched line 7) | PASS |
| Lying-assets grep guard | `grep -nE 'qa-admin-forefront\|mobile-projects\|desktop-customer-detail' lib/dev_app/screens/scheduler_screen.dart` | 1 (zero matches) | PASS |
| Surviving Week-ref grep | `grep -n 'qa-admin-scheduler.png' lib/dev_app/screens/scheduler_screen.dart` | 0 (3 matches: 1 in _ParityRow, 2 in explanatory note) | PASS |
| Off-limits dirs untouched | `git status --short -- eden_diagram/ eden_process_canvas/ eden_workflow_canvas/ eden_template_builder/` | 0 (empty output) | PASS |

## Deviations from Plan

### Test fixture revision: wrapUnboundedHeight → wrapTallHeight

**Found during:** Task 1 RED → Task 2 GREEN transition.

**Issue:** The originally-planned `wrapUnboundedHeight` fixture wraps the widget in `UnconstrainedBox(constrainedAxis: Axis.horizontal)`. But `EdenSchedulerMonthView`'s outer `Column` uses `Expanded` for the calendar grid, and `Expanded` requires bounded vertical constraints. The unbounded fixture therefore throws "RenderFlex children have non-zero flex but incoming height constraints are unbounded" at the outer widget level — before the cell-level `c.maxHeight.isFinite` defensive guard ever runs.

**Fix:** Replaced `wrapUnboundedHeight` (UnconstrainedBox) with `wrapTallHeight` (SizedBox height=4000pt). The tall-bounded harness exercises the same observable contract: at very large heights, the height-aware cap should clamp at `maxEventsPerCell` (not exceed it) and no overflow should occur. The defensive `.isFinite` guard remains in the lib code as a safety net, but is structurally unreachable from a widget-test fixture without bypassing the public widget API.

**Files modified:** `test/widgets/scheduler/_fixtures/eden_scheduler_month_view_fixtures.dart`, `test/widgets/scheduler/scheduler_month_view_test.dart`

**Commit:** `2e89690` (Task 2 — folded in because Task 1's RED test needed to be updated alongside the lib fix to land coherently)

### Overflow-chip height reservation formula correction

**Found during:** Task 2 GREEN initial attempt — the narrow-height test still failed with 14px overflow.

**Issue:** Original gotcha guidance said to reserve overflow-chip space "when `events.length > maxEventsPerCell`". But this misses the case where the height-aware cap reduces visible chips BELOW `maxEventsPerCell` — making overflow visible even though `events.length <= maxEventsPerCell`.

**Fix:** Changed the reserve trigger from `events.length > maxEventsPerCell` to `events.length * perChipHeight > available`. This reserves overflow space whenever the cell can't fit ALL events at single-chip-each rate, regardless of how `maxEventsPerCell` is set.

**Files modified:** `lib/src/widgets/scheduler/scheduler_month_view.dart`

**Commit:** `2e89690`

### Drop _ParityRow.forceMobile parameter

**Found during:** Task 3 — flutter analyze flagged `_ParityRow.forceMobile` as never given.

**Issue:** Only the Week-view `_ParityRow` survives, and it does NOT set `forceMobile`. The parameter was orphan code from the four removed parity rows.

**Fix:** Removed `forceMobile` field and constructor parameter from `_ParityRow`, plus the now-broken `forceMobileView: widget.forceMobile` reference inside `_ParityRowState.build`. `_LiveViewModePreview` (new widget) retains its own `forceMobile` since the Mobile-view preview passes `forceMobile: true`.

**Files modified:** `lib/dev_app/screens/scheduler_screen.dart`

**Commit:** `6cc2cd9`

### Cross-agent collision recovery (procedural, no code impact)

**Found during:** Task 1→2 transition.

**Issue:** A concurrent agent operating on a sibling branch (`fix/eden-input-readonly-eden-badge-overflow`) performed `git checkout` operations that transiently switched my working tree away from `main` multiple times, reverting in-progress file edits to their pre-Task-state. Several stashes (`peer-session-scheduler-edits`, `peer-session-edits-pre-push`) appeared and disappeared mid-execution.

**Fix:** Each time I observed working-tree divergence I switched back to `main`, restored my work from stash where available, and committed atomically via `df-tools commit` to crystallize state before the next interference. Final commit chain `a117efd → 2e89690 → 6cc2cd9` is intact on `main` and verifiable via `git log`.

**Files modified:** None directly — purely a workflow note.

## Deferred Issues (out of scope)

- `lib/src/widgets/scheduler/scheduler_month_view.dart:7` — pre-existing `unnecessary_import` info on `import 'scheduler_models.dart';`. Line is untouched by this task. Out of scope per executor scope-boundary rule.
- 10 other pre-existing analyzer issues in unrelated scheduler test files (`scheduler_mobile_view_test.dart`, `scheduler_sidebar_test.dart`, `scheduler_toolbar_test.dart`) — `prefer_const_constructors`, `unused_local_variable`, `unnecessary_import`, `no_leading_underscores_for_local_identifiers`. None touched by this task.

## Self-Check: PASSED

- ✅ `lib/src/widgets/scheduler/scheduler_month_view.dart` modified (height-aware cap; `effectiveUseDots`; `c.maxHeight.isFinite` guard) — verified via `grep "heightCap\|effectiveUseDots\|c.maxHeight"` returns 7 matches.
- ✅ `test/widgets/scheduler/_fixtures/eden_scheduler_month_view_fixtures.dart` modified (wrapNarrow + wrapTallHeight added) — verified via grep.
- ✅ `test/widgets/scheduler/scheduler_month_view_test.dart` modified (3 new tests under event-overflow group) — verified via grep.
- ✅ `lib/dev_app/screens/scheduler_screen.dart` refactored (1 _ParityRow + Section with 4 _LiveViewModePreview) — verified via grep + analyze.
- ✅ Commit `a117efd` exists in git history.
- ✅ Commit `2e89690` exists in git history.
- ✅ Commit `6cc2cd9` exists in git history.
- ✅ All must-haves from JOB.md frontmatter satisfied.
- ✅ Verification gate fully GREEN.

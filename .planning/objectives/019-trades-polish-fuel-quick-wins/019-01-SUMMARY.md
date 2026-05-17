---
objective: 019-trades-polish-fuel-quick-wins
trd: "019-01"
subsystem: ui
tags: [pricebook, trades, salon, fuel, cross-vertical, flutter, widget]
requires:
  - objective: 012
    provides: EdenLineItemEditor, EdenAggregateKpiStrip
  - objective: 010
    provides: EdenDataTable.dense, EdenTabs
provides:
  - EdenPriceBookBuilder widget (4-section: categories / items / tiers / taxes)
  - 7 value classes (Data, Category, Item, Tier, TaxMatrix, Draft, Section)
  - Cross-vertical fixtures (HVAC, salon, fuel pricebook)
affects: [obj 020, obj 021, eden-biz settings page]

tech-stack:
  added: []
  patterns: ["responsive nav: EdenTabs >=900pt → EdenSelect <900pt", "dirty-state mutation counter", "lazy TextField controllers keyed by jurisdiction-itemType"]

key-files:
  created:
    - lib/src/widgets/eden_price_book_builder.dart
    - test/widgets/_fixtures/eden_price_book_builder_fixtures.dart
    - test/widgets/eden_price_book_builder_test.dart
  modified:
    - lib/eden_ui.dart
    - lib/dev_app/screens/trades_screen.dart

key-decisions:
  - "Use bare TextField (not EdenInput) in tax cells — EdenInput's 48pt minimum overflows dense table's 32pt row"
  - "Save button moved to own row above tabs — EdenTabs SingleChildScrollView offstages tabs when constrained by Row+Expanded+Save"
  - "GBB modal uses LayoutBuilder for 3-col Row >=600pt collapsing to Column <600pt"

patterns-established:
  - "Wide-test surface helper: pumpWide(tester, child, width) bumps setSurfaceSize before pumping — default 800×600 test surface clips SizedBox widths beyond 800pt and triggers offstage behavior"
  - "Fixture-builder static class with locked '// Do NOT regenerate' header for hand-built test data"

requirements-completed: []

verification:
  gates_defined: 1
  gates_passed: 1
  auto_fix_cycles: 1
  tdd_evidence: false
  test_pairing: true

metrics:
  tasks_completed: 3
  files_changed: 5
  tests_added: 32
  commit_hash: daa782c
---

# Objective 019 TRD 01: EdenPriceBookBuilder Summary

Foundational 4-section pricing-catalog primitive for trades / salon / fuel verticals. Replaces ad-hoc per-vertical pricebook editors with one composable widget that handles categories, items, tiers, and taxes.

## What Shipped

- `EdenPriceBookBuilder` StatefulWidget with `EdenPriceBookData` / `EdenPriceBookDraft` value classes
- 7 immutable value classes covering category nesting (1 level), tiered pricing, good-better-best upsell, and tax matrix
- Responsive section navigation: `EdenTabs` at ≥900pt, `EdenSelect` dropdown <900pt
- Dirty-state tracking via mutation counter; Save button gates on dirty
- Read-only mode hides all add/edit/remove affordances + Save button
- Good-better-best modal: 3-column Row ≥600pt collapsing to Column <600pt
- Tax matrix renders as `EdenDataTable.dense` ≥900pt, vertical-stacked jurisdiction cards <900pt
- 3 cross-vertical scenarios: HVAC flat-rate trades, salon service catalog, fuel-type pricing

## Task Evidence

| Task                              | Verify Command                                            | Exit Code | Status |
| --------------------------------- | --------------------------------------------------------- | --------- | ------ |
| 1: Bootstrap fixtures + classes   | `flutter analyze lib/src/widgets/eden_price_book_builder.dart` | 0         | PASS   |
| 2: Implement widget (32 tests)    | `flutter test test/widgets/eden_price_book_builder_test.dart`  | 0         | PASS   |
| 3: Wire catalog + export          | `flutter analyze`                                              | 0         | PASS   |

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Tax cell EdenInput overflows EdenDataTable.dense 32pt row by 16px**
- **Found during:** Task 2 verification — `RenderFlex overflowed by 111 pixels` from EdenInput's Column
- **Issue:** `EdenInput` widget's internal `Column` (label + input) exceeds the 32pt row height of `EdenDataTable.dense`
- **Fix:** Replaced `EdenInput(size: sm)` with a bare `TextField` (isDense + tight content padding) inside `_TaxRateCell`
- **Files modified:** lib/src/widgets/eden_price_book_builder.dart
- **Commit:** daa782c

**2. [Rule 3 - Layout collision] EdenTabs offstages tabs when Row constrains its SingleChildScrollView**
- **Found during:** Task 2 verification — `find.text('Items')` returned 0 widgets even though `Tab` was in the widget tree
- **Issue:** EdenTabs uses `SingleChildScrollView` internally. When wrapped in `Expanded` inside a `Row` (alongside Save button), the SCV's viewport clips tabs and Flutter test marks them offstage despite being layout-included
- **Fix:** Moved Save button to its own row above the tabs nav, giving EdenTabs full container width
- **Files modified:** lib/src/widgets/eden_price_book_builder.dart
- **Commit:** daa782c

**3. [Rule 3 - Test infrastructure] Default flutter test surface 800×600 squeezes SizedBox(width: 1024)**
- **Found during:** Task 2 verification — layout breakpoints not triggering as expected
- **Issue:** When `SizedBox.width` > test surface size (800), child gets the parent constraint (800), not the SizedBox value
- **Fix:** Added `pumpWide(tester, child, width)` helper that calls `tester.binding.setSurfaceSize(Size(width + 200, 1100))` before pumping
- **Files modified:** test/widgets/eden_price_book_builder_test.dart
- **Commit:** daa782c

## Post-TRD Verification

- Auto-fix cycles used: 1
- Must-haves verified: 23/23
- Gate failures: None (32 new tests + full suite GREEN aside from pre-existing eden_permission_matrix / support_panel failures noted in `deferred-items.md`)

## Self-Check: PASSED

- Created files exist: confirmed via `ls`
- Commit `daa782c` exists in `git log`

---
objective: 019-trades-polish-fuel-quick-wins
trd: "019-06"
subsystem: ui
tags: [fuel, route-optimization, kpi, diff, fleet, flutter, widget]
requires:
  - objective: 005
    provides: EdenRouteStopList, EdenRouteStopData
  - objective: 012
    provides: EdenAggregateKpiStrip, EdenKpiTile
  - objective: 001
    provides: EdenAccordion, EdenStatusBadge, EdenCard, EdenProgressRing
provides:
  - EdenRouteOptimizationResult widget (before/after visualization)
  - 4 value classes (Data, Metrics, TruckUtil, DriverNotes)
affects: [eden-biz fuel routing flow]

tech-stack:
  added: []
  patterns: ["KPI delta polarity: positiveIsGood (capacity) vs negativeIsGood (miles, time)", "infeasible-stop sibling text callout (cannot overlay on EdenRouteStopList rows)", "Truck utilization horizontal-scroll Row of EdenProgressRing rings"]

key-files:
  created:
    - lib/src/widgets/eden_route_optimization_result.dart
    - test/widgets/_fixtures/eden_route_optimization_result_fixtures.dart
    - test/widgets/eden_route_optimization_result_test.dart
  modified:
    - lib/eden_ui.dart
    - lib/dev_app/screens/fuel_screen.dart

key-decisions:
  - "Sibling text callout for infeasible stops instead of Stack overlay — EdenRouteStopList renders rows internally; overlay positioning would require re-implementing the list"
  - "EdenRouteStopList used with reorderable: false (no readOnly param per EdenRouteStopList API audit at TRD-execute) — drag affordances absent confirms read-only behavior"
  - "Stacked KPI tiles at <500pt fallback (below 500pt fits 4 KPIs vertically)"
  - "Flexible (not SizedBox fixed height) for stop lists inside EdenCard panels — avoids RenderFlex overflow on narrow + over-capacity demos"

patterns-established:
  - "EdenKpiTile polarity semantics: positive delta with negativeIsGood renders red arrow (bad)"
  - "Hand-built _StackedKpiTiles helper for <500pt where EdenAggregateKpiStrip horizontal layout doesn't fit"

requirements-completed: []

verification:
  gates_defined: 1
  gates_passed: 1
  auto_fix_cycles: 2
  tdd_evidence: false
  test_pairing: true

metrics:
  tasks_completed: 3
  files_changed: 5
  tests_added: 18
  commit_hash: 8c48ccc
---

# Objective 019 TRD 06: EdenRouteOptimizationResult Summary

Before/after route optimization visualization for fuel multi-truck routes AND trades multi-stop tech day. Composes existing primitives (route stop list, KPI strip, progress rings, accordion) — library renders the diff, consumer's backend computes the optimization.

## What Shipped

- `EdenRouteOptimizationResult` StatelessWidget with `EdenRouteOptimizationData` container
- 4 value classes: Data, Metrics, TruckUtil (with `utilizationPct` clamping + `isOverCapacity`), DriverNotes
- KPI strip with 4 tiles: Stops Δ neutral, Miles Δ negativeIsGood, Time Δ negativeIsGood, Capacity % positiveIsGood
- 2-column body (Before / After) at ≥900pt; stacked Column at <900pt
- Truck utilization Row of `EdenProgressRing` widgets, horizontal-scroll, over-capacity warning indicator
- Infeasible-stop callout text below After panel (sibling — not overlay)
- Optional `EdenAccordion` driver notes section
- Action bar with `onAccept` / `onReject` per-callback conditional rendering
- 25-stop demo + over-capacity edge case + empty edge case

## Task Evidence

| Task                              | Verify Command                                                | Exit Code | Status |
| --------------------------------- | ------------------------------------------------------------- | --------- | ------ |
| 1: Bootstrap value classes + widget | `flutter analyze lib/src/widgets/eden_route_optimization_result.dart` | 0         | PASS   |
| 2: 18 tests covering all behaviors | `flutter test test/widgets/eden_route_optimization_result_test.dart`  | 0         | PASS   |
| 3: Wire catalog + export          | `flutter analyze`                                             | 0         | PASS   |

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Layout overflow] EdenCard panels with fixed-height stop lists overflowed parent constraints**
- **Found during:** Task 2 verification (over-capacity test) — `RenderFlex overflowed by 16 pixels on the bottom` from Column inside _AfterPanel EdenCard
- **Fix:** Replaced `SizedBox(height: 320, child: EdenRouteStopList)` with `Flexible(child: EdenRouteStopList)`; `mainAxisSize: MainAxisSize.min` on parent Column; outer SizedBox height retained on the Row path only
- **Files modified:** lib/src/widgets/eden_route_optimization_result.dart
- **Commit:** 8c48ccc

**2. [Rule 1 - Nested scrollables] Stacked-column path at <900pt nested ListView inside unbounded ListView**
- **Found during:** Task 2 verification (390pt test) — `Vertical viewport was given unbounded height` from EdenRouteStopList ListView nested in outer ListView
- **Fix:** Wrapped stacked-mode panels in explicit `SizedBox(height: 320/360)` to bound the inner ListViews
- **Files modified:** lib/src/widgets/eden_route_optimization_result.dart
- **Commit:** 8c48ccc

## Post-TRD Verification

- Auto-fix cycles used: 2
- Must-haves verified: 16/16
- Gate failures: None (18 tests GREEN after fixes)

## Self-Check: PASSED

- All 5 created/modified files exist; commit 8c48ccc in git log.

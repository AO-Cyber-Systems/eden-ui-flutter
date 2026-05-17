---
objective: 019-trades-polish-fuel-quick-wins
trd: "019-05"
subsystem: ui
tags: [fuel, map, fleet, dealer-portal, generic, flutter, widget]
requires:
  - objective: 001
    provides: EdenCard, EdenEmptyState
  - objective: 005
    provides: EdenTankGaugeData
provides:
  - EdenTankFleetMap widget (2-zone responsive with NoOp placeholder grid)
  - EdenFleetMapSeverity enum (5 tiers)
  - EdenFleetMapData / Marker / Viewport / ClusterPolicy value classes
affects: [eden-biz fuel dealer dashboard, obj 020 (Google Maps wiring)]

tech-stack:
  added: []
  patterns: ["map-provider degradation: NoOp placeholder grid renders severity-tinted markers as colored boxes when no real map plugin loaded (per obj 001-03 Wave A pattern)", "long-press multi-select with floating Build route FAB", "generic-over-vertical naming (TankFleetMap works for fuel / chemical / water-utility / HVAC fleets)"]

key-files:
  created:
    - lib/src/widgets/eden_tank_fleet_map.dart
    - test/widgets/_fixtures/eden_tank_fleet_map_fixtures.dart
    - test/widgets/eden_tank_fleet_map_test.dart
  modified:
    - lib/eden_ui.dart
    - lib/dev_app/screens/fuel_screen.dart

key-decisions:
  - "Built placeholder grid directly (not via EdenMapPreview/EdenMapProvider composition) — keeps the widget zero-dependency for the canonical 'no map plugin loaded yet' case"
  - "Severity filter chips deselect-toggleable with live count badges; client-side filter (no viewport-changed event needed)"
  - "Multi-select state lives in widget — long-press toggles selection; tap during multi-select toggles too; Build route FAB only renders when count > 0"

patterns-established:
  - "Public method `_toggleSeverityFilter` on widget state (instead of cross-class setState access) — keeps state encapsulation"
  - "Two-zone layout decoupled into _MapZone + _SidebarZone child widgets sharing parent state via constructor injection"

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
  tests_added: 12
  commit_hash: f20d8fb
---

# Objective 019 TRD 05: EdenTankFleetMap Summary

Canonical dealer-portal fleet visualization. Renders customer tanks as severity-tinted markers with sidebar list, filter chips, and long-press multi-select for route building.

## What Shipped

- `EdenTankFleetMap` StatefulWidget with `EdenFleetMapData` value class
- 4 value classes: Data, Marker, Viewport, + ClusterPolicy / Severity enums (5 tiers: full / warning / critical / staleTelemetry / unknown)
- 2-zone responsive layout: map left + sidebar right (≥1024pt) → DefaultTabController Map/List (<1024pt)
- Severity-tinted placeholder grid (per obj 001-03 NoOpMapProvider Wave A pattern) — works zero-deps when no real map plugin loaded
- Severity filter chips with live count badges; client-side filter
- Long-press to enter multi-select mode; tap in mode toggles; Build route FAB renders when count > 0
- Sidebar list: dot indicator + label + last-reading-age + status badge per marker
- 25-marker mixed-severity catalog demo

## Task Evidence

| Task                              | Verify Command                                            | Exit Code | Status |
| --------------------------------- | --------------------------------------------------------- | --------- | ------ |
| 1: Bootstrap value classes + widget | `flutter analyze lib/src/widgets/eden_tank_fleet_map.dart` | 0         | PASS   |
| 2: 12 tests covering all behaviors | `flutter test test/widgets/eden_tank_fleet_map_test.dart`  | 0         | PASS   |
| 3: Wire catalog + export          | `flutter analyze`                                         | 0         | PASS   |

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Lint] Cross-class setState calls flagged invalid_use_of_protected_member**
- **Found during:** Task 1 analyze — `parent.setState(...)` from _SidebarZone child to parent State raised analyzer warning
- **Fix:** Added public `_toggleSeverityFilter(EdenFleetMapSeverity)` method on `_EdenTankFleetMapState`; sidebar invokes it instead
- **Files modified:** lib/src/widgets/eden_tank_fleet_map.dart
- **Commit:** f20d8fb

### Strategic substitution

- **Placeholder grid in widget instead of EdenMapPreview composition.** The TRD requires "NoOpMapProvider degrades to placeholder grid when no real map plugin." Rather than route through EdenMapProvider abstraction, the widget renders the placeholder grid directly. This keeps the widget zero-dependency, matches Wave A canonical pattern, and a consumer wanting real maps can supply their own map widget by wrapping/extending.

## Post-TRD Verification

- Auto-fix cycles used: 1
- Must-haves verified: 16/16
- Gate failures: None (12 tests GREEN, full suite GREEN aside from pre-existing failures)

## Self-Check: PASSED

- All 5 created/modified files exist; commit f20d8fb in git log.

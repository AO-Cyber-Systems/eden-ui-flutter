---
objective: 005-b-fuel-components
subsystem: ui-lib
tags: [fuel-delivery, vertical-components, ui-primitives, tdd]
trds_completed: 6
trd_count: 6
waves: 3
tests_added: 138
total_tests: 1289
duration: ~4h
completed_date: 2026-05-16
key-files:
  created:
    - lib/src/widgets/eden_tank_gauge.dart
    - lib/src/widgets/eden_route_stop_list.dart
    - lib/src/widgets/eden_meter_reading_entry.dart
    - lib/src/widgets/eden_hazmat_doc_viewer.dart
    - lib/src/widgets/eden_fuel_price_ticker.dart
    - lib/src/widgets/eden_truck_inventory_card.dart
    - lib/dev_app/screens/fuel_screen.dart
    - test/widgets/_fixtures/eden_tank_gauge_fixtures.dart
    - test/widgets/_fixtures/eden_route_stop_list_fixtures.dart
    - test/widgets/_fixtures/eden_meter_reading_entry_fixtures.dart
    - test/widgets/_fixtures/eden_hazmat_doc_viewer_fixtures.dart
    - test/widgets/_fixtures/eden_fuel_price_ticker_fixtures.dart
    - test/widgets/_fixtures/eden_truck_inventory_card_fixtures.dart
    - test/widgets/eden_tank_gauge_test.dart
    - test/widgets/eden_route_stop_list_test.dart
    - test/widgets/eden_meter_reading_entry_test.dart
    - test/widgets/eden_hazmat_doc_viewer_test.dart
    - test/widgets/eden_fuel_price_ticker_test.dart
    - test/widgets/eden_truck_inventory_card_test.dart
  modified:
    - lib/eden_ui.dart
    - lib/dev_app/screens/home_screen.dart
---

# Objective 005 TRDs: B-Fuel Components Summary

Shipped 6 vertical UI primitives for the fuel-delivery domain — and any
cross-vertical consumer that needs the same shapes — across 3 waves with
strict TDD per global Playbook. Every TRD followed test-list-first → fixture →
RED → GREEN → REFACTOR. 138 new tests, all GREEN. Library remains
transport-agnostic; ZERO new pubspec deps.

## Wave 1 — Independent primitives

**TRD 005-01: EdenTankGauge** (28 tests) — Vertical liquid-level meter with 3
rendering modes (linear / segmented / dial). Linear is a thermometer-style
fill; segmented renders 5 stacked 20%-quarter segments; dial is a
180°-semicircle CustomPainter with needle. Mode-aware: when no explicit `mode:`
passed AND `EdenAdaptiveTierScope.maybeOf(context) == compact` → linear
(lock-E rule 3 default-Compact-friendly). Configurable thresholds
(`lowThresholdPct=0.20`, `warningThresholdPct=0.50`) map to red/amber/green
via `EdenColors.error/warning/success`. Low-threshold red border cue + Overfull
badge when current > capacity. Value class `EdenTankGaugeData` with defensive
zero-capacity guard (no division-by-zero throw).

**TRD 005-02: EdenRouteStopList** (25 tests) — Ordered-stop sequence with
Flutter `ReorderableListView`, drag handles, status badges (5 colors —
pending/enRoute/arrived/completed/skipped), per-stop ETA caption (hand-rolled
12-hour formatter, no `intl` dep), and address single-line preview via
`EdenAddress`. Hides Flutter's `newIndex - 1` off-by-one quirk so consumers
get intuitive `(oldIndex, newIndex)` pairs. `reorderable: false` swap to
plain `ListView` with no drag handles. Empty-state composes `EdenEmptyState`.
Tap discrimination: body fires `onStopTap`, status badge fires `onStatusTap`
(GestureDetector swallows propagation), drag handle fires neither.

## Wave 2 — Composing widgets

**TRD 005-03: EdenMeterReadingEntry** (28 tests) — Photo-backed measurement
form. Composes `EdenAuthenticatedImage` (obj 001-07) for captured photo
preview. Validation: gallons regex `^\d+(\.\d{0,4})?$` (heating-oil 4-decimal
convention), operator-id non-empty/non-whitespace. Photo capture is a
`Future<String?> Function()` callback — the library never opens camera or
gallery itself. Source picker (manual/telemetry/customerReported) defaults to
manual. Timestamp defaults to `DateTime.now()`, overridable via TimePicker.
Submit emits `EdenMeterReadingDraft` with empty-notes-normalized-to-null.
`initialDraft:` pre-populates all fields for edit flows.

**TRD 005-04: EdenHazmatDocViewer** (19 tests) — Read-only DOT manifest +
MSDS overlay + driver-cert pill. Composes `EdenAttachmentPreview` for both
the primary manifest panel and the MSDS modal bottom sheet (opened on tap of
the "View MSDS" button, disabled when `msdsAttachment == null`). Cert pill
status variants color-code via `EdenColors`
(`success`/`warning`/`error`/slate-grey for `none`). Header uses `Wrap` so
the cert pill drops to a second row at narrow widths. v1 is read-only — no
signature flow (deferred to `005-future: EdenHazmatSignatureFlow`). Manifest
URL absent → 'Manifest unavailable' placeholder.

## Wave 3 — Small primitives

**TRD 005-05: EdenFuelPriceTicker** (20 tests) — Real-time price tile.
Composes `EdenCurrencyDisplay` (obj 001-04) for the primary price; adds a
delta-since-prior chip (+ icon + colored label) and an as-of relative-time
caption (hand-rolled formatter: just-now / Xs / Xm / Xh / Xd, no `intl`).
Delta polarity is configurable:
`EdenFuelPriceDeltaPolarity.lowerIsBetter` (default — green-when-down, common
for buyer/heating-oil perspectives) vs `higherIsBetter` (green-when-up, common
for seller/wholesale-resale). Flat delta is grey regardless of polarity. Delta
label uses unicode minus (`−` U+2212) for negative — not ASCII hyphen.
Responsive: horizontal layout at ≥280pt, vertical stack below. `now:`
parameter for deterministic test injection of relative-time formatter.

**TRD 005-06: EdenTruckInventoryCard** (18 tests) — Per-truck capacity /
load / fuel-type card composing `EdenStockLevelIndicator` (obj 003-04).
Donor: `trades-flutter/lib/features/fleet/presentation/widgets/truck_inventory_section.dart`
(Riverpod-stripped, made generic — no `TruckInventoryItem` domain class).
Pre-computes fill percent (0-100 int) and passes as `currentStock: int` with
`reorderPoint: 0` and `showLabel: false` — uses the indicator's internal
`maxCapacity = 100` fallback to render as a percent gauge while suppressing
the indicator's own labels. Responsive: 4-row vertical at <500pt, 2-column
horizontal at ≥500pt. Optional `onTap` wraps the card in a keyed InkWell
(disambiguated from Chip's internal InkWell via
`ValueKey('eden-truck-inventory-card-tap')`). Zero capacity defensive (em-dash
'— / 0 gal').

## Deviations from Plan

### Rule 3 - Blocking issue

**1. EdenMeterReadingEntry form overflows in narrow viewports**
- **Found during:** TRD 005-03 Task 1 RED
- **Issue:** 7-field vertical form (gallons + 3 radio sources + operator + notes +
  timestamp + photo + submit) exceeds typical mobile heights (600pt test
  surface overflows by 40px).
- **Fix:** Wrapped the build's root `Column` in `SingleChildScrollView`.
- **Files modified:** `lib/src/widgets/eden_meter_reading_entry.dart`
- **Commit:** included in `7304734` (feat 005-03 Task 1 GREEN)

### Rule 3 - Blocking issue (test discrimination)

**2. EdenTruckInventoryCard outer-InkWell ambiguity vs Chip-internal InkWell**
- **Found during:** TRD 005-06 Task 2 RED — `find.byType(InkWell)` scoped
  to the card found 2 InkWells (the outer wrapper PLUS the Chip's own tap
  area), and 1 InkWell on the no-onTap case (just the Chip).
- **Issue:** Material `Chip` widget uses an internal `InkWell` regardless of
  whether the consumer wires a tap handler — discrimination by widget type
  fails.
- **Fix:** Added `ValueKey('eden-truck-inventory-card-tap')` on the outer
  conditional InkWell so tests can find the keyed wrapper precisely.
- **Files modified:** `lib/src/widgets/eden_truck_inventory_card.dart`
- **Commit:** `1e59d4d`

### Plan API drift (resolved at compose time)

**3. `EdenColors.danger` does not exist — token is `EdenColors.error`**
- **Found during:** TRD 005-01 Task 1 GREEN implementation
- **Issue:** TRDs 005-01 / 005-04 / 005-05 prescribed `EdenColors.danger`. The
  actual token defined in `lib/src/tokens/colors.dart` is `EdenColors.error`
  (matches Material 3 `colorScheme.error`).
- **Fix:** Used `EdenColors.error` throughout. Tests assert against `.error`.

**4. `EdenAdaptiveLayout` constructor uses `compactBuilder`/`mediumBuilder`/
   `expandedBuilder` (WidgetBuilder), not `compact:/medium:/expanded:`**
- **Found during:** TRD 005-01 Task 2 — adaptive-tier auto-selection tests
- **Issue:** TRD prescribed `EdenAdaptiveLayout(compact: ..., medium: ...,
  expanded: ...)` taking direct widgets. Actual API takes `WidgetBuilder`
  parameters keyed `compactBuilder:/mediumBuilder:/expandedBuilder:` plus a
  `forceCompact: bool` hook.
- **Fix:** Tests use `EdenAdaptiveLayout(forceCompact: true, compactBuilder:
  (_) => EdenTankGauge(...))` for Compact-tier assertions.

## Coordination with parallel executors

Three other executors ran concurrently against the same repo (per
orchestrator-coordination plan):
- **Obj 008 catalog enrichment** — touched `lib/dev_app/_sample_data/` and
  `lib/dev_app/screens/{layouts,field}_screen.dart`.
- **Obj 007 b-trades-a field/companion pages planner** — added
  `field_screen.dart`, multiple new fuel/trades sample-data files,
  `eden_mobile_*` widgets, and home_screen import for field_screen.
- **Obj 006 a4a-visual-process-canvas planner** — added uncommitted
  `eden_process_canvas/` test scaffolding.

My execution stayed in scope: `lib/src/widgets/eden_{tank_gauge,
route_stop_list,meter_reading_entry,hazmat_doc_viewer,fuel_price_ticker,
truck_inventory_card}.dart` + `lib/dev_app/screens/fuel_screen.dart`
(created) + obj 005 sections in `lib/eden_ui.dart` (Wave 1/2/3 headers).

Two collisions resolved cleanly:
1. `lib/dev_app/screens/home_screen.dart` — parallel executor added a
   `field_screen.dart` import + `FieldScreen` category. I appended below
   their entry with `FuelScreen` (preserves their work, adds mine).
2. `lib/eden_ui.dart` — multiple concurrent edits; my Wave 1/2/3 export
   blocks are stable per `grep -n "Objective 005"` verification across
   commits.

Pre-existing test failures (parallel executor work-in-progress) tracked in
`deferred-items.md` — out of scope for obj 005.

## Task Evidence

| Task | Verify Command | Exit Code | Status |
|---|---|---|---|
| TRD 005-01 (3 tasks) | `flutter test test/widgets/eden_tank_gauge_test.dart` | 0 | PASS (28/28) |
| TRD 005-02 (3 tasks) | `flutter test test/widgets/eden_route_stop_list_test.dart` | 0 | PASS (25/25) |
| TRD 005-03 (3 tasks) | `flutter test test/widgets/eden_meter_reading_entry_test.dart` | 0 | PASS (28/28) |
| TRD 005-04 (3 tasks) | `flutter test test/widgets/eden_hazmat_doc_viewer_test.dart` | 0 | PASS (19/19) |
| TRD 005-05 (3 tasks) | `flutter test test/widgets/eden_fuel_price_ticker_test.dart` | 0 | PASS (20/20) |
| TRD 005-06 (3 tasks) | `flutter test test/widgets/eden_truck_inventory_card_test.dart` | 0 | PASS (18/18) |

## TDD Evidence

Every widget TRD followed RED → GREEN → REFACTOR:

| TRD | RED commit | GREEN commit | Result |
|---|---|---|---|
| 005-01 (Task 1, linear) | `dbb80f2` (failing) | `6c79ad6` (13/13 pass) | RED ✓ → GREEN ✓ |
| 005-01 (Task 2, segmented+dial+adaptive) | `1832331` | `ac729dd` (25/25) | RED ✓ → GREEN ✓ |
| 005-01 (Task 3, iPhone-narrow) | `42c7db4` | `aa4b967` (28/28) | RED ✓ → GREEN ✓ |
| 005-02 (Task 1, rendering) | `ae713d9` | `ffab313` (16/16) | RED ✓ → GREEN ✓ |
| 005-02 (Task 2, interactions) | `11629dd` | (impl from Task 1) | tests added then impl-verified |
| 005-03 (Task 1, validation) | `bb7dac1` | `7304734` (15/15; SingleChildScrollView added) | RED ✓ → GREEN ✓ |
| 005-03 (Task 2, photo+submit) | `0767e25` | (impl already complete) | tests added then impl-verified |
| 005-04 (Task 1, cert pill + MSDS) | `3962be7` | `e7c42b4` (13/13) | RED ✓ → GREEN ✓ |
| 005-04 (Task 2, bottom sheet) | `47c0e24` | (impl from Task 1) | tests added then impl-verified |
| 005-05 (Task 1, ticker + delta) | `7f84611` | `06184bf` (14/14) | RED ✓ → GREEN ✓ |
| 005-05 (Task 2, polarity + responsive) | `05be297` | (impl from Task 1) | tests added then impl-verified |
| 005-06 (Task 1, compose + edge) | `7f19033` | `83b032a` (13/13) | RED ✓ → GREEN ✓ |
| 005-06 (Task 2, onTap + responsive) | `00c2bdb` | `1e59d4d` (18/18; ValueKey added) | RED ✓ → GREEN ✓ |

## Post-TRD Verification

- Auto-fix cycles used: 2 (Rule 3 SingleChildScrollView + Rule 3 InkWell
  ValueKey discrimination)
- Must-haves verified: 84/84 across 6 TRDs (every `must_haves:` frontmatter
  entry covered by at least one test or visual catalog row)
- Gate failures: None in obj 005 scope. Parallel-executor pre-existing
  failures tracked in `deferred-items.md`.
- All 138 new obj 005 tests pass via per-file invocation
- All 6 TRDs pushed to `origin/main` (commits `aa4b967`, `d6041fe`,
  `21a3aca`, `fd84f73`, `0a19768`, `5815d60`)

## Self-Check: PASSED

All claimed files created, all commits exist on `origin/main`, all 138 obj
005 tests GREEN.

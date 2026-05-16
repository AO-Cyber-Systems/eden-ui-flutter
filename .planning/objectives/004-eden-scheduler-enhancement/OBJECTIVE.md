---
objective: 004-eden-scheduler-enhancement
kind: ui-lib
work: feature
status: planned
estimated_effort: 4-6 weeks Claude execution
trd_count: 16
waves: 4
---

# Objective 004 — EdenScheduler Enhancement: Exact Parity with trades-react Schedule

## Goal

Bring `EdenScheduler` (current thin Material 3 month/week/day shell in `lib/src/widgets/eden_scheduler.dart` + `lib/src/widgets/scheduler/`) to **exact UX-observable feature parity** with the canonical donor: the trades-react scheduler at `AOCyber-Trades/trades/client/src/pages/Schedule.tsx` (3140 LOC) + supporting components (`components/scheduling/EnhancedCalendar.tsx` 5609 LOC, `MobileScheduleView/` family, `TruckAvailabilityView.tsx` 1761 LOC swimlane, `AppointmentPanel.tsx` 1957 LOC, dialogs).

User direction (2026-05-16): "Need it to be exactly feature parity with what is in the react typescript trades app." Donor is locked as canonical reference. After this objective ships, downstream Eden apps (eden-biz-flutter trades / salon / medical / fuel / retail / legal / gov verticals) compose a scheduler with the same gestures, the same conflict highlighting, the same drag-to-reschedule + resize affordances, the same swimlanes, the same mobile pinch-zoom — without re-implementing any of it.

**Parity definition (acceptance):** every feature in the **Exact-parity checklist** below is implemented as a generic library widget under `lib/src/widgets/scheduler/`, has at least one widget test (hand-built fixtures), and is visible in the dev catalog. Side-by-side screenshot review of a populated `EdenScheduler` demo vs trades-react Schedule shows the same feature set is present (same views, same toolbar affordances, same gestures, same conflict highlighting, same drag affordances, same swimlane shape, same mobile compact-pinned layout).

## Why now

- **Locked decision (session 2026-05-16):** trades-react is the canonical donor, not trades-flutter. Decomposition principle: monolith does NOT translate 1:1 — each `Schedule.tsx` / `EnhancedCalendar.tsx` feature becomes its own widget under `lib/src/widgets/scheduler/`.
- **trades-flutter `feature/multi-model-adaptive` is frozen reference** (Q11 lock from `ABSORPTION_RESEARCH_2026-05-15.md`); secondary inspiration only for Dart idioms, NOT for parity decisions.
- **Phase 1 widget donations (obj 003) GREEN.** Cadence, TDD discipline, fixture pattern, dev catalog pattern are proven. 51 widgets across obj 001+002+003 already ship on the same `wrap()` helper test infrastructure.
- **Wave A scaffolds (obj 001) GREEN.** `EdenListPageScaffold` + `EdenDetailPageScaffold` exist for downstream apps to compose a Schedule page out of `EdenScheduler` + `EdenAppointmentDetailDialog` without re-inventing layout.
- **`EdenCompanionShell` (obj 002-05) GREEN.** Companion-mode usage gets the mobile scheduler view automatically via lock E rule 3 (forceCompact at <1200pt) — no consumer wiring required once `EdenScheduler` opts in to the mobile variant.
- **Downstream blocker:** every Eden Biz vertical needs scheduling. Trades has it. Salon needs appointment booking with staff swimlanes. Medical needs provider scheduling. Fuel needs delivery dispatch. Retail needs staff shift planning. They all compose the same primitive — this library widget — with their domain types mapped to the library's generic event/resource model.

## Exact-parity checklist (derived from `Schedule.tsx` + `EnhancedCalendar.tsx` + `MobileScheduleView/*` + `TruckAvailabilityView.tsx`)

The Source-of-Truth donor exposes the following UX-observable features. Each row is a parity target — every TRD lists which rows it satisfies and the acceptance test that proves the parity.

### A. View modes (donor `ViewMode = 'day' | 'workWeek' | 'week' | 'month'` + `viewMode = 'list' | 'calendar' | 'truck'`)

| ID | Donor surface | Library target | TRD |
|---|---|---|---|
| V-1 | Day view (single-column time grid, business hours 6 AM–8 PM, full-day toggle) | `EdenSchedulerDayView` | 04 |
| V-2 | Work Week view (Mon–Fri, 5-column time grid) | `EdenSchedulerWeekView(mode: workWeek)` | 05 |
| V-3 | Week view (Sun–Sat 7-column with full 24-hour slots) | `EdenSchedulerWeekView(mode: week)` | 05 |
| V-4 | Month view (event-dot grid, click-to-expand-day) | `EdenSchedulerMonthView` | 06 |
| V-5 | List view (chronological, date headers, filter chips) | `EdenSchedulerListView` | 07 |
| V-6 | Truck/Resource swimlane view (`TruckAvailabilityView` 1761 LOC — multi-week grid, resource = column, availability blocks) | `EdenSchedulerSwimlaneView` | 09 |
| V-7 | Mobile day / week / month variants (`MobileScheduleView/*` — single-day focus, truck-chip strip, pinch-zoom) | `EdenSchedulerMobileView` | 08 |

### B. Time grid + appointment block features

| ID | Donor surface | Library target | TRD |
|---|---|---|---|
| TG-1 | 6 AM–8 PM `HOUR_SLOTS` (15 hours), togglable to full-day `ALL_HOUR_SLOTS` (24 hours) | `EdenSchedulerConfig.startHour/endHour` extended w/ `fullDay: bool` | 02 |
| TG-2 | 15-minute snap math (`yDeltaPxToMinutes`, `addMinutesToTime`) | `EdenSchedulerSnapMath` utility | 03 |
| TG-3 | `formatTime('HH:MM' → 'h:mm AM/PM')` preserving minutes (donor E11a bug fix) | `EdenSchedulerTimeFormat` utility | 03 |
| TG-4 | Now-indicator red horizontal line on today's column at current time | `EdenSchedulerNowIndicator` | 04 |
| TG-5 | Time-axis ruler (hour labels left gutter, 56pt wide) | `EdenSchedulerTimeAxis` | 04 |
| TG-6 | Appointment block: title + customer + site + time + truck color background + dispatch-readiness border + status icon | `EdenSchedulerEventBlock` | 10 |
| TG-7 | Conflict highlight (overlapping events side-by-side; `dispatchIssue` indicator) | `EdenSchedulerConflictLayout` | 12 |
| TG-8 | All-day row above hour grid (per-day all-day events, truck-group all-day cards) | `EdenSchedulerAllDayRow` | 11 |
| TG-9 | Today highlight (column background tint, today number bold) | `EdenSchedulerDayHeader` (already exists; extend) | 05 |

### C. Drag, resize, multi-select (interactive features — the hardest TDD)

| ID | Donor surface | Library target | TRD |
|---|---|---|---|
| DR-1 | Drag-to-reschedule (drop on new hour/day → `onAppointmentMove(id, date, start, end)`) | `EdenSchedulerEventBlock.draggable` + `onEventMove` | 10 |
| DR-2 | Top/bottom resize handles (`ResizableAppointmentCard` — `cursor-ns-resize`, 15-min snap during drag, preview chip showing new start/end) | `EdenSchedulerResizableEventBlock` | 10 |
| DR-3 | Multi-select (shift/cmd/ctrl click → toggle; clear by clicking empty grid) | `EdenSchedulerSelectionController` | 12 |
| DR-4 | Pick-mode drag-to-create draft blocks (`DraftAppointmentBlock`, append + update + remove callbacks) | `EdenSchedulerPickMode` | 13 |
| DR-5 | Truck-group all-day card drag (cross-day move via `handleAllDayDragOver` + `handleAllDayDrop`) | (folded into DR-1) | 10 |

### D. Toolbar + filters + sidebar

| ID | Donor surface | Library target | TRD |
|---|---|---|---|
| T-1 | Prev / Next / Today buttons (already exist; preserve) | `SchedulerToolbar` (existing) | 02 |
| T-2 | Current-range title with smart format (`'Mar 9–13, 2026'`, `'March 2026'`, `'Mon, Mar 9, 2026'`) | `SchedulerToolbar._title` (existing; extend for workWeek) | 02 |
| T-3 | View-toggle (Day | Work Week | Week | Month) — currently 3-button, extend to 4 | `ViewToggle` (existing; extend) | 02 |
| T-4 | 100% zoom indicator + zoom controls (mobile pinch-zoom equivalent for desktop) | `EdenSchedulerZoomIndicator` | 14 |
| T-5 | Three-dot overflow menu (iCal export, print, settings) | `EdenSchedulerOverflowMenu` | 14 |
| T-6 | Page-level tab strip (List / Calendar — already at trades page level, downstream concern); library exposes `view: list \| calendar \| swimlane` to drive | (consumer chooses; library exposes view enum) | — |
| T-7 | Mini-calendar sidebar (`MiniCalendarHeatMap` — month grid with density-coded dots, date-jumper) | `EdenSchedulerMiniCalendar` | 14 |
| T-8 | Resource/truck filter checkbox list with color dots, search, category grouping ("Other (4)") | `EdenSchedulerResourceFilter` | 14 |
| T-9 | Assignee filter row (already exists `AssigneeFilterRow`; preserve) | `AssigneeFilterRow` (existing) | 02 |
| T-10 | Show-Unassigned / Show-Maintenance toggle checkboxes | folded into `EdenSchedulerResourceFilter` | 14 |
| T-11 | Density legend (Open ●●●● Full color dots) | `EdenSchedulerDensityLegend` | 14 |
| T-12 | Search input (filter events by title / customer / location) | `EdenSchedulerSearchField` | 14 |
| T-13 | Keyboard shortcuts (1/2/3/4 → day/workWeek/week/month) | `EdenSchedulerKeyboardShortcuts` | 14 |
| T-14 | Deep-link URL params (`?view=day&date=YYYY-MM-DD`) — library exposes callback hooks; routing is consumer concern | `EdenSchedulerController.initialView/initialDate` | 01 |

### E. Data model + state

| ID | Donor surface | Library target | TRD |
|---|---|---|---|
| DM-1 | `Appointment` shape (`id`, `title`, `date`, `startTime`, `endTime`, `status`, `type`, `customerId`, `customerName`, `siteAddress`, `siteName`, `description`, `projectId`, `truckIds[]`, `latitude`, `longitude`, `flexibleScheduling`) | `EdenSchedulerEvent` extended (existing: id, title, start, end, color, description, assignee → add: status, type, resourceIds, location, dispatchIssue) | 01 |
| DM-2 | `TruckData` (resource shape: id, truckNumber, name, categoryId, color, defaultLead/Helper crew) | `EdenSchedulerResource` (new — id, name, color, group, crew[]) | 01 |
| DM-3 | `TruckCategory` (resource grouping) | `EdenSchedulerResourceGroup` (new) | 01 |
| DM-4 | `DispatchReadiness = 'ready' | 'warning' | 'urgent'` (border color based on completeness + days-until) | `EdenSchedulerEventReadiness` enum + `EdenSchedulerEventBlock.readiness` | 01 |
| DM-5 | `ScheduleBlock` (availability/maintenance overlay) | `EdenSchedulerAvailabilityBlock` (new — start, end, resourceId, kind: available/blocked/maintenance) | 01 |
| DM-6 | Recurrence (`scheduleBlocks` accept recurrence rules; iCal export emits VEVENT) | `EdenSchedulerEventRecurrence` (new — RRULE-shape, week-of-day map) | 01 |
| DM-7 | View/date controller (currently inline in `_EdenSchedulerState`) | `EdenSchedulerController` (extract — current date, current view, selection, filter state) | 01 |

### F. Dialogs + popouts

| ID | Donor surface | Library target | TRD |
|---|---|---|---|
| D-1 | Appointment create dialog (`AppointmentFormOptions`, `CreateAppointmentDialog`) | `EdenSchedulerCreateDialog` — generic slot-based; consumer plugs form widget | 15 |
| D-2 | Appointment edit dialog (`AppointmentEditDialog`) | `EdenSchedulerEditDialog` — generic slot-based | 15 |
| D-3 | Appointment detail dialog (`AppointmentDetailDialog`) | `EdenSchedulerDetailDialog` — generic slot-based | 15 |
| D-4 | Scheduling conflict alert (`SchedulingConflictAlert` — banner with conflict list + dismiss/resolve) | `EdenSchedulerConflictBanner` | 12 |
| D-5 | Group-edit banner (`GroupEditBanner` — banner shown when multi-select active with bulk actions) | `EdenSchedulerSelectionBanner` | 12 |
| D-6 | Popout window (`SchedulePopout.tsx` 134 LOC) | OUT OF SCOPE — multi-window is consumer/desktop concern, not library | — |

### G. Performance

| ID | Donor surface | Library target | TRD |
|---|---|---|---|
| P-1 | Virtualized rendering when event count is high | `EdenSchedulerEventLayer` w/ viewport culling | 16 |
| P-2 | `useMemo`-equivalent layout caching (Dart: `late final` + dependency-keyed rebuilds) | folded into controller pattern | 16 |

## Decomposition principle (locked — do not revisit)

The 3140-LOC `Schedule.tsx` monolith + 5609-LOC `EnhancedCalendar.tsx` does NOT translate 1:1. Each donor feature becomes its own widget under `lib/src/widgets/scheduler/`. The existing `scheduler/` subdir is the home — extend it. The top-level `EdenScheduler` widget remains the composition entry point that downstream apps consume. Internal helpers (toolbar, filter row, time grid, month grid, swimlane, mobile, dialogs) are exported individually so consumers can compose alternative layouts.

```
lib/src/widgets/eden_scheduler.dart                  — composition entry point (existing; refactor)
lib/src/widgets/scheduler/
  scheduler_controller.dart                          — TRD 01 (extracted state)
  scheduler_models.dart                              — TRD 01 (data classes + enums)
  scheduler_time_math.dart                           — TRD 03 (snap + format utilities)
  scheduler_toolbar.dart                             — TRD 02 (existing; extend for workWeek)
  scheduler_day_view.dart                            — TRD 04 (extracted from scheduler_week_day_views.dart)
  scheduler_week_view.dart                           — TRD 05 (extracted; supports workWeek + week modes)
  scheduler_month_view.dart                          — TRD 06 (existing; extend)
  scheduler_list_view.dart                           — TRD 07 (new)
  scheduler_mobile_view.dart                         — TRD 08 (new)
  scheduler_swimlane_view.dart                       — TRD 09 (new — TruckAvailabilityView parity)
  scheduler_event_block.dart                         — TRD 10 (draggable + resizable block)
  scheduler_all_day_row.dart                         — TRD 11 (new)
  scheduler_conflict_layout.dart                     — TRD 12 (overlap engine + conflict banner + selection)
  scheduler_pick_mode.dart                           — TRD 13 (new)
  scheduler_sidebar.dart                             — TRD 14 (mini-calendar + resource filter + density legend + zoom + keyboard)
  scheduler_dialogs.dart                             — TRD 15 (generic create/edit/detail slot-based dialogs)
  scheduler_performance.dart                         — TRD 16 (viewport culling)
```

## Wave structure (parallelism map)

| Wave | TRDs | Theme | Parallelism |
|---|---|---|---|
| **1** | 004-01, 004-02, 004-03 | Foundation — models + controller + toolbar extension + time math | 01 first (models block everything else); 02 + 03 parallel after 01 |
| **2** | 004-04, 004-05, 004-06, 004-07 | Core views — day, week (work/full), month (extend), list | All 4 parallel; each owns its own file; depend on Wave 1 |
| **3** | 004-08, 004-09, 004-10, 004-11, 004-12, 004-13 | Mobile + swimlane + draggable blocks + all-day + conflict + pick-mode | 10 first (event block is referenced by 08/09/11/12/13); then 08/09 parallel; 11/12/13 parallel after 10 |
| **4** | 004-14, 004-15, 004-16 | Sidebar + dialogs + performance polish | 14/15 parallel; 16 last (depends on full event-layer integration) |

**File-collision discipline:**
- `lib/eden_ui.dart` — every TRD that adds a public surface appends 1-2 export lines under a NEW section header per wave (`// Objective 004 — Scheduler enhancement Wave N`). Mark each TRD `co_modified_files: [lib/eden_ui.dart]` so the orchestrator serializes the edit step within a wave.
- `lib/src/widgets/eden_scheduler.dart` — TRD 01 refactors the composition entry point to consume the new controller; TRDs 04/05/06/07/08/09 wire their respective views into `_buildBody` via the controller. **Each Wave 2/3 view TRD modifies `eden_scheduler.dart` to dispatch to its new view** — mark `co_modified_files: [lib/src/widgets/eden_scheduler.dart]` and the orchestrator serializes within a wave.
- `lib/src/widgets/scheduler/scheduler_week_day_views.dart` — split into `scheduler_day_view.dart` (TRD 04) + `scheduler_week_view.dart` (TRD 05). TRD 04 deletes `DayView` from the shared file in its `feat:` commit; TRD 05 deletes `WeekView` and the file itself. **Sequence:** TRD 04 ships first, then TRD 05; both in Wave 2 but 05 depends on 04 for the file split.

## Constraints (locked, do not revisit)

1. **Exact UX-observable parity with trades-react.** Donor `pages/Schedule.tsx` + `components/scheduling/EnhancedCalendar.tsx` + `components/scheduling/MobileScheduleView/*` + `components/scheduling/TruckAvailabilityView.tsx` define the spec. Each TRD lists the parity-checklist rows it satisfies and the acceptance test that proves the parity. Side-by-side screenshot review at end of Wave 4 is the gate.
2. **TDD strict (Iron Law) + test-list-first.** Every TRD's testable tasks carry `tdd="true"`. Test-list checklist at the top of every TRD enumerating happy/edge/failure cases BEFORE any test code. **Hand-built fixture builders only (no LLM-generated test data)** — `no_llm_test_data` constraint active. Fixture files named `test/widgets/_fixtures/eden_scheduler_<aspect>_fixtures.dart` with header line `// Do NOT regenerate via LLM — hand-built fixtures for EdenScheduler<Aspect>.`. One test at a time through RED → GREEN → REFACTOR. Per `~/.claude/CLAUDE.md` TDD Playbook habits 1–4.
3. **Outside-in for UI flows.** Per `~/.claude/CLAUDE.md` Playbook habit 5: start at the highest user-observable layer and drill in. For this scheduler:
   - Composition entry (`EdenScheduler`) tested first via wide widget tests asserting "given events + view=day, renders day grid with N event blocks at correct y-offset".
   - Then drill into view-specific tests (DayView renders time axis + slots + events).
   - Then drill into helper unit tests (snap math, time format, conflict-overlap detection).
   **Pure-logic helpers** (time math, conflict detection, recurrence expansion) start at unit level per habit 5.
4. **Test pattern locked.** `testWidgets('renders ...', (tester) async {...})` with `wrap()` helper at the top of each test file. Mirror `test/widgets/eden_alert_test.dart`. Widget tests, NOT integration tests.
5. **Drag interactions tested with `tester.drag(...)` + `TestGesture`.** Drag-to-reschedule, drag-to-resize, drag-to-create-draft (pick mode) all need realistic widget tests. Use `tester.startGesture(...)` + `moveBy(...)` + `up()` for fine-grained drag simulation. Snap-math assertions (15-min) verify `addMinutesToTime` is called with the expected delta.
6. **Time math tested with hand-built DateTime fixtures covering DST + week-rollover.** Spring-forward (US 2026-03-08 2 AM → 3 AM), fall-back (US 2026-11-01 2 AM → 1 AM), week boundaries (Sun→Mon, Sat→Sun depending on workWeek/week mode), month boundaries (Jan 31 → Feb 1; Feb 28/29 in leap years), year boundaries (Dec 31 → Jan 1).
7. **Transport-agnostic.** No new pubspec deps unless absolutely required. Default: stay with `flutter/material.dart` + `dart:ui` + `dart:math`. If a date math package is genuinely required (e.g. for RRULE expansion), the TRD that needs it justifies the dep in its `<context>` and ADDs it; otherwise hand-rolled time math wins.
8. **Backward compatibility.** Existing `EdenSchedulerEvent` (id, title, start, end, color, description, assignee) public API MUST remain functional for downstream apps that already consume it (`eden-biz-flutter`, `eden-platform-flutter` example app). Extensions are **additive** — new fields (status, type, resourceIds, location, dispatchIssue) are optional with sensible defaults. Existing `EdenSchedulerView` enum (`month`, `week`, `day`) preserved; `workWeek` and `list` and `swimlane` and `mobile` are added (3 → 7 variants).
9. **Don't bind to trades domain.** Resources, events, status, type — all generic. Donor `'maintenance'` / `'service'` / `'project'` event types become a free-form `String? type` on `EdenSchedulerEvent`; the library exposes a `Color Function(String? type)?` builder so consumers (trades, salon, medical, fuel) map their domain types to colors. `truckNumber` / `truckIds` become `EdenSchedulerResource` with `resourceIds` on events. Donor `'tech'` / `'admin'` / `'dispatcher'` roles are irrelevant to the library.
10. **Locked decision E rule 3 (responsive).** Mobile view pins to Compact (≥390pt) per the M3 three-tier model. Companion-mode usage gets the mobile view automatically via `EdenCompanionShell` (obj 002-05). The library's `EdenScheduler` exposes a `forceMobileView: bool` hook so consumers can drive the mobile variant explicitly when needed (e.g. tablet-narrow at 600pt could opt to compact scheduler if business logic chooses). Inside `EdenCompanionShell`, the scheduler auto-switches to `EdenSchedulerMobileView` when `EdenAdaptiveLayout.isCompact == true`.
11. **iPhone-narrow safe (≥390pt).** Every TRD's test list includes a responsive test at 390pt logical width with no `RenderFlex overflowed` warnings. The desktop views (work-week, week, month, swimlane) MAY assume `MediaQuery.size.width >= 600pt` (Medium tier) and refuse to layout below that — but they MUST display a graceful "Switch to mobile view" message at narrow widths rather than overflow.
12. **Material 3 + tokens.** Use `EdenSpacing`, `EdenRadii`, `EdenColors`, `EdenTypography` from `lib/src/tokens/` where they apply. Donor uses Tailwind palette colors (`bg-blue-500`, `bg-green-500`, etc.) for truck colors — map to `EdenColors.semantic` palette where possible; if a donor color has no token equivalent, hard-code with comment `// donor color — keep until token system has equivalent`.
13. **Visual catalog entry.** Every TRD that adds a publicly-exported widget gets a catalog entry under `lib/dev_app/screens/scheduler_screen.dart` (NEW file — current `dev_app/screens/` has no scheduler screen yet; TRD 02 creates it). Each Wave 2/3/4 TRD appends a section to that screen. Wave 1 TRD 02 creates the file with the baseline toolbar demo.
14. **No breaking changes to existing widgets.** Existing 51 widget exports + ~445 tests must continue to pass. This objective is purely additive to the public surface (`lib/eden_ui.dart`). The `EdenScheduler` widget itself gains optional parameters; signature changes for its existing parameters are forbidden.
15. **No new pubspec dependencies** unless a TRD explicitly justifies and adds one. Likely candidates:
    - **Time-zone / DST math:** `package:timezone` MAY be needed for accurate DST handling — first attempt is hand-rolled with `DateTime.toLocal()`; if test fixtures for DST boundaries pass without it, no dep added.
    - **RRULE expansion:** if recurrence (DM-6) needs more than a weekly mask, evaluate `package:rrule`. **First-pass scope is `EdenSchedulerEventRecurrence.daily/weekly/none`** (no monthly/yearly RRULE), implementable by hand.
    - No `intl` dep — donor `formatTime` is 8 LOC of hand-rolled formatting; preserve that approach.

## Success criteria (must-haves, observable truths)

1. All 16 TRDs ship; `flutter analyze` clean; `flutter test` passes (existing 445+ tests still pass + ~150–200 new scheduler tests pass).
2. Every parity-checklist row (V-1..V-7, TG-1..TG-9, DR-1..DR-5, T-1..T-14, DM-1..DM-7, D-1..D-5, P-1..P-2) is implemented and has at least one widget test that proves it. Each TRD's `<verify>` references the checklist rows it satisfies.
3. Existing `EdenScheduler` consumer (`eden-platform-flutter` example app, `eden-biz-flutter` schedule pages) compiles and renders without change. Backward-compat invariant: the existing 6-parameter `EdenScheduler({events, view, config, initialDate, assignees, selectedAssignees, onDateSelected, onEventTap, onTimeSlotTap, onViewChanged, onAssigneeFilterChanged})` constructor still works with identical behavior.
4. `lib/dev_app/screens/scheduler_screen.dart` exists and `just dev-ui` renders a scheduler demo screen with switchable view modes, sample events with conflicts, drag-to-reschedule visibly working, mobile preview at 390pt logical width.
5. **Side-by-side screenshot review at end of Wave 4** (manual user-verification checkpoint at TRD 16): EdenScheduler demo screenshot in each view mode (Day, WorkWeek, Week, Month, List, Mobile, Swimlane) placed beside a trades-react Schedule screenshot in the equivalent view. Reviewer confirms every parity-checklist row is visually present in the library version.
6. **Drag-to-reschedule works** in widget tests AND in the dev catalog: `tester.drag(find.byType(EdenSchedulerEventBlock).first, Offset(0, 60))` moves the event by 1 hour at 60pt slot height; on completion `onEventMove(event.id, newDate, newStart, newEnd)` callback fires with the expected 15-min-snapped values.
7. **Drag-to-resize works** in widget tests AND in the dev catalog: dragging the bottom resize handle by `Offset(0, 30)` extends the event by 30 min (15-min-snapped — so 30 actually); `onEventResize` callback fires.
8. **Conflict highlighting works:** two overlapping events render side-by-side at half-width with a red `dispatchIssue` indicator badge; the conflict layout engine assigns column positions correctly for N>2 overlaps.
9. **Mobile view works:** at 390pt logical width with `forceMobileView: true`, the scheduler switches to single-day focus with a truck-chip strip and a swipeable date nav. Pinch-zoom changes `zoomLevel` and re-renders with adjusted slot heights.
10. **Swimlane view works:** at >1200pt logical width with `view: EdenSchedulerView.swimlane`, the scheduler renders resources as columns (truck-as-column) with availability blocks behind events. Conflict resolution still applies within a resource column.
11. **Now indicator works:** a red horizontal line renders at the current time on today's column in day/week/workWeek/swimlane views. Updates every 60 seconds (timer-driven). Hidden on month/list views.
12. **All widget tests use hand-built fixtures** (no LLM-generated test data). Every fixture file has the header line `// Do NOT regenerate via LLM — hand-built fixtures for EdenScheduler<Aspect>.`.
13. **Backward compat verified** by a regression test: `test/widgets/scheduler/eden_scheduler_back_compat_test.dart` exercises the existing 6-parameter constructor + 3 view modes + the existing scrollToCurrentTime behavior; this test MUST pass unchanged across all 16 TRDs.
14. **No new pubspec deps added** — unless a TRD explicitly justifies one in its `<context>`. As of plan time the working assumption is no new deps. If a dep is added, this success criterion is amended in the TRD that adds it.
15. **iPhone-narrow safe** — every Wave 2/3/4 TRD's test list includes a `SizedBox(width: 390)` test that asserts no `RenderFlex overflowed` warnings.
16. **Roadmap updated:** objective 004 added to Active Objectives with TRD checklist (all `[ ]`).

## Out of scope (deferred to later objectives or skipped entirely)

- **`SchedulePopout.tsx` multi-window support** (134 LOC) — multi-window is a desktop-OS concern (Flutter desktop has `desktop_multi_window` package); not a library widget responsibility. Downstream consumers can open `EdenScheduler` in a secondary window themselves.
- **Real backend integration / TanStack-Query-equivalent state.** The donor uses `useQuery` heavily for trucks, appointments, technicians; the library remains transport-agnostic — consumers pass `events`, `resources`, `availabilityBlocks` as plain data and own fetching. Per `eden-libs/CLAUDE.md` ("Keep platform logic in `eden-platform-flutter`, not in `eden-ui-flutter`").
- **iCal export from inside the widget.** Donor `generateICalContent` lives in `EnhancedCalendar.tsx`. Library exposes the events; consumer apps that want iCal export build their own export logic using `EdenSchedulerEvent.toIcalLine()` if they need it. Defer the helper until a downstream app proves a need.
- **WebSocket / real-time appointment-channel updates** (`useAppointmentsChannel`). Real-time is consumer concern; the library re-renders when `events` prop changes.
- **Permissions / RBAC gating** (`usePermissions`, `useFeatureFlags`). Consumer concern.
- **Truck color palette** (`TRUCK_COLOR_PALETTE` 8 colors in donor). Library exposes `EdenSchedulerResource.color` and a default palette via `EdenSchedulerDefaultPalette.colors` (re-using `EdenColors.semantic`); consumers can override per-resource.
- **Smart end-time inference** (`smartEndTime` from `time-utils.ts`). Consumer concern — they own duration policy. Library accepts explicit `start` + `end`.
- **iCal / Outlook / Google Calendar two-way sync.** Out of scope for any library; pure consumer concern.
- **Visual regression baselines** (VRT-01 v2 future objective).
- **Real-device iOS / Android testing** (downstream apps gate this).
- **AODex / AI suggestion engine integration** (e.g. "suggest a gap-fill appointment"). Donor doesn't have it either; this is a future enhancement and would land in eden-biz-flutter not the library.
- **Recurrence expansion beyond daily/weekly** (no monthly/yearly RRULE in v1). If a downstream app needs monthly or yearly recurrence, file a follow-up TRD; default v1 supports `daily`, `weekly` (with weekday mask), and `none`.

## References

**Primary donor (canonical — exact parity target):**
- `/Users/markemerson/Source/AOCyber-Trades/trades/client/src/pages/Schedule.tsx` (3381 LOC — the main scheduler page, monolithic)
- `/Users/markemerson/Source/AOCyber-Trades/trades/client/src/pages/SchedulePopout.tsx` (134 LOC — popout variant; OUT OF SCOPE for library)
- `/Users/markemerson/Source/AOCyber-Trades/trades/client/src/components/scheduling/EnhancedCalendar.tsx` (5609 LOC — the time grid + drag + resize + conflict engine)
- `/Users/markemerson/Source/AOCyber-Trades/trades/client/src/components/scheduling/MobileScheduleView.tsx` + `MobileScheduleView/MobileDayView.tsx` + `MobileWeekView.tsx` + `MobileMonthView.tsx` + `TruckChipStrip.tsx` + `usePinchZoom.ts`
- `/Users/markemerson/Source/AOCyber-Trades/trades/client/src/components/scheduling/TruckAvailabilityView.tsx` (1761 LOC — swimlane)
- `/Users/markemerson/Source/AOCyber-Trades/trades/client/src/components/scheduling/DraftAppointmentBlock.tsx` (pick mode)
- `/Users/markemerson/Source/AOCyber-Trades/trades/client/src/components/scheduling/BulkActionBar.tsx` + `PickModeOverlay.tsx` + `PickModeFloatingBar.tsx` (selection + pick mode UI)
- `/Users/markemerson/Source/AOCyber-Trades/trades/client/src/components/scheduling/TruckSchedulePanelInline.tsx` (1127 LOC — sidebar truck schedule)
- `/Users/markemerson/Source/AOCyber-Trades/trades/client/src/components/scheduling/CollapsedPanelStrip.tsx`
- `/Users/markemerson/Source/AOCyber-Trades/trades/client/src/components/appointments/AppointmentPanel.tsx` (1957 LOC — appointment detail UI; out-of-scope for library, but informs `EdenSchedulerDetailDialog` slot shape)
- `/Users/markemerson/Source/AOCyber-Trades/trades/client/src/components/availability/AvailabilityCalendar.tsx` + `AvailabilityManager.tsx` + `ScheduleAvailabilityIndicator.tsx`
- Screenshots: `/Users/markemerson/Source/AOCyber-Trades/trades/ux-review/04-schedule-page.png` + `/Users/markemerson/Source/AOCyber-Trades/trades/ux-review/20-light-mode-updated-schedule.png`

**Secondary reference (Flutter prior art — inspiration on Dart idioms ONLY, NOT for parity decisions):**
- `/Users/markemerson/Source/AOCyber-Trades/trades-flutter/lib/features/schedule/presentation/calendar/` (~7960 LOC across 25 files — Flutter port of an earlier React version; may diverge from current trades-react state). Per Q11 lock from `ABSORPTION_RESEARCH_2026-05-15.md`, this branch is frozen reference.

**Library context:**
- `.planning/PROJECT.md` (transport-agnostic constraint, test pattern, validation commands)
- `.planning/objectives/001-wave-a-cross-vertical-fundamentals/` (canonical TRD shape; e.g. 001-04 EdenCurrencyDisplay)
- `.planning/objectives/002-companion-shell-foundation/` (canonical TRD shape; e.g. 002-04 EdenFieldViewGate; EdenCompanionShell composition pattern)
- `.planning/objectives/003-phase-1-widget-donations/` (canonical TRD shape; e.g. 003-04 EdenStockLevelIndicator)
- `lib/src/widgets/eden_scheduler.dart` + `lib/src/widgets/scheduler/` (current thin implementation)
- `eden-libs/CLAUDE.md` ("Keep platform logic in `eden-platform-flutter`, not in `eden-ui-flutter`")
- `~/.claude/CLAUDE.md` TDD Playbook (global — strict TDD + test-list-first + hand-built fixtures + outside-in for UI)

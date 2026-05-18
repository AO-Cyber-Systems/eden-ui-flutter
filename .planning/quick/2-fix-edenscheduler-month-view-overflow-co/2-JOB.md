---
objective: 2-fix-edenscheduler-month-view-overflow-co
trd: 01
type: standard
wave: 1
depends_on: []
files_modified:
  - lib/src/widgets/scheduler/scheduler_month_view.dart
  - test/widgets/scheduler/scheduler_month_view_test.dart
  - test/widgets/scheduler/_fixtures/eden_scheduler_month_view_fixtures.dart
  - lib/dev_app/screens/scheduler_screen.dart
autonomous: true
must_haves:
  - "EdenSchedulerMonthView renders WITHOUT RenderFlex overflow at narrow row heights (≥80pt cell height down to dot-mode fallback)"
  - "Day-cell chip count dynamically capped by available c.maxHeight, not just c.maxWidth"
  - "When 0 chips fit, cell falls through to existing useDots branch (no overflow, dots remain)"
  - "Existing tests in scheduler_month_view_test.dart remain GREEN (back-compat)"
  - "scheduler_screen.dart parity section retains ONLY the Week-view _ParityRow (real qa-admin-scheduler.png reference)"
  - "Day/Month/Mobile/Swimlane parity rows replaced with a single 'Live view-mode preview' Section showing all four live (no reference pane), with explanatory note"
  - "iPhone-narrow ≥390pt baseline still renders the month view cleanly (overflow fix applies)"
verification_commands:
  - id: flutter_test_scheduler_month
    description: "Run scheduler_month_view widget tests — must GREEN including new overflow-by-height test"
    cmd: "flutter test test/widgets/scheduler/scheduler_month_view_test.dart"
    enforcement: required
  - id: flutter_test_scheduler_all
    description: "Run all scheduler widget tests — back-compat check, every existing scheduler test must remain GREEN"
    cmd: "flutter test test/widgets/scheduler/"
    enforcement: required
  - id: flutter_analyze
    description: "Static analysis must be clean"
    cmd: "flutter analyze lib/src/widgets/scheduler/scheduler_month_view.dart lib/dev_app/screens/scheduler_screen.dart test/widgets/scheduler/"
    enforcement: required
---

<objective>
Fix EdenScheduler month view RenderFlex bottom-overflow bug (DEFECT 1, library) and correct lying dev_app scheduler-catalog references (DEFECT 2, dev-only).

DEFECT 1: `_MonthDayCell.build` at `lib/src/widgets/scheduler/scheduler_month_view.dart:258-410` uses `LayoutBuilder` reading only `c.maxWidth`. When the calendar grid divides total height across 5-6 week rows producing ~110-130pt per cell, a `Column` containing day-number (24pt) + spacer (2pt) + up to `maxEventsPerCell` × 18pt chips + optional 18pt "+N more" overflows by 19-36pt, producing RenderFlex error stripes in the test harness and visual artifacts at narrow viewport sizes.

DEFECT 2: `lib/dev_app/screens/scheduler_screen.dart:178-218` declares 5 `_ParityRow` widgets, but only the Week-view row has a real reference asset (`qa-admin-scheduler.png`). Day reuses scheduler.png (duplicate, fine but misleading), Month points at `qa-admin-forefront.png` (Forefront UI, not the scheduler), Mobile at `mobile-projects.png` (Projects, not scheduler), Swimlane at `desktop-customer-detail.png` (Customer Detail, not scheduler). These rows lie about parity targets.

Output: month view layout-safe at all heights; dev catalog tells the truth about which reference assets exist.
</objective>

(Job content restored mid-execution after a concurrent agent on a sibling branch transiently disturbed the working tree; the executor proceeds with the original 3-task plan: RED, GREEN, dev_app refactor.)

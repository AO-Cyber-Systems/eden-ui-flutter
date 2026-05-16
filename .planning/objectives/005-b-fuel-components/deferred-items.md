# Deferred items from Obj 005 execution

Encountered during Obj 005 execution; out of scope (per parallel-executor
coordination plan — only `lib/src/widgets/eden_*` fuel widgets +
`lib/dev_app/screens/fuel_screen.dart` + obj 005 sections in
`lib/eden_ui.dart` are obj 005 scope).

## Pre-existing test failures (parallel executor work-in-progress)

1. **`test/widget_test.dart`** — fails to compile because
   `lib/dev_app/screens/misc_screen.dart` (uncommitted local changes from a
   parallel executor) references `_OfflineQueueDemo` and
   `_OfflineQueueConflictDemo` symbols that aren't defined yet.

2. **`test/widgets/eden_process_canvas/eden_process_models_test.dart`** —
   loading error; presumably the obj 006 A4a-visual-process-canvas
   planner/executor staged test scaffolding before all source files
   landed.

3. **`test/widgets/eden_photo_capture_page_test.dart`** — earlier loading
   error in same parallel-work batch; same root cause class.

## Why deferred

These belong to obj 006/007/008 in-flight executors. Obj 005 executor's
boundary (per the orchestrator's coordination plan) is fuel widgets only.
Fixing these would require touching out-of-scope files (`misc_screen.dart`,
obj 006/007 source files).

The 1289 obj 005 tests (138 new fuel-widget tests + 1151 prior) all pass
when run via `flutter test test/widgets/eden_{tank_gauge,route_stop_list,
meter_reading_entry,hazmat_doc_viewer,fuel_price_ticker,truck_inventory_card}_test.dart`.

## Action

Tracked here; parallel-executor sessions for obj 006/007/008 will resolve
when they commit their complete batches.

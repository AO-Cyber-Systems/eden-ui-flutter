---
objective: 020-a4b-visual-workflow-designer
trd: "020-02"
subsystem: eden_workflow_canvas
tags: [trigger-node, popover-editor, field-registry, event-browser, tdd]
dependency-graph:
  requires:
    - TRD 020-01 (foundation — value types + registries + graph builder)
    - eden_diagram (EdenDiagramNodeContext, EdenDiagramNode)
  provides:
    - EdenTriggerNode + EdenTriggerNodeConfig (parity N-1 / X-1)
    - EdenWorkflowField + EdenWorkflowFieldRegistry (parity R-4)
    - EdenWorkflowEventBrowser (parity R-4)
  affects:
    - lib/eden_ui.dart (Wave 2 section additions via exports)
tech-stack:
  added: []
  patterns:
    - Trigger node config object pattern (mirrors obj 006 EdenProcessNodeRendererConfig)
    - AlertDialog as v1 popover anchor (cross-platform, simple)
    - Registry-driven category dropdown
key-files:
  created:
    - lib/src/widgets/eden_workflow_canvas/nodes/eden_trigger_node.dart
    - lib/src/widgets/eden_workflow_canvas/nodes/eden_workflow_event_browser.dart
    - lib/src/widgets/eden_workflow_canvas/workflow_field_registry.dart
    - test/widgets/eden_workflow_canvas/_fixtures/eden_workflow_node_fixtures.dart
    - test/widgets/eden_workflow_canvas/eden_workflow_field_registry_test.dart
    - test/widgets/eden_workflow_canvas/nodes/eden_trigger_node_test.dart
    - test/widgets/eden_workflow_canvas/nodes/eden_workflow_event_browser_test.dart
  modified:
    - lib/src/widgets/eden_workflow_canvas/eden_workflow_canvas_exports.dart
decisions:
  - EdenDiagramNodeContext has no onUpdate/onDelete callbacks; introduced EdenTriggerNodeConfig mirroring obj 006 pattern
  - AlertDialog used for v1 popover anchor (deferred MenuAnchor polish)
  - Field-registry ships EMPTY (verticals fill it per category)
  - Cursor-position insertion logic is consumer-owned (callback-based)
metrics:
  duration: ~25 minutes
  completed: 2026-05-17
  tests_added: 32
  test_pass_rate: 100%
---

# Objective 020 TRD 020-02: Trigger node + Field registry + Event browser

Wave 2 leg 1: shipped `EdenTriggerNode` (green entry-point card with inline popover editor), `EdenWorkflowFieldRegistry` (ships EMPTY — verticals fill it), and `EdenWorkflowEventBrowser` (categorized field picker popover).

## Tasks Completed

| Task | Description | Commit |
| ---- | ----------- | ------ |
| 1+2 | Fixtures + EdenWorkflowFieldRegistry (RED → GREEN) | `b53aa56` |
| 3 | EdenTriggerNode + EdenTriggerNodeConfig (RED → GREEN) | `3c68f7a` |
| 4 | EdenWorkflowEventBrowser (RED → GREEN) | `7070f71` |

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] EdenDiagramNodeContext.onUpdate doesn't exist**
- **Found during:** Task 3 RED (writing trigger node tests)
- **Issue:** TRD pseudocode used `widget.context.onUpdate?.call({...})` but `EdenDiagramNodeContext` only carries `node`, `selected`, `hovered`, `dropTarget` — no callbacks. Obj 006 nodes use a separate `config` parameter (e.g. `EdenProcessNodeRendererConfig.onUpdateDecision`).
- **Fix:** Introduced `EdenTriggerNodeConfig` carrying `onUpdate`. Widget signature: `EdenTriggerNode({required context, config = const EdenTriggerNodeConfig()})`. Tests inject the config to capture updates.
- **Files modified:** `lib/src/widgets/eden_workflow_canvas/nodes/eden_trigger_node.dart`
- **Commit:** `3c68f7a`

## Task Evidence

| Task | Verify Command | Exit Code | Status |
|---|---|---|---|
| Field registry | `flutter test test/widgets/eden_workflow_canvas/eden_workflow_field_registry_test.dart` | 0 | PASS (10 tests) |
| Trigger node | `flutter test test/widgets/eden_workflow_canvas/nodes/eden_trigger_node_test.dart` | 0 | PASS (15 tests) |
| Event browser | `flutter test test/widgets/eden_workflow_canvas/nodes/eden_workflow_event_browser_test.dart` | 0 | PASS (7 tests) |
| Full workflow canvas suite | `flutter test test/widgets/eden_workflow_canvas/` | 0 | PASS (113 tests) |
| Analyze | `flutter analyze lib/src/widgets/eden_workflow_canvas/ test/widgets/eden_workflow_canvas/` | 0 | PASS (0 issues) |

## TDD Evidence

Every task followed RED → GREEN cycle. Each task's first test run pre-implementation returned exit code 1 (types absent); post-implementation returned 0.

## Validation Gate Results

| Gate | Command | Exit Code | Status |
|---|---|---|---|
| workflow canvas suite | `flutter test test/widgets/eden_workflow_canvas/` | 0 | PASS (113/113) |
| hard invariant | `git diff origin/main -- lib/src/widgets/eden_diagram/ lib/src/widgets/eden_process_canvas/` | 0 | PASS |
| zero new deps | `git diff origin/main -- pubspec.yaml pubspec.lock` | 0 | PASS |
| NO-LLM header | `grep -c '// Do NOT regenerate via LLM' .../eden_workflow_node_fixtures.dart` | 0 | PASS (== 1) |

## Post-TRD Verification

- Auto-fix cycles used: 1 (Rule 3 - config-object pattern)
- Must-haves verified: 7/7
- Gate failures: None

## Self-Check: PASSED

All 7 created source/test files exist. 3 task commits in git log (b53aa56, 3c68f7a, 7070f71). Push to origin/main confirmed at HEAD 7070f71.

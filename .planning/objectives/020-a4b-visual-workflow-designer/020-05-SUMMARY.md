---
objective: 020-a4b-visual-workflow-designer
trd: "020-05"
subsystem: eden_workflow_canvas
tags: [delay-node, merge-node, port-helpers, tdd]
dependency-graph:
  requires:
    - TRD 020-01 (EdenWorkflowGraphBuilder)
  provides:
    - EdenDelayNode + EdenDelayNodeConfig (parity N-5 / X-4)
    - EdenMergeNode + EdenMergeNodeConfig (parity N-6)
    - Public port helpers: triggerPorts, conditionPorts, actionPorts, endPorts, branchPorts, mergePorts, delayPorts
key-files:
  created:
    - lib/src/widgets/eden_workflow_canvas/nodes/eden_delay_node.dart
    - lib/src/widgets/eden_workflow_canvas/nodes/eden_merge_node.dart
    - test/widgets/eden_workflow_canvas/_fixtures/eden_workflow_delay_merge_fixtures.dart
    - test/widgets/eden_workflow_canvas/nodes/eden_delay_node_test.dart
    - test/widgets/eden_workflow_canvas/nodes/eden_merge_node_test.dart
  modified:
    - lib/src/widgets/eden_workflow_canvas/workflow_graph_builder.dart (port helpers now public)
    - lib/src/widgets/eden_workflow_canvas/eden_workflow_canvas_exports.dart
decisions:
  - Port helpers made static + public (renamed _triggerPorts -> triggerPorts etc.) for TRD 020-07 toolbox-drop integration
  - Delay popover conditionally renders Minutes input (only when type=fixed) per donor parity
  - delayConfig map spread preserves non-minutes keys (untilTime, businessHoursStart future use)
metrics:
  duration: ~25 minutes
  completed: 2026-05-17
  tests_added: 28
  test_pass_rate: 100%
---

# Objective 020 TRD 020-05: Delay + Merge nodes + public port helpers

Shipped `EdenDelayNode` (purple wait card with delay-type/minutes editor) + `EdenMergeNode` (gray join card, presentational-only) + made graph-builder port helpers public to support TRD 020-07's toolbox-drop integration.

## Tasks Completed

| Task | Description | Commit |
| ---- | ----------- | ------ |
| 1-3 | Fixtures + Delay + Merge + port helpers public | `0ac0d53` |

## Task Evidence

| Task | Verify Command | Exit Code | Status |
|---|---|---|---|
| Full workflow canvas | `flutter test test/widgets/eden_workflow_canvas/` | 0 | PASS (194 tests) |
| Analyze | `flutter analyze` | 0 | PASS (0 issues) |

## Validation Gates

| Gate | Command | Status |
|---|---|---|
| port helpers public | `EdenWorkflowGraphBuilder.triggerPorts()` resolves | PASS |
| TRD 020-01 back-compat | renamed callers internally updated; graph builder tests still GREEN | PASS |
| hard invariant | obj 006 dirs untouched | PASS |

## Self-Check: PASSED

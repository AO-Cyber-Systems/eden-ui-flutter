---
objective: 020-a4b-visual-workflow-designer
trd: "020-06"
subsystem: eden_workflow_canvas
tags: [end-node, validator, tdd]
dependency-graph:
  requires:
    - TRDs 020-02..020-05 (full node coverage for validation rules)
    - eden_process_canvas (EdenProcessValidationSeverity enum)
  provides:
    - EdenWorkflowEndNode (parity N-7)
    - EdenWorkflowValidator + EdenWorkflowValidationResult + EdenWorkflowValidationIssue (parity V-1 / V-2)
key-files:
  created:
    - lib/src/widgets/eden_workflow_canvas/nodes/eden_workflow_end_node.dart
    - lib/src/widgets/eden_workflow_canvas/workflow_validator.dart
    - test/widgets/eden_workflow_canvas/_fixtures/eden_workflow_validator_fixtures.dart
    - test/widgets/eden_workflow_canvas/nodes/eden_workflow_end_node_test.dart
    - test/widgets/eden_workflow_canvas/eden_workflow_validator_test.dart
  modified:
    - lib/src/widgets/eden_workflow_canvas/eden_workflow_canvas_exports.dart
decisions:
  - Severity enum REUSED from obj 006 (EdenProcessValidationSeverity) — locked decision, no parallel enum
  - End node is presentational-only (no popover, no delete) per donor parity
  - 8 rules implemented per donor workflowValidation.ts:17-122 exactly
metrics:
  duration: ~25 minutes
  completed: 2026-05-17
  tests_added: 25
  test_pass_rate: 100%
---

# Objective 020 TRD 020-06: End node + Validator (Wave 4)

Shipped `EdenWorkflowEndNode` (red termination circle) + `EdenWorkflowValidator` (pure-function 8-rule validator).

## Tasks Completed

| Task | Description | Commit |
| ---- | ----------- | ------ |
| 1-3 | Fixtures + End node + Validator | `0c6ade7` |

## Task Evidence

| Task | Verify Command | Exit Code | Status |
|---|---|---|---|
| Full workflow canvas | `flutter test test/widgets/eden_workflow_canvas/` | 0 | PASS (219 tests) |
| Analyze | `flutter analyze` | 0 | PASS (0 issues) |

## Validation Gates

All 8 donor rules covered by independent unit tests. Reuse of obj 006 severity enum verified.

## Self-Check: PASSED

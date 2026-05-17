---
objective: 020-a4b-visual-workflow-designer
trd: "020-04"
subsystem: eden_workflow_canvas
tags: [branch-node, condition-node, diamond, popover-editor, tdd]
dependency-graph:
  requires:
    - TRD 020-01 (EdenWorkflowConditionOperator enum)
  provides:
    - EdenBranchNode + EdenBranchNodeConfig (parity N-3)
    - EdenConditionNode + EdenConditionNodeConfig (parity N-4 / X-3)
key-files:
  created:
    - lib/src/widgets/eden_workflow_canvas/nodes/eden_branch_node.dart
    - lib/src/widgets/eden_workflow_canvas/nodes/eden_condition_node.dart
    - test/widgets/eden_workflow_canvas/_fixtures/eden_workflow_flow_node_fixtures.dart
    - test/widgets/eden_workflow_canvas/nodes/eden_branch_node_test.dart
    - test/widgets/eden_workflow_canvas/nodes/eden_condition_node_test.dart
  modified:
    - lib/src/widgets/eden_workflow_canvas/eden_workflow_canvas_exports.dart
decisions:
  - Branch is presentational-only (no popover) per donor
  - Condition diamond uses Transform.rotate(pi/4) + counter-rotated content overlay
  - Operator labels use words ("contains", "!=") rather than Unicode symbols (≠, ∋) to avoid font rendering inconsistency
  - Empty-field Save is a no-op (donor parity)
metrics:
  duration: ~20 minutes
  completed: 2026-05-17
  tests_added: 20
  test_pass_rate: 100%
---

# Objective 020 TRD 020-04: Branch + Condition nodes (Wave 3 leg 1)

Shipped `EdenBranchNode` (gray parallel-split card) + `EdenConditionNode` (amber rotated-diamond boolean predicate composer).

## Tasks Completed

| Task | Description | Commit |
| ---- | ----------- | ------ |
| 1-3 | Fixtures + Branch + Condition nodes | `97bba17` |

## Task Evidence

| Task | Verify Command | Exit Code | Status |
|---|---|---|---|
| Branch + Condition | `flutter test test/widgets/eden_workflow_canvas/nodes/eden_branch_node_test.dart test/widgets/eden_workflow_canvas/nodes/eden_condition_node_test.dart` | 0 | PASS (20 tests) |
| Full workflow canvas | `flutter test test/widgets/eden_workflow_canvas/` | 0 | PASS (166 tests) |
| Analyze | `flutter analyze` | 0 | PASS (0 issues) |

## Self-Check: PASSED

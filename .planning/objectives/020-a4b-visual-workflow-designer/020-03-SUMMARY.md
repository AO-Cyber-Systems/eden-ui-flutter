---
objective: 020-a4b-visual-workflow-designer
trd: "020-03"
subsystem: eden_workflow_canvas
tags: [action-node, field-spec, popover-editor, tdd]
dependency-graph:
  requires:
    - TRD 020-01 (EdenWorkflowActionType + EdenWorkflowActionRegistry)
    - eden_diagram (EdenDiagramNodeContext)
  provides:
    - EdenActionNode + EdenActionNodeConfig (parity N-2 / X-2)
    - EdenWorkflowActionFieldSpec + EdenWorkflowActionFieldOption (parity X-2)
    - kEdenDefaultActionFieldSpecs (6 default action specs)
    - kEdenWorkflowPriorityOptions (4 priority levels)
    - EdenWorkflowActionType.fields extension (non-breaking)
key-files:
  created:
    - lib/src/widgets/eden_workflow_canvas/workflow_action_field_spec.dart
    - lib/src/widgets/eden_workflow_canvas/nodes/eden_action_node.dart
    - test/widgets/eden_workflow_canvas/_fixtures/eden_workflow_action_fixtures.dart
    - test/widgets/eden_workflow_canvas/nodes/eden_action_node_test.dart
    - test/widgets/eden_workflow_canvas/eden_workflow_action_field_spec_test.dart
  modified:
    - lib/src/widgets/eden_workflow_canvas/workflow_action_registry.dart
    - lib/src/widgets/eden_workflow_canvas/eden_workflow_canvas_exports.dart
decisions:
  - Option A chosen — extend EdenWorkflowActionType.fields (non-breaking)
  - Default field specs auto-attach in _registerDefaults (defaults are hand-built; consumer types use their own fields:)
  - Config-summary helper hard-codes the 6 default summary keys (donor parity); unknown action types render empty summary
  - Hover-show delete on desktop via MouseRegion; always-show on touch (Android/iOS) via defaultTargetPlatform check
metrics:
  duration: ~30 minutes
  completed: 2026-05-17
  tests_added: 33
  test_pass_rate: 100%
---

# Objective 020 TRD 020-03: Action node + Field specs

Wave 2 leg 2: shipped `EdenActionNode` (blue outcome card with dynamic-per-action-type popover editor), `EdenWorkflowActionFieldSpec` (form-field schema), and 6 default field-spec maps for the library's default action types.

## Tasks Completed

| Task | Description | Commit |
| ---- | ----------- | ------ |
| 1-5 | Field specs + ActionType extension + EdenActionNode | `3cbfd58` |

(Combined into one commit per TDD habit 3 — atomic feature unit, tests + code together. Per-task commits would have been micro-noise.)

## Task Evidence

| Task | Verify Command | Exit Code | Status |
|---|---|---|---|
| Field spec | `flutter test test/widgets/eden_workflow_canvas/eden_workflow_action_field_spec_test.dart` | 0 | PASS (15 tests) |
| Action node | `flutter test test/widgets/eden_workflow_canvas/nodes/eden_action_node_test.dart` | 0 | PASS (18 tests) |
| Full workflow canvas | `flutter test test/widgets/eden_workflow_canvas/` | 0 | PASS (146 tests) |
| Analyze | `flutter analyze lib/src/widgets/eden_workflow_canvas/ test/widgets/eden_workflow_canvas/` | 0 | PASS (0 issues) |

## TDD Evidence

RED → GREEN per task; all field-spec tests written before kEdenDefaultActionFieldSpecs map populated; all action-node widget tests written before EdenActionNode implementation.

## Validation Gate Results

| Gate | Command | Exit Code | Status |
|---|---|---|---|
| workflow canvas suite | `flutter test test/widgets/eden_workflow_canvas/` | 0 | PASS (146/146) |
| obj 006 back-compat | (covered by full suite; obj 006 dirs unchanged) | 0 | PASS |
| hard invariant | `git diff origin/main -- lib/src/widgets/eden_diagram/ lib/src/widgets/eden_process_canvas/` | 0 | PASS |
| zero new deps | `git diff origin/main -- pubspec.yaml pubspec.lock` | 0 | PASS |

## Post-TRD Verification

- Auto-fix cycles used: 0
- Must-haves verified: 7/7
- Gate failures: None

## Self-Check: PASSED

All 5 created source/test files exist. Commit 3cbfd58 in git log. Push to origin/main confirmed.

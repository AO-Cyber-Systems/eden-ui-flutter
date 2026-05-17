---
objective: 020-a4b-visual-workflow-designer
trd: "020-01"
subsystem: eden_workflow_canvas
tags: [foundation, value-types, registries, graph-builder, tdd]
dependency-graph:
  requires:
    - eden_diagram (EdenDiagramNode, EdenDiagramEdge, EdenDiagramPort)
    - eden_process_canvas (EdenProcessNodePosition, EdenProcessSavedEdge, EdenProcessViewport, EdenFreeFormLayout)
  provides:
    - EdenWorkflowDefinition / EdenWorkflowCondition / EdenWorkflowAction value types
    - EdenWorkflowCanvasLayout / EdenWorkflowSaveData
    - EdenWorkflowTriggerType / EdenWorkflowConditionOperator enums
    - EdenWorkflowCategoryRegistry (5 defaults) + EdenWorkflowActionRegistry (6 defaults)
    - EdenWorkflowGraphBuilder.toCanvas + .fromCanvas
    - EdenWorkflowEdgeStyle constants
  affects:
    - lib/eden_ui.dart (new Objective 020 export section)
tech-stack:
  added: []
  patterns:
    - Reuse obj 006 value types (no parallel position type)
    - Registry singletons mirror EdenProcessRuntimeComponentRegistry shape
    - Static-class graph builder (pure functions, no instance state)
    - BFS with yes-handle priority for execution-order extraction
key-files:
  created:
    - lib/src/widgets/eden_workflow_canvas/workflow_models.dart
    - lib/src/widgets/eden_workflow_canvas/workflow_category_registry.dart
    - lib/src/widgets/eden_workflow_canvas/workflow_action_registry.dart
    - lib/src/widgets/eden_workflow_canvas/workflow_graph_builder.dart
    - lib/src/widgets/eden_workflow_canvas/eden_workflow_canvas_exports.dart
    - test/widgets/eden_workflow_canvas/_fixtures/eden_workflow_models_fixtures.dart
    - test/widgets/eden_workflow_canvas/eden_workflow_models_test.dart
    - test/widgets/eden_workflow_canvas/eden_workflow_category_registry_test.dart
    - test/widgets/eden_workflow_canvas/eden_workflow_action_registry_test.dart
    - test/widgets/eden_workflow_canvas/eden_workflow_graph_builder_test.dart
  modified:
    - lib/eden_ui.dart
decisions:
  - Reused obj 006 EdenProcessNodePosition/SavedEdge/Viewport directly (no EdenWorkflowNodePosition)
  - TriggerType + ConditionOperator are Dart enums (small fixed set), NOT registries
  - EdenWorkflowAction stores `actionType` field but JSON wire key is `'type'` (donor parity)
  - EdenDiagramEdge handle info stored via edge.data['sourceHandle']/['targetHandle'] (top-level fields exist for fixed sides; data slot carries the React-Flow-style handle id strings)
metrics:
  duration: ~50 minutes
  completed: 2026-05-17
  tests_added: 81
  test_pass_rate: 100%
---

# Objective 020 TRD 020-01: Wave 1 Foundation Summary

Established the value-type vocabulary, category + action registries, and the bidirectional `EdenWorkflowGraphBuilder.toCanvas` / `.fromCanvas` pure functions that every downstream TRD depends on. Ships zero new pubspec deps and reuses obj 006's position / edge / viewport value types verbatim.

## Tasks Completed

| Task | Description | Commit |
| ---- | ----------- | ------ |
| 2 | Value types + enums + EdenWorkflowEdgeStyle (RED → GREEN) | `76718db` |
| 3 | EdenWorkflowCategoryRegistry singleton + 5 defaults (RED → GREEN) | `cd21a12` |
| 4 | EdenWorkflowActionRegistry singleton + 6 defaults (RED → GREEN) | `c001694` |
| 5 | EdenWorkflowGraphBuilder bidirectional pure functions (RED → GREEN) | `87e88a9` |
| 6 | Public-exports smoke test (REFACTOR) | `6021c59` |

Task 1 (fixtures) was rolled into Task 2's commit per TDD habit 4 — fixtures land alongside the first test that consumes them, with the registry-fixture half landing in Task 5's commit once the registry types existed.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Fixture file referenced types before they existed**
- **Found during:** Task 2 (RED for models)
- **Issue:** TRD specified all 20+ fixture factories in Task 1, but registry-type factories (`EdenWorkflowCategory`, `EdenWorkflowActionType`) referenced types not built until Tasks 3 + 4. Compilation blocked.
- **Fix:** Split fixtures into two waves — value-type fixtures land with Task 2 commit; registry fixtures restored to the same file at the end of Task 5 once both registry types existed.
- **Files modified:** `test/widgets/eden_workflow_canvas/_fixtures/eden_workflow_models_fixtures.dart`
- **Commit:** `87e88a9` (Task 5)

## Task Evidence

| Task | Verify Command | Exit Code | Status |
|---|---|---|---|
| 2: value types | `flutter test test/widgets/eden_workflow_canvas/eden_workflow_models_test.dart` | 0 | PASS (30 tests) |
| 3: category registry | `flutter test test/widgets/eden_workflow_canvas/eden_workflow_category_registry_test.dart` | 0 | PASS (13 tests) |
| 4: action registry | `flutter test test/widgets/eden_workflow_canvas/eden_workflow_action_registry_test.dart` | 0 | PASS (13 tests) |
| 5: graph builder | `flutter test test/widgets/eden_workflow_canvas/eden_workflow_graph_builder_test.dart` | 0 | PASS (24 tests) |
| 6: full suite | `flutter test test/widgets/eden_workflow_canvas/` | 0 | PASS (81 tests) |

## TDD Evidence

Every task followed RED → GREEN. Selected commands (one per task):

| Phase | Command | Exit Code | Expected |
|---|---|---|---|
| RED (models) | `flutter test .../eden_workflow_models_test.dart` (pre-impl) | 1 | FAIL (correct — types absent) |
| GREEN (models) | same command post-impl | 0 | PASS (correct) |
| RED (graph builder) | `flutter test .../eden_workflow_graph_builder_test.dart` (pre-impl) | 1 | FAIL (correct) |
| GREEN (graph builder) | same command post-impl | 0 | PASS (correct) |

## Validation Gate Results

| Gate | Command | Exit Code | Status |
|---|---|---|---|
| workflow canvas tests | `flutter test test/widgets/eden_workflow_canvas/` | 0 | PASS (81/81) |
| obj 006 back-compat | `flutter test test/widgets/eden_process_canvas/ test/widgets/eden_diagram/` | 0 | PASS (401/401) |
| workflow canvas analyze | `flutter analyze lib/src/widgets/eden_workflow_canvas/ test/widgets/eden_workflow_canvas/` | 0 | PASS (0 issues) |
| hard invariant | `git diff origin/main -- lib/src/widgets/eden_diagram/ lib/src/widgets/eden_process_canvas/` | 0 | PASS (empty diff) |
| zero new deps | `git diff origin/main -- pubspec.yaml pubspec.lock` | 0 | PASS (empty diff) |
| NO-LLM header | `grep -c '// Do NOT regenerate via LLM' .../eden_workflow_models_fixtures.dart` | 0 | PASS (== 1) |

## Deferred Issues (pre-existing, out of scope)

Full `flutter test` from `eden-ui-flutter` baseline reports 8 failures in unrelated test files (`eden_permission_matrix_test.dart`, `eden_consent_flow_test.dart`, `eden_tank_fleet_map_test.dart`, `eden_json_viewer_test.dart`, `support_panel_test.dart`, `eden_media_row_test.dart`). Verified pre-existing via `git stash + flutter test`: failures reproduce on the pre-020 baseline. Out of scope per the per-task scope boundary rule.

## Post-TRD Verification

- Auto-fix cycles used: 1 (Rule 3 - blocking, fixture split)
- Must-haves verified: 12/12
- Gate failures: None

## Self-Check: PASSED

All 10 created files exist on disk. All 5 task commits present in git log (76718db, cd21a12, c001694, 87e88a9, 6021c59). Push to origin/main confirmed at HEAD 6021c59.

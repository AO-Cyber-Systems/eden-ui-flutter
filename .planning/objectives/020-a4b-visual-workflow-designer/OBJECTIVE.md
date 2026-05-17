---
objective: 020-a4b-visual-workflow-designer
kind: ui-lib
work: feature
status: planned
estimated_effort: 2-3 weeks Claude execution
trd_count: 7
waves: 5
---

# Objective 020 — A4-b Visual Workflow Designer Port from trades-react

## Goal

Port the trades-react Workflow Designer (`AOCyber-Trades/trades/client/src/components/workflow/` — 20 files, 7 node types: Trigger / Action / Branch / Condition / Delay / Merge / End) into `eden-ui-flutter` as a generic, vertical-agnostic, transport-agnostic workflow-builder primitive. After this objective ships, every Eden Biz vertical (trades, salon, medical, fuel, retail, legal, gov) composes a workflow designer with the same node grammar (Trigger / Condition / Action / Delay / Branch / Merge / End), the same drag-from-toolbox UX, the same node-popover editing affordances, and the same flat-array bidirectional sync (flat trigger + conditions[] + actions[] ↔ canvas graph) — without re-implementing any of it.

The objective EXTENDS the existing `eden_diagram/` engine + `eden_process_canvas/` patterns established by **objective 006** (Visual Process Canvas, GREEN). It is **NOT** a fresh canvas — same `EdenDiagram` engine, same `customNodeRenderer` dispatch pattern, same `EdenDiagramPort` multi-handle model, same `EdenProcessLayoutEngine`-style pluggable layouts. The workflow designer is the **third consumer** of the eden_diagram engine (system diagrams was first, process canvas second).

**Donor reality check (per deep-audit §2.2):** the workflow designer differs from the process canvas in **data shape**, not infrastructure:
- Process canvas models a hierarchical phase → task-group → task tree (canonical process template).
- Workflow designer models a flat event-driven ladder: ONE trigger fires from an entity event (entity_created / entity_updated / status_change / scheduled / manual / time_based), then conditions (Yes/No branching diamonds) filter, then actions (create-task / send-notification / send-email / send-sms / update-status / create-callback) fire, with optional delays / parallel branches / merges before terminating at an end node.

The library reuses obj 006's canvas / port / drop-target / context-menu / layout infrastructure verbatim — only the node grammar + workflow-specific value shape + workflow toolbox change.

**Parity definition (acceptance):** every donor feature in the **Donor-parity checklist** below is implemented as a generic library widget under `lib/src/widgets/eden_workflow_canvas/` (workflow-builder-specific widgets — distinct directory from process_canvas), has at least one widget test (hand-built fixtures), and is visible in the dev catalog under a new `workflow_designer_screen.dart`. Side-by-side review of a populated `EdenVisualWorkflowCanvas` demo vs trades-react `WorkflowCanvas` shows the same feature set (same 7 node types, same toolbox categories, same popover editors, same auto-layout button, same validation popover, same connection semantics).

## Why now

- **Obj 006 complete + GREEN** (per ROADMAP.md line 105 — 15 TRDs all `[ ]` in the roadmap entry but `OBJECTIVE.md` confirms the infrastructure is built; the existing `lib/src/widgets/eden_process_canvas/` + `lib/src/widgets/eden_diagram/` files in the tree, plus `process_builder_screen.dart` in dev_app/screens/, confirm the canvas engine + customNodeRenderer + EdenDiagramPort + EdenProcessLayoutEngine + customNodeRenderer dispatch + node-popover-editor pattern have already shipped).
- **Locked direction (deep-audit 2026-05-15 §6 row 2):** A4-b Workflow Designer is sequenced AFTER A4-a (≈half the cost, ~2 wk) because the canvas infra is reusable. Now is the moment.
- **Active initiative alignment** (advisory, from `feedback_planner_proto_conflict.md` + the donor stability check below): `eden-biz-flutter` trades vertical wants workflow-template editing UX. Salon (post-visit follow-up), medical (appointment reminders + no-show callbacks), fuel (low-tank-level → dispatch trigger), retail (inventory-reorder threshold), gov (case-deadline reminders) all want the same primitive. Building it once, generically, pays back across 5+ verticals.
- **Donor stability:** trades-react `workflow/` is mature, in-production, 20 files. Known backend gap (`entity_created` missing from Zod enum — flagged in `AOCyber-Trades/trades/CLAUDE.md` Critical Warnings) is **backend-side**, not a UI port blocker (locked decision §7.3 of deep-audit: fix lands as part of absorption, NOT a Flutter UI ticket — the UI ships the trigger type now).
- **Cadence proven:** obj 006 GREEN (15 TRDs, ~120-180 new widget tests on top of 445+). Same TDD discipline (Iron Law + test-list-first + hand-built fixtures + outside-in per `~/.claude/CLAUDE.md` TDD Playbook), same `wrap()` test helper, same dev-catalog pattern, same file-collision discipline on `lib/eden_ui.dart`.

## Donor-parity checklist (derived from `client/src/components/workflow/`)

The donor exposes these UX-observable features. Each row is a parity target — every TRD lists which rows it satisfies and the acceptance test that proves the parity.

### W. Workflow data shape (distinct from process)

| ID | Donor surface | Library target | TRD |
|---|---|---|---|
| W-1 | Flat `WorkflowTemplate { triggerType, triggerConfig, category, conditions: [], actions: [] }` — single trigger → ordered conditions → ordered actions → implicit end | `EdenWorkflowDefinition` value type (NOT phase-hierarchical) — `triggerType`, `triggerConfig`, `category`, `conditions: List<EdenWorkflowCondition>`, `actions: List<EdenWorkflowAction>`, `canvasLayout: EdenWorkflowCanvasLayout?` | 020-01 |
| W-2 | `TriggerType` enum: scheduled / completed / status_change / time_based / manual / entity_created | `EdenWorkflowTriggerType` enum (registry-driven option labels NOT required — small fixed set, semantically defined like donor) | 020-01 |
| W-3 | `WorkflowCategory` enum: appointment / task / project / customer / callback | `EdenWorkflowCategory` String (registry-driven via `EdenWorkflowCategoryRegistry` per locked decision — verticals add their own categories; library ships 5 defaults) | 020-01 |
| W-4 | `ConditionOperator`: equals / not_equals / greater_than / less_than / contains / not_contains | `EdenWorkflowConditionOperator` enum (small fixed semantic set) | 020-01 |
| W-5 | `ActionType` String (registry-driven — donor hard-codes 6: create_task / send_notification / create_callback / update_status / send_email / send_sms) | `EdenWorkflowActionRegistry` (singleton, `register(EdenWorkflowActionType)`, `lookup(String id)`, `all() → List`, `reset()`, `resetToDefaults()` ships 6 defaults; verticals register more) — parity row W-5 | 020-01 |
| W-6 | `WorkflowCanvasLayout` (version: 1, nodes: Record<id, {position}>, edges: SavedEdge[], viewport?) | `EdenWorkflowCanvasLayout` value type (reuses `EdenProcessNodePosition`, `EdenProcessSavedEdge`, `EdenProcessViewport` from obj 006 — value-type compat verified via JSON round-trip test) | 020-01 |
| W-7 | `flowToWorkflowData(nodes, edges, userEdges) → WorkflowSaveData` — BFS graph traversal extracting conditions + actions in execution order | `EdenWorkflowGraphBuilder.fromCanvas(nodes, edges, userEdges) → EdenWorkflowSaveData` pure function — parity row W-7 | 020-01 |

### N. Node types (7 total)

| ID | Donor surface | Library target | TRD |
|---|---|---|---|
| N-1 | `TriggerNode.tsx` — green card (180-220pt min/max width), trigger-type-driven icon (Calendar/RefreshCw/Clock/Hand/Zap), trigger label + category subtitle, popover editor (trigger type + category select), source-only ports (right, bottom) | `EdenTriggerNode` widget + popover editor + event browser ride-along | 020-02 |
| N-2 | `ActionNode.tsx` — blue card, action-type-driven icon (Plus/Bell/Phone/ArrowUpDown/Mail/MessageSquare), action label + config summary subtitle, popover with dynamic config fields per action type, target/source 4-handle ports, delete button on hover | `EdenActionNode` widget + popover editor (consumer-provided field schema OR registry-driven default fields per action id) | 020-03 |
| N-3 | `BranchNode.tsx` — gray card (140pt min), GitFork icon, "Split" label, target (top, left), source (right top 33%, right bottom 66%, bottom) — 3 outgoing handles for parallel paths | `EdenBranchNode` widget + multi-handle outgoing port emission | 020-04 |
| N-4 | `ConditionNode.tsx` — amber rotated diamond (140×140), GitBranch icon, "If field = value" label, popover (field + operator + value), target (top, left), Yes (right, green), No (bottom, red) | `EdenConditionNode` widget + popover editor (boolean expression composer) | 020-04 |
| N-5 | `DelayNode.tsx` — purple card (160-200pt min/max), Timer icon, "Wait Nm/h/d" label, popover (delay-type select + minutes input), target (top, left), source (right, bottom) | `EdenDelayNode` widget + popover editor | 020-05 |
| N-6 | `MergeNode.tsx` — gray card (140pt min), GitMerge icon, "Join" label, target (top, left at 33%, left-2 at 66% — 3 incoming handles), source (right, bottom) | `EdenMergeNode` widget + multi-handle incoming port emission | 020-05 |
| N-7 | `EndNode.tsx` — red 48×48 circle, Square icon, target-only handles (top, left) | `EdenWorkflowEndNode` widget (smaller scope than `EdenProcessEndNode` — distinct widget because workflow end has no orphan / no decision branching) | 020-06 |

### T. Toolbox + drag-from-palette

| ID | Donor surface | Library target | TRD |
|---|---|---|---|
| T-1 | `WorkflowToolbox.tsx` — left rail with 4 categories (Triggers / Conditions / Actions / Flow Control), 19 toolbox items, drag source via `dataTransfer.setData('application/workflow-node-type', ...)`, click-fallback handler | `EdenWorkflowToolbox` widget (left-rail container, registry-driven items per category) — parity rows T-1/T-2/T-3 | 020-07 |
| T-2 | Click-to-add fallback: `onAddNode(item)` callback when drag isn't viable | `EdenWorkflowToolbox.onAddNode` callback | 020-07 |
| T-3 | Drag source: `Draggable<EdenWorkflowDragPayload>` with `dragData` = `{nodeType, defaultData}` | Mirror obj 006 EdenProcessToolbox.Draggable pattern; same EdenWorkflowDragPayload value type | 020-07 |

### E. Edge / connection handling (reuses obj 006 patterns)

| ID | Donor surface | Library target | TRD |
|---|---|---|---|
| E-1 | User-drawn edges persist (`userEdges` state, saved to `canvasLayout.edges`) | Reuse `EdenDiagramController.userEdges` pattern from obj 006 — no new engine work | TRD 020-01 wires |
| E-2 | Edge styling: `smoothstep` 2pt indigo (#6366f1) for user-drawn, smoothstep 2pt default for auto-generated trigger→cond→action ladder | `EdenWorkflowEdgeStyle.user / .auto` helpers (mirror obj 006 EdenProcessEdgeStyle) | 020-01 |
| E-3 | Condition node uses sourceHandle: 'yes' / 'no'; auto-generated edge from condition uses 'yes' handle by default | `EdenWorkflowGraphBuilder` emits `sourceHandle: 'yes'` for condition→next edges | 020-01 + 020-04 |
| E-4 | Drag from port → preview line → connect; `connectOnClick: false` | Already in eden_diagram engine (obj 006); verify edge-creation callback fires | 020-07 |
| E-5 | Multi-handle ports per node (Trigger: right + bottom source; Condition: top + left target + yes-right + no-bottom; Branch: top + left target + right-33% + right-66% + bottom source) | Reuse `EdenDiagramPort` value type (obj 006 TRD-01); each node widget emits its custom port list via `EdenDiagramNode.ports` | 020-02 / 020-04 / 020-05 |

### C. Context menus

| ID | Donor surface | Library target | TRD |
|---|---|---|---|
| C-1 | Right-click node → simple context menu (Delete / Cancel); Trigger node can NOT be deleted (only one allowed per workflow) | `EdenWorkflowNodeContextMenu` (use obj 006's `EdenNodeContextMenu` slot API if compatible, else dedicated wrapper) | 020-07 |
| C-2 | No edge context menu in donor; press Delete/Backspace removes selected edge | Built-in via `EdenDiagram.deleteKeyCode` (obj 006 existing) | 020-07 |

### L. Layout engines

| ID | Donor surface | Library target | TRD |
|---|---|---|---|
| L-1 | `applyDagreLayout` (LR directed-graph layout, imported from process-builder utils — donor literally reuses process-canvas's Dagre port) | `EdenWorkflowFreeFormLayout` — reuses obj 006's `EdenFreeFormLayout` directly (BFS rank assignment, no Dagre dep, NO new code — just a typedef / re-export) | 020-01 (zero new layout code; reused) |
| L-2 | Auto-layout button → applyDagreLayout + fitView | Reuse `EdenDiagramController.fitView()` (obj 006) + library's existing `EdenFreeFormLayout` | 020-07 |
| L-3 | Saved positions persist (donor `canvasLayout.nodes` keyed by nodeId) | `EdenWorkflowCanvasLayout` — reuses `EdenProcessNodePosition` from obj 006 (value-type re-use) | 020-01 |

### S. Sync / hooks (model ↔ canvas)

| ID | Donor surface | Library target | TRD |
|---|---|---|---|
| S-1 | `useWorkflowToFlow(template, callbacks)` — converts WorkflowTemplate → nodes + edges; auto-applies Dagre if no saved positions | `EdenWorkflowGraphBuilder.toCanvas(definition) → (nodes, edges)` pure function | 020-01 |
| S-2 | `flowToWorkflowData(nodes, edges, userEdges) → SaveData` — BFS traversal extracting conditions[] + actions[] in execution order | `EdenWorkflowGraphBuilder.fromCanvas(...)` — pure function inverse of S-1 | 020-01 |
| S-3 | Preserve manual node positions on re-render (donor `currentPositions` Map) | `EdenWorkflowController.preserveManualPositions = true` (default) — reuses obj 006 `EdenProcessController` shape via composition | 020-07 |
| S-4 | Dynamically-created nodes (dropped from toolbox) persist alongside template-derived nodes | `EdenWorkflowController.addNode(EdenDiagramNode)` API | 020-07 |
| S-5 | Layout save extracts positions + user-drawn edges | `EdenWorkflowController.toLayoutData() → EdenWorkflowCanvasLayout` | 020-07 |

### V. Validation

| ID | Donor surface | Library target | TRD |
|---|---|---|---|
| V-1 | `validateWorkflow(nodes, edges)` — 8 rules: must-have-trigger, only-one-trigger, must-have-action, should-have-end, all-non-trigger-connected, all-non-end-have-outgoing, branch-≥2-outgoing, merge-≥2-incoming, condition-configured | `EdenWorkflowValidator.validate(definition, nodes, edges) → EdenWorkflowValidationResult` — pure function port; reuses `EdenProcessValidationIssue` value-type shape from obj 006 (severity enum + nodeId + message + suggestion) | 020-06 |
| V-2 | `getValidationSummary` — errors + warnings counts | `EdenWorkflowValidationResult.summary` getter | 020-06 |
| V-3 | Validation popover — error / warning list, click-to-focus node | `EdenWorkflowValidationPanel` (consumer composes into canvas chrome — mirror obj 006 EdenProcessValidationPanel) | 020-07 |

### X. Editor popovers (donor uses popovers, not modal dialogs)

| ID | Donor surface | Library target | TRD |
|---|---|---|---|
| X-1 | Trigger popover: trigger-type select + category select | Inline `_EdenTriggerEditor` widget (Popover anchor inside `EdenTriggerNode`) — same pattern as TriggerNode.tsx donor lines 135-183 | 020-02 |
| X-2 | Action popover: action-type select + dynamic config-field grid per action-type (e.g. send_email → to / subject / body) | Inline `_EdenActionEditor` widget — consumer provides `Map<String, List<EdenWorkflowActionFieldSpec>>` or registry ships defaults for 6 actions | 020-03 |
| X-3 | Condition popover: field input + operator select + value input | Inline `_EdenConditionEditor` widget (boolean expression composer) | 020-04 |
| X-4 | Delay popover: delay-type select + minutes input (only when type=fixed) | Inline `_EdenDelayEditor` widget | 020-05 |
| X-5 | Branch / Merge / End: NO popovers (no per-node config — only Delete from context menu) | — | n/a |

### R. Registry — Trigger event browser + Action types

| ID | Donor surface | Library target | TRD |
|---|---|---|---|
| R-1 | Donor `TriggerType` enum is hard-coded (6 values); donor `WorkflowCategory` enum is hard-coded (5 values) | `EdenWorkflowCategoryRegistry` (5 defaults: appointment / task / project / customer / callback; verticals add their own — e.g. medical might add `visit`, fuel might add `tank` / `delivery_route`) — parity decision: keep TriggerType as fixed Dart enum (small semantic set) but Category as registry (verticals will want to add) | 020-01 |
| R-2 | Donor hard-codes 19 toolbox items across 4 categories | `EdenWorkflowToolboxItemRegistry` (ships 19 defaults; verticals add their own); the toolbox widget iterates the registry | 020-07 |
| R-3 | Action types: 6 hard-coded (create_task, send_notification, create_callback, update_status, send_email, send_sms) | `EdenWorkflowActionRegistry` — singleton with `register(EdenWorkflowActionType)`, `lookup(String id)`, `all()`, `reset()`, `resetToDefaults()`; ships 6 defaults — parity row W-5 | 020-01 |
| R-4 | Event browser: donor `FieldBrowser.tsx` shows available fields from `WORKFLOW_FIELD_METADATA` per category for `{field}` template-string interpolation in action configs | `EdenWorkflowEventBrowser` — registry-driven (`EdenWorkflowFieldRegistry`); consumers register fields per category; library widget renders the browser popover. **Optional ride-along on the Trigger node** for v1; can defer the field-insertion UX to v2 if scope tight. | 020-02 |

## Wave structure (parallelism map)

| Wave | TRDs | Theme | Parallelism |
|---|---|---|---|
| **1** | 020-01 | Foundation — value types + 3 registries (Category, Action, ToolboxItem) + EdenWorkflowGraphBuilder.toCanvas/.fromCanvas | Single TRD; foundation for everything; ~2 days |
| **2** | 020-02, 020-03 | Entry-point + outcome nodes — Trigger (W-2/N-1/E-5/X-1/R-4) + Action (W-5/N-2/X-2/R-3) | 020-02 + 020-03 parallel; different files; depend on Wave 1 |
| **3** | 020-04, 020-05 | Flow-control nodes — Branch + Condition (N-3/N-4/E-5/X-3) + Delay + Merge (N-5/N-6/X-4) | 020-04 + 020-05 parallel; different files; depend on Wave 1 |
| **4** | 020-06 | Termination + validation — EndNode (N-7) + EdenWorkflowValidator (V-1/V-2) | Single TRD; depends on Wave 2 + Wave 3 (validator inspects all node types) |
| **5** | 020-07 | Composite root + toolbox + catalog — EdenVisualWorkflowCanvas (composite root composing all nodes + controller + validation panel) + EdenWorkflowToolbox (T-1/T-2/T-3) + dev catalog screen + 1 nav tile | Single TRD; depends on Waves 1-4 |

**Total: 7 TRDs across 5 waves.** ~2-3 weeks Claude execution per audit §6 (≈half of obj 006's 4 wk).

**File-collision discipline:**
- `lib/eden_ui.dart` — every TRD that adds a public surface appends 1-2 export lines under a NEW section header per wave (`// Objective 020 — Workflow canvas Wave N`). Mark each TRD `co_modified_files: [lib/eden_ui.dart]` so the orchestrator serializes the edit step within a wave.
- `lib/src/widgets/eden_workflow_canvas/eden_workflow_canvas_exports.dart` — TRDs 01, 02, 03, 04, 05, 06, 07 all append exports. Serialize within each wave.
- `lib/dev_app/screens/home_screen.dart` — TRD 07 adds one nav entry pointing to a new workflow-designer screen.
- `lib/dev_app/screens/process_builder_screen.dart` — leave UNCHANGED. Workflow-designer demo goes in a NEW file `lib/dev_app/screens/workflow_designer_screen.dart` (TRD 07).
- **NO modifications to `lib/src/widgets/eden_diagram/` or `lib/src/widgets/eden_process_canvas/`.** The workflow canvas reuses these primitives via composition; if a missing engine feature is discovered, the TRD MUST surface it as an out-of-scope blocker, not a co-modification. (This is enforced by the obj 006 invariant: engine extensions land in obj 006, not subsequent obj.)

## Constraints (locked, do not revisit)

1. **REUSE obj 006 infrastructure, do not duplicate.** All canvas / port / drop-target / customNodeRenderer / EdenDiagramPort / EdenProcessLayoutEngine / context-menu primitives are SHIPPED. The workflow canvas composes them. New code lives ONLY in `lib/src/widgets/eden_workflow_canvas/` — NO modifications to `lib/src/widgets/eden_diagram/` or `lib/src/widgets/eden_process_canvas/`.
2. **Generic + vertical-agnostic.** No trades-specific fields anywhere. Domain shapes (`EdenWorkflowDefinition`, `EdenWorkflowCondition`, `EdenWorkflowAction`) are generic Dart classes named in cross-vertical terms. Donor's domain-specific fields (`triggerConfig`, `actionConfig`) become `Map<String, dynamic> config` slots; verticals project their domain into the slot. Action types and categories are registry-driven (W-5 / R-1 / R-3).
3. **Transport-agnostic.** No new pubspec deps. NO `xyflow` / `react-flow` equivalent — reuse eden_diagram (obj 006). NO `dagre` — reuse `EdenFreeFormLayout` (obj 006 BFS-rank). NO HTTP / persistence layer. The existing `flutter/material.dart` + `flutter/widgets.dart` + `dart:ui` + `dart:math` are enough.
4. **TDD strict (Iron Law) + test-list-first.** Every TRD's testable tasks carry `tdd="true"`. Test-list checklist at the top of every TRD enumerating happy/edge/failure cases BEFORE any test code. **Hand-built fixture builders only (no LLM-generated test data)** — `no_llm_test_data` constraint active. Fixture files named `test/widgets/eden_workflow_canvas/_fixtures/eden_workflow_<aspect>_fixtures.dart` with header line `// Do NOT regenerate via LLM — hand-built fixtures for EdenWorkflow<Aspect>.`. One test at a time through RED → GREEN → REFACTOR per `~/.claude/CLAUDE.md` TDD Playbook habits 1–4.
5. **Outside-in for UI flows.** Per `~/.claude/CLAUDE.md` Playbook habit 5: pure-logic helpers (validator, graph builder, fromCanvas/toCanvas conversion) start at unit level. Composite widgets (canvas + nodes + toolbox wired together in `EdenVisualWorkflowCanvas`) get system-level widget tests asserting "given a `EdenWorkflowDefinition`, renders 1 trigger + N condition + M action + end nodes, dragging an action from toolbox onto canvas fires `onAddAction(actionType, config)`". Individual node widgets get unit-level widget tests.
6. **Test pattern locked.** `testWidgets('renders ...', (tester) async {...})` with `wrap()` helper at the top of each test file. Mirror obj 006 test pattern; ultimately `test/widgets/eden_alert_test.dart` shape. Widget tests, NOT integration tests.
7. **iPhone-narrow safe (≥390pt) — workflow designer is desktop/tablet UX with a graceful narrow fallback.** Like obj 006, the workflow designer is fundamentally a 1200pt+ canvas UX. At <1200pt, the library MUST render a **read-only fallback** message ("Workflow designer requires tablet/desktop width — switch to mobile workflow list view") rather than overflow. The fallback widget exists at the canvas root (`EdenVisualWorkflowCanvas`); individual node widgets MUST themselves not overflow at 390pt (they're tested in isolation at narrow widths and render compactly per donor 180-220pt min/max card widths).
8. **Material 3 + tokens.** Use `EdenSpacing`, `EdenRadii`, `EdenColors`, `EdenTypography` from `lib/src/tokens/` where they apply. Donor uses Tailwind palette colors (`bg-green-50`, `bg-blue-50`, `bg-amber-50`, `bg-purple-50`, `bg-gray-50`, `bg-red-50`) for node fills — map to `theme.colorScheme.primary/.secondary/.tertiary/.surface` where possible; if a donor color has no token equivalent, hard-code with comment `// donor color — keep until token system has equivalent`.
9. **Visual catalog entry.** TRD 020-07 creates `lib/dev_app/screens/workflow_designer_screen.dart` with a populated demo — Trigger (entity_created on appointment) → Condition (priority = high) → Action (send_notification) → Action (create_task) → Delay (30 min) → Action (send_sms) → End — plus drag-from-toolbox working, popover editors functioning, auto-layout button, validation popover showing 0 errors. TRD 07 also adds one nav tile to `home_screen.dart`. Earlier TRDs do NOT modify the dev catalog (per file-collision discipline).
10. **No breaking changes to existing widgets.** Existing widget exports + tests must continue to pass. This objective is purely additive to the public surface (`lib/eden_ui.dart`).
11. **No new pubspec dependencies.** Period. If a TRD believes it needs one, it MUST justify in `<context>` and add it explicitly; default assumption is no new deps.
12. **Registries are SINGLETONS but reset-able for tests.** `EdenWorkflowCategoryRegistry.instance`, `EdenWorkflowActionRegistry.instance`, `EdenWorkflowFieldRegistry.instance`, `EdenWorkflowToolboxItemRegistry.instance` all expose `register()`, `lookup()`, `all()`, `reset()` (and `resetToDefaults()` for registries with defaults). Tests MUST call `resetToDefaults()` (or `reset()`) in `setUp` to avoid bleed across tests.
13. **Decomposition principle — generic, hand-rolled, NOT 1:1 donor translation.** Donor `WorkflowCanvas.tsx` is 612 LOC of React Flow integration. The Dart equivalent (`EdenVisualWorkflowCanvas` in TRD 020-07) target is <350 LOC because the engine work (eden_diagram from obj 006) absorbs the React-Flow boilerplate. If a TRD is approaching donor's LOC count, it's translating too literally — re-grep the donor for the LOGIC, drop the React-Flow scaffolding.
14. **Layout engine pluggability via OBJ 006.** `EdenVisualWorkflowCanvas` exposes `layout: EdenProcessLayoutEngine` (the obj 006 abstract type — workflow REUSES, doesn't fork). Default is `EdenFreeFormLayout()` (matches donor's Dagre LR behavior). Custom layouts via subclass.
15. **Callbacks, not state.** Mirroring obj 006 + donor: the canvas is **uncontrolled** by default but accepts a controller for advanced usage. Edits emit callbacks (`onTriggerUpdated`, `onConditionAdded`, `onConditionUpdated`, `onConditionDeleted`, `onActionAdded`, `onActionUpdated`, `onActionDeleted`, `onSaveLayout(EdenWorkflowCanvasLayout)`). Consumer owns persistence — fully transport-agnostic.
16. **Backend gap is NOT a Flutter UI concern.** Per deep-audit §7.3 locked decision: trades-go `entity_created` Zod enum bug is fixed during absorption, NOT as part of this Flutter port. The library SHIPS the `entity_created` trigger type in the enum + toolbox + editor; consumers (eden-biz-flutter) bind it to whatever backend they have. Library does no transport, so it can't observe the bug anyway.

## Success criteria (must-haves, observable truths)

1. All 7 TRDs ship; `flutter analyze` clean; `flutter test` passes (existing tests still pass + ~60–100 new workflow-canvas tests pass).
2. Every parity-checklist row (W-1..W-7, N-1..N-7, T-1..T-3, E-1..E-5, C-1..C-2, L-1..L-3, S-1..S-5, V-1..V-3, X-1..X-5, R-1..R-4) is implemented and has at least one widget or unit test that proves it. Each TRD's `<verify>` references the checklist rows it satisfies.
3. Existing `EdenDiagram` consumer (system-diagram demo in `lib/dev_app/screens/diagram_screen.dart`) compiles and renders without change. Existing `EdenVisualProcessCanvas` consumer (`process_builder_screen.dart`) compiles and renders without change. Backward-compat invariant: NO file in `lib/src/widgets/eden_diagram/` or `lib/src/widgets/eden_process_canvas/` is modified by this objective.
4. `lib/dev_app/screens/workflow_designer_screen.dart` exists and `just dev-ui` renders a workflow-designer demo screen with a sample workflow definition (1 trigger / 1 condition / 3 actions / 1 delay / 1 end), drag-from-toolbox visibly working, popover editors openable, auto-layout button, validation popover.
5. **Drag-from-toolbox works** in widget tests AND in the dev catalog: dragging an action-toolbox item onto the canvas creates a new EdenActionNode at the drop position; `onActionAdded(actionType, config)` callback fires.
6. **Popover editors work:** clicking a Trigger / Action / Condition / Delay node opens the inline popover with the right form, and saving fires the matching `on*Updated` callback.
7. **Context menu works:** right-clicking (long-press on touch) a non-trigger node opens `EdenWorkflowNodeContextMenu` with Delete + Cancel; right-clicking the Trigger node does NOT show Delete.
8. **Validator works:** `EdenWorkflowValidator.validate(...)` returns the same 8 issue shapes as donor (must-have-trigger / only-one-trigger / must-have-action / should-have-end / all-non-trigger-connected / all-non-end-have-outgoing / branch-≥2-outgoing / merge-≥2-incoming / condition-configured). `EdenWorkflowValidationPanel` renders the issues with severity icons + suggestion text.
9. **Bidirectional sync works (S-1 / S-2):** `EdenWorkflowGraphBuilder.toCanvas(definition)` returns nodes + edges; the canvas displays them; consumer edits via callbacks update definition; `EdenWorkflowGraphBuilder.fromCanvas(...)` returns the updated definition with conditions[] + actions[] in execution order. Tests cover both directions.
10. **Auto-layout works:** clicking the auto-layout button re-runs `EdenFreeFormLayout` (BFS rank) and fits viewport. No new layout code; pure composition of obj 006 layout engine.
11. **Action-type registry works:** `EdenWorkflowActionRegistry.instance.register(EdenWorkflowActionType(id: 'send_push', displayName: 'Send Push', icon: Icons.notifications_active))` makes the type available via `lookup('send_push')` and `all()` includes it. `resetToDefaults()` re-registers the 6 defaults exactly.
12. **Category registry works:** library default registry has 5 defaults (appointment / task / project / customer / callback). Consumers can add more (`register(EdenWorkflowCategory(id: 'visit', displayName: 'Patient Visit', icon: Icons.local_hospital))`).
13. **All widget/unit tests use hand-built fixtures** (no LLM-generated test data). Every fixture file has the header line `// Do NOT regenerate via LLM — hand-built fixtures for EdenWorkflow<Aspect>.`.
14. **No new pubspec deps added** — verified by grep on `pubspec.yaml` showing no additions.
15. **Backward compat verified:** existing tests in `test/widgets/eden_diagram/` and `test/widgets/eden_process_canvas/` MUST pass unchanged across all 7 TRDs. Specifically `eden_diagram_back_compat_test.dart` (obj 006 invariant) continues to pass.
16. **iPhone-narrow safe (≥390pt) — workflow designer fallback** — every node widget tested in isolation at `SizedBox(width: 390)` shows no `RenderFlex overflowed` warnings. The full `EdenVisualWorkflowCanvas` tested at `SizedBox(width: 390)` shows the fallback message (not an overflow).
17. **Roadmap updated:** objective 020 added under Active Objectives with TRD checklist (all `[ ]`).

## Out of scope (deferred to later objectives or skipped entirely)

- **WorkflowSidebar.tsx port** (donor right-rail with name / version / status badges / publish button / executions monitor / templates list). The library widget is the canvas itself; the sidebar is app-level chrome composed in `eden-biz-flutter` from existing primitives (EdenPageHeader, EdenBadge, EdenButton). NOT a library widget.
- **WorkflowTemplatesList.tsx + WorkflowTemplateDialog.tsx port** (templates picker UI). App-level concern; not a library primitive.
- **ActiveExecutionsMonitor.tsx port** (live workflow execution status). App-level + transport-coupled; not a library primitive.
- **Field interpolation UX (`{customer.name}` template-string composer)** — `EdenWorkflowEventBrowser` (R-4) ships the field-browser UI but the actual template-string interpolation logic (parse + render) is app-level. Library exposes the registry; consumers wire interpolation downstream.
- **Real backend integration.** The canvas is transport-agnostic; consumers own persistence. Per `eden-libs/CLAUDE.md` ("Keep platform logic in `eden-platform-flutter`, not in `eden-ui-flutter`").
- **Workflow-execution runtime rendering** (visualizing a workflow IN PROGRESS, e.g. blinking the currently-firing action node). The library is for EDITING the template; visualizing executions is a separate downstream concern.
- **Real-time collaborative editing / multi-user cursors.** Not in donor.
- **Undo/redo stack.** Not in donor; relies on callback-driven save + database revert.
- **Workflow versioning + publishing flow** (donor `isPublished`, `version`, Publish button). The canvas exposes the `definition.isPublished` + `definition.version` data and a `onPublish` callback but does NOT implement the version-management logic itself; that's app-layer.
- **Touch-first gestures beyond long-press = right-click.** Donor is mouse-first (React Flow). Library accepts the same semantics.
- **Visual regression baselines** (VRT-01 v2 future objective).
- **Real-device iOS / Android testing** (downstream apps gate this; workflow designer is desktop/tablet UX anyway).
- **AI-suggested workflow structure.** Future enhancement.
- **Workflow template marketplace / catalog.** Out of scope for a UI primitive.
- **Backend Zod-enum `entity_created` fix.** Per locked decision §7.3 of deep-audit: trades-go side, NOT a Flutter UI ticket. Library ships the trigger type; consumer wires the backend.

## References

**Primary donor (canonical — exact parity target):**
- `/Users/markemerson/Source/AOCyber-Trades/trades/client/src/components/workflow/WorkflowDesigner.tsx` (187 LOC — top-level orchestrator)
- `/Users/markemerson/Source/AOCyber-Trades/trades/client/src/components/workflow/WorkflowCanvas.tsx` (612 LOC — canvas root using @xyflow/react)
- `/Users/markemerson/Source/AOCyber-Trades/trades/client/src/components/workflow/WorkflowToolbox.tsx` (288 LOC — drag source with 19 items)
- `/Users/markemerson/Source/AOCyber-Trades/trades/client/src/components/workflow/types.ts` (172 LOC — value types)
- `/Users/markemerson/Source/AOCyber-Trades/trades/client/src/components/workflow/FieldBrowser.tsx` (283 LOC — event/field browser)
- `/Users/markemerson/Source/AOCyber-Trades/trades/client/src/components/workflow/nodes/TriggerNode.tsx` (189 LOC), `ActionNode.tsx` (304 LOC), `BranchNode.tsx` (97 LOC), `ConditionNode.tsx` (244 LOC), `DelayNode.tsx` (209 LOC), `MergeNode.tsx` (97 LOC), `EndNode.tsx` (43 LOC), `index.ts`
- `/Users/markemerson/Source/AOCyber-Trades/trades/client/src/components/workflow/utils/workflowValidation.ts` (164 LOC)
- `/Users/markemerson/Source/AOCyber-Trades/trades/client/src/components/workflow/utils/flowToWorkflowData.ts` (161 LOC — graph BFS extraction)
- `/Users/markemerson/Source/AOCyber-Trades/trades/client/src/components/workflow/hooks/useWorkflowToFlow.ts` (254 LOC — model→flow + Dagre auto-layout)
- `/Users/markemerson/Source/AOCyber-Trades/trades/client/src/components/workflow/WorkflowSidebar.tsx` (NOT ported — app-level)
- `/Users/markemerson/Source/AOCyber-Trades/trades/client/src/components/workflow/WorkflowTemplatesList.tsx` (NOT ported — app-level)
- `/Users/markemerson/Source/AOCyber-Trades/trades/client/src/components/workflow/WorkflowTemplateDialog.tsx` (NOT ported — app-level)
- `/Users/markemerson/Source/AOCyber-Trades/trades/client/src/components/workflow/ActiveExecutionsMonitor.tsx` (NOT ported — app-level)

**Reuse baseline (obj 006 — already shipped, REUSED VERBATIM by this objective):**
- `/Users/markemerson/Source/eden-libs/eden-ui-flutter/lib/src/widgets/eden_diagram/` (5 files — engine: diagram_data.dart with EdenDiagramPort + EdenDiagramNode.ports + hitTestNode + customNodeRenderer; diagram_painter.dart; eden_diagram.dart with onDropTargetChanged; mermaid_parser.dart; eden_diagram_exports.dart)
- `/Users/markemerson/Source/eden-libs/eden-ui-flutter/lib/src/widgets/eden_process_canvas/process_models.dart` (EdenProcessNodePosition, EdenProcessSavedEdge, EdenProcessViewport — REUSED as JSON-compatible value types)
- `/Users/markemerson/Source/eden-libs/eden-ui-flutter/lib/src/widgets/eden_process_canvas/process_layout_engine.dart` (EdenProcessLayoutEngine + EdenFreeFormLayout — REUSED via composition / typedef)
- `/Users/markemerson/Source/eden-libs/eden-ui-flutter/lib/src/widgets/eden_process_canvas/process_controller.dart` (EdenProcessController shape — INSPIRATION for EdenWorkflowController, not direct reuse)
- `/Users/markemerson/Source/eden-libs/eden-ui-flutter/lib/src/widgets/eden_process_canvas/eden_node_context_menu.dart` (REUSED via composition if API allows; else dedicated EdenWorkflowNodeContextMenu)
- `/Users/markemerson/Source/eden-libs/eden-ui-flutter/lib/src/widgets/eden_process_canvas/process_validator.dart` (EdenProcessValidationIssue value-type shape — REUSED; ship EdenWorkflowValidationIssue as a `typedef = EdenProcessValidationIssue` or distinct shape if validation rules need different metadata)

**Library context:**
- `.planning/PROJECT.md` (transport-agnostic constraint, test pattern, validation commands)
- `.planning/TRADES_REMAP_DEEP_AUDIT_2026-05-15.md` §2.2 (A4-b sub-system spec) + §6 (sub-system tracks) + §7.3 (locked decisions on backend gap)
- `.planning/objectives/006-a4a-visual-process-canvas/OBJECTIVE.md` (canonical pattern for this objective; donor parity-checklist format; wave structure; constraints)
- `.planning/objectives/006-a4a-visual-process-canvas/006-01-TRD.md` (canonical TRD shape for value-types + registry foundations)
- `.planning/objectives/006-a4a-visual-process-canvas/006-04-TRD.md` (canonical TRD shape for node widgets)
- `eden-libs/CLAUDE.md` ("Keep platform logic in `eden-platform-flutter`, not in `eden-ui-flutter`")
- `~/.claude/CLAUDE.md` TDD Playbook (global — strict TDD + test-list-first + hand-built fixtures + outside-in for UI)

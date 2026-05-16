---
objective: 006-a4a-visual-process-canvas
kind: ui-lib
work: feature
status: planned
estimated_effort: 4 weeks Claude execution
trd_count: 15
waves: 5
---

# Objective 006 — A4-a Visual Process Canvas Port from trades-react

## Goal

Port the trades-react Visual Process Builder (`AOCyber-Trades/trades/client/src/components/customizations/processes/visual-builder/` — 21 files, 3819 LOC) into `eden-ui-flutter` as a generic, vertical-agnostic, transport-agnostic process-builder primitive. After this objective ships, every Eden Biz vertical (trades, salon, medical, fuel, retail, legal, gov) composes a process builder with the same node grammar (Start / End / Phase / TaskGroup / Task / Decision / Orphan), the same drag-from-toolbox UX, the same context-menu editing affordances, the same swimlane + free-form layout engines, and the same model-to-canvas bidirectional sync — without re-implementing any of it.

The objective EXTENDS the existing `eden_diagram/` sub-suite (currently consumed only by system-diagram rendering); it does NOT create a parallel top-level subdir. The process builder is the **second consumer** of the eden_diagram engine; system-diagrams was the first. Engine gaps surfaced during the port (drag-from-toolbox drop-target hit-testing, multi-handle ports, custom-widget node rendering) land as additive enhancements to eden_diagram in Wave 1, then the process-builder widgets stack on top.

**Parity definition (acceptance):** every donor feature in the **Donor-parity checklist** below is implemented as a generic library widget under `lib/src/widgets/eden_diagram/` (engine extensions) + `lib/src/widgets/eden_process_canvas/` (process-builder-specific widgets), has at least one widget test (hand-built fixtures), and is visible in the dev catalog under a new `process_builder_screen.dart`. Side-by-side review of a populated `EdenVisualProcessCanvas` demo vs trades-react VisualProcessCanvas shows the same feature set is present (same 7 node types, same toolbox, same context menus, same dialogs, same swimlane shape, same free-form drag-routing).

## Why now

- **Locked decisions (deep-audit 2026-05-15 §7 + companion locks):** process-builder metaphor supports BOTH swimlane (default per Mark) and free-form canvas. Entity-type is registry-driven (verticals register via `verticalsdk.RegisterProcessEntityType` — backend cleanup is eden-biz#53, tracked separately). Process builder STAYS GENERIC (vertical-agnostic). Library extends `eden_diagram/`, not a new top-level subdir.
- **Donor stability:** trades-react `visual-builder/` is mature, in-production, 21 files of focused code. The port has a known-good reference.
- **Engine reuse:** the existing eden_diagram canvas (pan/zoom/grid/edge-routing/hit-testing) handles ~60% of what's needed. Gaps are surgical (drag-target hit-test, multi-handle ports, custom-widget node rendering). Cheaper than the trades-react port from scratch.
- **Cadence proven:** objectives 001-004 GREEN. TDD discipline (Iron Law + test-list-first + hand-built fixtures + outside-in), `wrap()` test helper, dev-catalog pattern, file-collision discipline on `lib/eden_ui.dart` — all proven across ~445 widget tests on 51 widgets.
- **Downstream demand:** trades vertical needs Visual Process Builder to ship process-template editing UX in eden-biz-flutter. Salon, medical, fuel verticals all have process-template work coming next. They all compose the same primitive — this library widget — with their domain entity types mapped to the library's generic registry.
- **Active initiative alignment** (advisory, from `feedback_planner_proto_conflict.md` + `project_verticals_milestone_planning_2026-05-06.md`): objective 006 directly advances the Eden Biz Beta milestone Track A4 (visual builders); the next sub-system tracks (A4-b Workflow Designer, A4-c Template Block Builder per deep-audit §2.2 + §6) reuse this objective's engine extensions and node-grammar pattern, so getting the API surface right here pays back ≈2x.

## Donor-parity checklist (derived from `client/src/components/customizations/processes/visual-builder/`)

The donor exposes the following UX-observable features. Each row is a parity target — every TRD lists which rows it satisfies and the acceptance test that proves the parity.

### N. Node types (7 total)

| ID | Donor surface | Library target | TRD |
|---|---|---|---|
| N-1 | `StartNode.tsx` — green circle, Play icon, source-only port (bottom) | `EdenProcessStartNode` | 04 |
| N-2 | `EndNode.tsx` — red circle, Square icon, target-only port (top) | `EdenProcessEndNode` | 04 |
| N-3 | `PhaseNode.tsx` — colored card (8 colors), expand/collapse, inline group preview, drop-target highlight, top/left/right/bottom handles | `EdenProcessPhaseNode` | 05 |
| N-4 | `TaskGroupNode.tsx` — bordered card, inline task list rows w/ toggles (Req/Photo/Sig/Approve), per-task add/edit/delete/reorder, workflow-hook badge, drop-target highlight | `EdenProcessTaskGroupNode` | 06 |
| N-5 | `TaskNode.tsx` — small card, runtime-component icon (15 component types), requirement badges, form-fields badge, optional indicator, top/left/right/bottom handles | `EdenProcessTaskNode` | 07 |
| N-6 | `DecisionNode.tsx` — rotated-diamond shape, GitBranch icon, name + condition popover, yes (right=green) / no (bottom=red) / target (top=amber) handles | `EdenProcessDecisionNode` | 07 |
| N-7 | `OrphanNode.tsx` — neutral card showing not-yet-connected element, type-icon, delete button, full 4-handle ports | `EdenProcessOrphanNode` | 04 |

### T. Toolbox + drag-from-palette

| ID | Donor surface | Library target | TRD |
|---|---|---|---|
| T-1 | `Toolbox.tsx` — left rail (208pt), categorized items (Structure / Tasks / Templates), drag source via `dataTransfer.setData('application/reactflow-type', ...)` | `EdenProcessToolbox` (drag source, registry-driven items) | 12 |
| T-2 | Toolbox templates section — sorted by workCategoryId match, "rec" badge for recommended | `EdenProcessToolbox.templateItems` slot (consumer provides templates) | 12 |
| T-3 | Click-to-add fallback when drag isn't viable (touch / no-drag) | `EdenProcessToolbox.onAddNode` callback | 12 |

### D. Drop / drag-target handling on canvas

| ID | Donor surface | Library target | TRD |
|---|---|---|---|
| D-1 | `findNodeAtPosition(clientX, clientY)` — flowPosition→canvas conversion, hit-test by node bounds | `EdenDiagramController.hitTestNode(Offset)` (new engine API) | 02 |
| D-2 | `dropTargetNodeId` state — highlights phase/group nodes during drag-over | `EdenDiagram.onDropTargetChanged(String? nodeId)` callback + visual ring | 02 |
| D-3 | Drop on a taskGroup → add task to that group (donor `onAddTaskToGroup`) | `EdenVisualProcessCanvas.onDropTask(target, config)` callback | 14 |
| D-4 | Drop on a phase → add task to that phase (or add taskGroup if drop=taskGroup) | `EdenVisualProcessCanvas.onDropTask/.onDropTaskGroup` callbacks | 14 |
| D-5 | Drop on empty canvas → add to first phase (donor fallback) | Same callbacks, target=null | 14 |
| D-6 | Inline task drag-over → "split into new group" (donor `onSplitTaskToNewGroup`) | `EdenProcessTaskGroupNode.onTaskDropOnRow(taskId)` callback | 06 |

### E. Edge / connection handling

| ID | Donor surface | Library target | TRD |
|---|---|---|---|
| E-1 | User-drawn edges persist (donor `userEdges` state — survives re-renders, saved to layout) | `EdenDiagramController.userEdges` + `onUserEdgesChanged` callback | 03 |
| E-2 | Edge styling: `smoothstep` 2pt indigo for user-drawn; dashed 1.5pt for auto-generated phase→group | `EdenProcessEdgeStyle.user / .autoFan` | 03 |
| E-3 | Right-click edge → context menu with Delete | `EdenEdgeContextMenu` | 11 |
| E-4 | Drag from port → preview line → connect; `connectOnClick: false` | Already in eden_diagram engine; verify edge-creation callback fires | 02 |
| E-5 | Multi-handle ports per node (decision has yes/no/top/left; phase has top/right/bottom/left) | `EdenDiagramNode.ports: List<EdenDiagramPort>` (new — extends current 4-direction fixed model) | 02 |

### C. Context menus

| ID | Donor surface | Library target | TRD |
|---|---|---|---|
| C-1 | `NodeContextMenu` — right-click node, Add Task / Add Task Group / Apply Template (phase) / Edit / Delete | `EdenNodeContextMenu` (action slots — consumer provides items per node-type) | 11 |
| C-2 | Submenu for Apply Template (templates list) | `EdenNodeContextMenu.submenuItems` slot | 11 |
| C-3 | `EdgeContextMenu` — right-click edge, Delete Connection | `EdenEdgeContextMenu` | 11 |
| C-4 | Click-outside dismiss | Both menus | 11 |

### L. Layout engines

| ID | Donor surface | Library target | TRD |
|---|---|---|---|
| L-1 | `applySwimLaneLayout` — phases vertical spine left, groups fan right, parent-tracking via edges | `EdenSwimlaneLayout` (default) | 08 |
| L-2 | `applyDagreLayout` — Dagre directed-graph LR layout, node-type-aware sizing | `EdenFreeFormLayout` (manual graph-layout, NOT a Dagre dep — see gotchas) | 09 |
| L-3 | `applyGridLayout` / `applyLinearLayout` — simple fallbacks | `EdenGridLayout` + `EdenLinearLayout` (helpers on `EdenProcessLayouts`) | 09 |
| L-4 | Auto-layout button → re-layout + fitView (donor `handleAutoLayout`) | `EdenVisualProcessCanvas.autoLayout()` API | 14 |
| L-5 | Saved positions persist (donor `process.config.layout.nodes` keyed by nodeId) | `EdenProcessLayoutData` value type (positions + edges); consumer round-trips | 03 |

### S. Sync / hooks (model ↔ canvas)

| ID | Donor surface | Library target | TRD |
|---|---|---|---|
| S-1 | `useProcessToFlow(process, callbacks)` — converts ProcessDefinition → nodes+edges, wires callbacks into node data | `EdenProcessGraphBuilder` (pure function: `EdenProcessDefinition → (nodes, edges)`) + `EdenProcessController` (manages canvas state + delegates callbacks) | 03 |
| S-2 | Preserve manual node positions on re-render (donor `currentPositions` map) | `EdenProcessController.preserveManualPositions = true` (default) | 03 |
| S-3 | Pending positions for newly-created elements (donor `pendingPositions`) | `EdenProcessController.pendingPositions: Map<String, Offset>` | 03 |
| S-4 | Orphan nodes tracked separately, removed via `onDelete` | `EdenProcessController.orphans` + `addOrphan/removeOrphan` | 03 |
| S-5 | Layout save extracts positions + user-drawn edges (donor `handleSave`) | `EdenProcessController.toLayoutData() → EdenProcessLayoutData` | 03 |

### V. Validation

| ID | Donor surface | Library target | TRD |
|---|---|---|---|
| V-1 | `validateProcess` — orphan-detection, empty-phase, empty-group, decision missing branches, disconnected nodes, no-phases-error | `EdenProcessValidator.validate(definition, nodes, edges) → EdenProcessValidationResult` | 13 |
| V-2 | `getValidationSummary` — errors + warnings counts | `EdenProcessValidationResult.summary` getter | 13 |
| V-3 | Validation popover — error / warning lists, click-to-focus node | `EdenProcessValidationPanel` (consumer composes into canvas chrome) | 14 |

### X. Editor dialogs

| ID | Donor surface | Library target | TRD |
|---|---|---|---|
| X-1 | `PhaseEditorDialog` — name + description (debounced save), color swatch, checkbox flags | `EdenProcessPhaseEditorDialog` | 10 |
| X-2 | `TaskGroupEditorDialog` — group name/description, collapsed-default, required, template-import, task list w/ inline add/edit/delete | `EdenProcessTaskGroupEditorDialog` | 10 |
| X-3 | `TaskEditorDialog` — task name/description, runtime-component picker (15 components), required flags (photo/sig/approval/etc.), workflow hooks | `EdenProcessTaskEditorDialog` | 10 |

### R. Entity-type registry (locked decision §7.2)

| ID | Locked decision | Library target | TRD |
|---|---|---|---|
| R-1 | Entity types must be registry-driven (NOT enum-locked to `project / appointment / bid`). Verticals register their types. | `EdenProcessEntityTypeRegistry` (singleton w/ `register(EdenProcessEntityType)`, `lookup(String id)`, `all() → List`) — generic, no domain knowledge | 01 |
| R-2 | Runtime-component types similarly registry-driven (donor hard-codes 15 components: checklist, form, kanban, status_selector, photo_gallery, signature_capture, document_upload, approval_gate, timeline, notes_log, equipment_list, materials_tracker, lien_waiver_tracker, closeout_checklist, multi_checklist) | `EdenProcessRuntimeComponentRegistry` (singleton, register IconData + label per id; library ships a sensible default set but consumers override) | 01 |

## Wave structure (parallelism map)

| Wave | TRDs | Theme | Parallelism |
|---|---|---|---|
| **1** | 006-01, 006-02, 006-03 | Foundation — value types + entity-type registry + eden_diagram engine extensions + EdenProcessController | 01 first (blocks 02/03); 02 + 03 parallel after 01 (different files in eden_diagram/) |
| **2** | 006-04, 006-05, 006-06, 006-07 | Atomic node widgets — Start/End/Orphan / Phase / TaskGroup / Task+Decision | All 4 parallel; each owns its own files; depend on Wave 1 |
| **3** | 006-08, 006-09 | Layout engines — swimlane (default) + free-form (manual graph) + grid/linear helpers | 08 + 09 parallel; both depend on Wave 1 |
| **4** | 006-10, 006-11, 006-12 | Editing UX — 3 editor dialogs / context menus / toolbox | All 3 parallel; depend on Wave 2 nodes |
| **5** | 006-13, 006-14, 006-15 | Composition + validation + demo | 13 first (validator is referenced by 14); 14 composes everything; 15 dev catalog screen (depends on 14) |

**File-collision discipline:**
- `lib/eden_ui.dart` — every TRD that adds a public surface appends 1-2 export lines under a NEW section header per wave (`// Objective 006 — Process canvas Wave N`). Mark each TRD `co_modified_files: [lib/eden_ui.dart]` so the orchestrator serializes the edit step within a wave.
- `lib/src/widgets/eden_diagram/diagram_data.dart` — TRDs 01 and 02 BOTH modify this (01 adds value types like `EdenDiagramPort`; 02 extends `EdenDiagramNode` with `ports` + `customRenderer`). Mark `co_modified_files: [lib/src/widgets/eden_diagram/diagram_data.dart]`. TRD 01 ships first within Wave 1; TRD 02 follows.
- `lib/src/widgets/eden_diagram/eden_diagram.dart` — TRD 02 modifies the canvas widget to support drop-target hit-test + custom-widget node rendering. Single owner within Wave 1.
- `lib/src/widgets/eden_diagram/eden_diagram_exports.dart` — TRDs 01 and 02 BOTH append exports. Serialize within Wave 1.
- `lib/dev_app/screens/diagram_screen.dart` exists already — leave UNCHANGED. Process-builder demo goes in a NEW file `lib/dev_app/screens/process_builder_screen.dart` (TRD 15).
- `lib/dev_app/screens/home_screen.dart` — TRD 15 adds one nav entry pointing to the new process-builder screen.

## Constraints (locked, do not revisit)

1. **EXTEND eden_diagram, do not fork.** All engine gaps (drag-target hit-test, multi-handle ports, custom-widget node renderers) land as additive extensions to `lib/src/widgets/eden_diagram/`. Process-builder-specific widgets (`EdenProcess*`) live in NEW `lib/src/widgets/eden_process_canvas/`. The two subsuites compose; they do not duplicate canvas/painter logic.
2. **Generic + vertical-agnostic.** No trades-specific fields anywhere. Domain shapes (`ProcessDefinition`, `ProcessPhase`, `ProcessTaskGroup`, `ProcessTaskTemplate`) are generic Dart classes named in cross-vertical terms. Donor's domain-specific fields (`runtimeComponentConfig`, `linkedTaskTemplateId`, `workflowHookId`) become `Map<String, dynamic> data` slots; verticals project their domain into the slot. Entity types and runtime-component types are registry-driven (R-1, R-2).
3. **Transport-agnostic.** No new pubspec deps. NO `dagre` equivalent — implement free-form layout by hand (BFS/DFS-based column assignment; see gotchas in TRD 09). NO `xyflow` equivalent — eden_diagram engine handles canvas. NO `flutter_flow_chart` — same reason. The existing `flutter/material.dart` + `flutter/widgets.dart` + `dart:ui` + `dart:math` are enough.
4. **TDD strict (Iron Law) + test-list-first.** Every TRD's testable tasks carry `tdd="true"`. Test-list checklist at the top of every TRD enumerating happy/edge/failure cases BEFORE any test code. **Hand-built fixture builders only (no LLM-generated test data)** — `no_llm_test_data` constraint active. Fixture files named `test/widgets/_fixtures/eden_process_<aspect>_fixtures.dart` with header line `// Do NOT regenerate via LLM — hand-built fixtures for EdenProcess<Aspect>.`. One test at a time through RED → GREEN → REFACTOR per `~/.claude/CLAUDE.md` TDD Playbook habits 1–4.
5. **Outside-in for UI flows.** Per `~/.claude/CLAUDE.md` Playbook habit 5: pure-logic helpers (validation, layout math, graph build) start at unit level. Composite widgets (canvas + node + toolbox wired together in `EdenVisualProcessCanvas`) get system-level widget tests asserting "given a `ProcessDefinition`, renders N phase nodes at correct positions, dragging a task from toolbox onto group fires `onAddTaskToGroup(groupId, config)`". Individual node widgets get unit-level widget tests.
6. **Test pattern locked.** `testWidgets('renders ...', (tester) async {...})` with `wrap()` helper at the top of each test file. Mirror `test/widgets/eden_alert_test.dart`. Widget tests, NOT integration tests.
7. **iPhone-narrow safe (≥390pt) — process builder is desktop/tablet UX with a graceful narrow fallback.** Per deep-audit §5 the process builder is fundamentally a 1200pt+ canvas UX (Material 3 Expanded tier). At <1200pt, library widgets MUST render a **read-only fallback** message ("Process builder requires tablet/desktop width — switch to mobile-summary view") rather than overflow. The fallback widget exists at the canvas root (`EdenVisualProcessCanvas`); individual node widgets MUST themselves not overflow at 390pt (they're tested in isolation at narrow widths and render compactly).
8. **Material 3 + tokens.** Use `EdenSpacing`, `EdenRadii`, `EdenColors`, `EdenTypography` from `lib/src/tokens/` where they apply. Donor uses Tailwind palette colors (`bg-blue-500`, `bg-green-500`, `bg-amber-50`, etc.) for node fills — map to `EdenColors.semantic` palette where possible; if a donor color has no token equivalent, hard-code with comment `// donor color — keep until token system has equivalent`.
9. **Visual catalog entry.** TRD 15 creates `lib/dev_app/screens/process_builder_screen.dart` with a populated demo — Start → 3 Phases (each with 2 groups, 3-5 tasks per group) → End — plus a Decision node, an orphan, drag-from-toolbox working, both swimlane + free-form layouts switchable via toggle, dialogs openable via context menu. TRD 15 also adds one nav tile to `home_screen.dart`. Earlier TRDs do NOT modify the dev catalog (per file-collision discipline).
10. **No breaking changes to existing widgets.** Existing 51+ widget exports + ~445+ tests must continue to pass. This objective is purely additive to the public surface (`lib/eden_ui.dart`). The existing `EdenDiagram` widget signature gains optional parameters; existing parameters' signatures are forbidden from changing.
11. **No new pubspec dependencies.** Period. If a TRD believes it needs one, it MUST justify in `<context>` and add it explicitly; default assumption is no new deps. Free-form layout uses hand-rolled graph algorithms; recurrence (if needed elsewhere) is hand-rolled.
12. **Entity-type and runtime-component registries are SINGLETONS but reset-able for tests.** `EdenProcessEntityTypeRegistry.instance` exposes `register()`, `lookup()`, `all()`, and `reset()`. Tests MUST call `reset()` in `setUp` to avoid bleed across tests. The library ships a sensible default runtime-component set (≥6 of donor's 15) registered at library init; consumers add their own via `register()`.
13. **Decomposition principle — generic, hand-rolled, NOT 1:1 donor translation.** Donor `VisualProcessCanvas.tsx` is 1012 LOC of React Flow integration. The Dart equivalent (`EdenVisualProcessCanvas` in TRD 14) target is <400 LOC because the engine work (eden_diagram extensions in TRD 02) absorbs the React-Flow boilerplate. If a TRD is approaching donor's LOC count, it's translating too literally — re-grep the donor for the LOGIC, drop the React-Flow scaffolding.
14. **Layout engine pluggability.** `EdenVisualProcessCanvas` exposes `layout: EdenProcessLayoutEngine` (sealed-ish): `EdenSwimlaneLayout()` (default) | `EdenFreeFormLayout()` | `EdenGridLayout()` | `EdenLinearLayout()` | custom subclass. Swap is a constructor parameter; no re-instantiation cost.
15. **Callbacks, not state.** Mirroring the donor: the canvas is **uncontrolled** by default but accepts a controller for advanced usage. Edits emit callbacks (`onAddPhase`, `onUpdatePhase`, `onDeletePhase`, `onAddTaskGroup`, `onUpdateTaskGroup`, `onDeleteTaskGroup`, `onAddTask`, `onUpdateTask`, `onDeleteTask`, `onAddDecision`, `onUpdateDecision`, `onDeleteDecision`, `onSaveLayout(EdenProcessLayoutData)`). Consumer owns persistence — fully transport-agnostic.

## Success criteria (must-haves, observable truths)

1. All 15 TRDs ship; `flutter analyze` clean; `flutter test` passes (existing 445+ tests still pass + ~120–180 new process-canvas tests pass).
2. Every parity-checklist row (N-1..N-7, T-1..T-3, D-1..D-6, E-1..E-5, C-1..C-4, L-1..L-5, S-1..S-5, V-1..V-3, X-1..X-3, R-1..R-2) is implemented and has at least one widget or unit test that proves it. Each TRD's `<verify>` references the checklist rows it satisfies.
3. Existing `EdenDiagram` consumer (system-diagram demo in `lib/dev_app/screens/diagram_screen.dart`) compiles and renders without change. Backward-compat invariant: the existing `EdenDiagram` constructor signature still works; new optional parameters (`ports`, `customNodeRenderer`, `onDropTargetChanged`) default to safe no-ops.
4. `lib/dev_app/screens/process_builder_screen.dart` exists and `just dev-ui` renders a process-builder demo screen with switchable layout (swimlane / free-form), sample process definition (3 phases / 6 groups / ~18 tasks / 1 decision / 1 orphan), drag-from-toolbox visibly working, context menus working, dialogs openable.
5. **Drag-from-toolbox works** in widget tests AND in the dev catalog: `tester.drag(find.byType(EdenProcessToolbox).at(0), Offset(400, 200))` simulates the drag (or programmatic `controller.simulateDrop(...)`), and on drop the `onAddTask(target, config)` callback fires with the expected target and config.
6. **Drop-target highlight works:** dragging a toolbox item over a `PhaseNode` or `TaskGroupNode` highlights it (visual ring), and dragging OFF clears it.
7. **Context menus work:** right-clicking (long-press on touch) a node opens `EdenNodeContextMenu` with the correct items per node type (Phase: Add Task / Add Group / Apply Template / Edit / Delete; TaskGroup: Add Task / Edit / Delete; Task: Edit / Delete; Decision: Edit / Delete; Edge: Delete Connection).
8. **Editor dialogs work:** opening the Phase / TaskGroup / Task editor dialog via context-menu Edit shows the editable fields, debounced text saves on blur, immediate-save toggles for non-text fields all fire the `onUpdate*` callbacks.
9. **Swimlane layout works:** with `layout: EdenSwimlaneLayout()`, phases stack vertically on the left, groups fan out to the right, group column auto-heights to inline-task count.
10. **Free-form layout works:** with `layout: EdenFreeFormLayout()`, nodes flow left-to-right based on edge dependencies (BFS rank assignment), no overlapping nodes, auto-fit to bounds.
11. **Validation works:** `EdenProcessValidator.validate(...)` returns the same issue shape as donor (orphan-warning, empty-phase-warning, empty-group-warning, decision-missing-branches-error, disconnected-node-warning, no-phases-error). `EdenProcessValidationPanel` renders the issues with severity icons + suggestion text + click-to-focus.
12. **Entity-type registry works:** `EdenProcessEntityTypeRegistry.instance.register(EdenProcessEntityType(id: 'service_visit', displayName: 'Service Visit', icon: Icons.build))` makes the type available via `lookup('service_visit')` and `all()` includes it. `reset()` clears all registrations.
13. **Runtime-component registry works:** library default registry has 6+ component types (`checklist`, `form`, `photo_gallery`, `signature_capture`, `approval_gate`, `notes_log` at minimum). Consumers can add more.
14. **Bidirectional sync works (S-1 through S-5):** `EdenProcessGraphBuilder.build(definition)` returns nodes + edges; the canvas displays them; consumer edits via callbacks update definition; re-building from updated definition preserves manual node positions; orphan tracking works.
15. **All widget/unit tests use hand-built fixtures** (no LLM-generated test data). Every fixture file has the header line `// Do NOT regenerate via LLM — hand-built fixtures for EdenProcess<Aspect>.`.
16. **No new pubspec deps added** — verified by grep on `pubspec.yaml` showing no additions.
17. **Backward compat verified by regression test:** `test/widgets/eden_diagram/eden_diagram_back_compat_test.dart` exercises the existing `EdenDiagram(data: ...)` constructor + sample diagram data; this test MUST pass unchanged across all 15 TRDs.
18. **iPhone-narrow safe (≥390pt) — process builder fallback** — every node widget tested in isolation at `SizedBox(width: 390)` shows no `RenderFlex overflowed` warnings. The full `EdenVisualProcessCanvas` tested at `SizedBox(width: 390)` shows the fallback message (not an overflow).
19. **Roadmap updated:** objective 006 added under Active Objectives with TRD checklist (all `[ ]`).

## Out of scope (deferred to later objectives or skipped entirely)

- **A4-b WorkflowDesigner port** (deep-audit §2.2 — 20 files, 7 workflow node types). Separate objective, depends on A4-a engine landing first. Reuses everything this objective builds.
- **A4-c TemplateBlockBuilder port** (deep-audit §6 — third visual-builder consumer of eden_diagram). Separate objective, post-A4-a.
- **Real backend integration.** The canvas is transport-agnostic; consumers own persistence. Per `eden-libs/CLAUDE.md` ("Keep platform logic in `eden-platform-flutter`, not in `eden-ui-flutter`").
- **Process-instance runtime rendering** (donor `runtimeComponentConfig` slots — `checklist`, `form`, `photo_gallery`, etc. each render an interactive widget when the process is being EXECUTED). The visual builder is for EDITING the template; rendering instances is a separate downstream concern handled by `eden-biz-flutter` or similar app-layer consumers. Library exposes the runtime-component-id registry; rendering the actual runtime widget for an in-progress process belongs higher in the stack.
- **Real-time collaborative editing / multi-user cursors.** Not in donor. Consumer concern if needed later.
- **Undo/redo stack.** Not in donor; donor relies on callback-driven save + database revert. Library defers to consumer.
- **Process-template versioning + publishing flow** (donor `isPublished`, `hasUnpublishedChanges`, `onPublish`, `onRevert` workflow). The canvas exposes the `process.isPublished` data and `onPublish` / `onRevert` callbacks but does NOT implement the version-management logic itself; that's app-layer.
- **Drag-to-create-new-phase / drag-to-reorder-phases.** Donor doesn't have this; phase add/order comes through toolbox + sortOrder field. Same for library v1.
- **Touch-first gestures beyond long-press = right-click.** Donor is mouse-first (React Flow). Library accepts the same semantics. If a future objective demands gesture-first process editing on tablet, that's a follow-up.
- **Visual regression baselines** (VRT-01 v2 future objective).
- **Real-device iOS / Android testing** (downstream apps gate this; process builder is desktop/tablet UX anyway).
- **AI-suggested process structure** ("suggest a phase between these two"). Future enhancement; not in donor; not a library concern.
- **Process template marketplace / catalog.** Out of scope for a UI primitive.

## References

**Primary donor (canonical — exact parity target):**
- `/Users/markemerson/Source/AOCyber-Trades/trades/client/src/components/customizations/processes/visual-builder/VisualProcessCanvas.tsx` (1012 LOC — the canvas root using `@xyflow/react`)
- `/Users/markemerson/Source/AOCyber-Trades/trades/client/src/components/customizations/processes/visual-builder/Toolbox.tsx` (188 LOC — drag source)
- `/Users/markemerson/Source/AOCyber-Trades/trades/client/src/components/customizations/processes/visual-builder/types.ts` (220 LOC — value types)
- `/Users/markemerson/Source/AOCyber-Trades/trades/client/src/components/customizations/processes/visual-builder/index.ts` (32 LOC — public exports)
- `/Users/markemerson/Source/AOCyber-Trades/trades/client/src/components/customizations/processes/visual-builder/NodeContextMenu.tsx` (111 LOC)
- `/Users/markemerson/Source/AOCyber-Trades/trades/client/src/components/customizations/processes/visual-builder/EdgeContextMenu.tsx` (38 LOC)
- `/Users/markemerson/Source/AOCyber-Trades/trades/client/src/components/customizations/processes/visual-builder/nodes/StartNode.tsx` (30 LOC), `EndNode.tsx` (30 LOC), `OrphanNode.tsx` (120 LOC), `PhaseNode.tsx` (260 LOC), `TaskGroupNode.tsx` (409 LOC), `TaskNode.tsx` (311 LOC), `DecisionNode.tsx` (198 LOC), `index.ts` (19 LOC)
- `/Users/markemerson/Source/AOCyber-Trades/trades/client/src/components/customizations/processes/visual-builder/dialogs/PhaseEditorDialog.tsx` (195 LOC), `TaskGroupEditorDialog.tsx` (334 LOC), `TaskEditorDialog.tsx` (583 LOC)
- `/Users/markemerson/Source/AOCyber-Trades/trades/client/src/components/customizations/processes/visual-builder/utils/layoutEngine.ts` (258 LOC — Dagre + swimlane + grid + linear)
- `/Users/markemerson/Source/AOCyber-Trades/trades/client/src/components/customizations/processes/visual-builder/utils/processValidation.ts` (146 LOC)
- `/Users/markemerson/Source/AOCyber-Trades/trades/client/src/components/customizations/processes/visual-builder/hooks/useProcessToFlow.ts` (294 LOC — model ↔ flow sync)
- `/Users/markemerson/Source/AOCyber-Trades/trades/client/src/components/customizations/processes/visual-builder/edges/index.ts` (11 LOC — placeholder edge registry)

**Secondary reference (Flutter prior art — inspiration on Dart idioms ONLY, NOT for parity decisions):**
- `/Users/markemerson/Source/AOCyber-Trades/trades-flutter/lib/features/process_builder/presentation/widgets/swimlane_canvas.dart` (527 LOC — Flutter swimlane variant with TransformationController + InteractiveViewer + CustomPaint dot grid; informs the swimlane layout TRD's Dart idioms)
- `/Users/markemerson/Source/AOCyber-Trades/trades-flutter/lib/features/process_builder/presentation/widgets/swimlane_toolbar.dart` (167 LOC)
- `/Users/markemerson/Source/AOCyber-Trades/trades-flutter/lib/features/process_builder/presentation/widgets/process_sidebar.dart` (437 LOC)
- `/Users/markemerson/Source/AOCyber-Trades/trades-flutter/lib/features/process_builder/domain/process_builder_model.dart` (215 LOC)
- `/Users/markemerson/Source/AOCyber-Trades/trades-flutter/lib/features/process_builder/domain/process_template_model.dart` (417 LOC)

**Library context:**
- `.planning/PROJECT.md` (transport-agnostic constraint, test pattern, validation commands)
- `.planning/TRADES_REMAP_DEEP_AUDIT_2026-05-15.md` §2.1 (A4-a sub-system spec) + §7 (locked decisions)
- `.planning/objectives/004-eden-scheduler-enhancement/` (canonical TRD shape; e.g. 004-01, 004-03, 004-09 swimlane analogue, 004-10 event-block analogue)
- `.planning/objectives/001-wave-a-cross-vertical-fundamentals/` (TRD shape patterns)
- `lib/src/widgets/eden_diagram/diagram_data.dart` + `diagram_painter.dart` + `eden_diagram.dart` + `eden_diagram_exports.dart` + `mermaid_parser.dart` (existing engine — extension target)
- `lib/dev_app/screens/diagram_screen.dart` (existing diagram demo — DO NOT MODIFY; reference for screen patterns)
- `eden-libs/CLAUDE.md` ("Keep platform logic in `eden-platform-flutter`, not in `eden-ui-flutter`")
- `~/.claude/CLAUDE.md` TDD Playbook (global — strict TDD + test-list-first + hand-built fixtures + outside-in for UI)

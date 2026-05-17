---
objective: 021-a4c-template-block-builder
trd: "021-03"
subsystem: template-builder
tags: [wave-2, canvas, layout-engine, freeform-composes-eden_diagram, narrow-fallback]
requires:
  - EdenTemplateBlock
  - EdenTemplateGraph
  - EdenTemplateSection
  - EdenTemplateBlockRegistry
  - EdenDiagram (obj 006)
  - EdenDiagramData (obj 006)
  - EdenDiagramNode (obj 006)
provides:
  - EdenTemplateLayoutEngine
  - EdenTemplateVerticalStackLayout
  - EdenTemplateFreeformLayout
  - EdenTemplateBuilderCanvas
  - EdenTemplateBlockPlaceholder
affects:
  - lib/src/widgets/eden_template_builder/eden_template_builder_exports.dart
tech-stack:
  added: []
  patterns:
    - layout-engine-strategy (mirrors obj 006 EdenProcessLayoutEngine pattern)
    - reorderable-list-view-newindex-quirk-hidden
    - drag-target-with-candidate-highlight
    - composes-eden_diagram-NOT-extends
    - layout-builder-narrow-fallback-1200pt
key-files:
  created:
    - lib/src/widgets/eden_template_builder/template_layout_engine.dart
    - lib/src/widgets/eden_template_builder/eden_template_block_placeholder.dart
    - lib/src/widgets/eden_template_builder/eden_template_builder_canvas.dart
    - test/widgets/eden_template_builder/_fixtures/eden_template_canvas_fixtures.dart
    - test/widgets/eden_template_builder/eden_template_block_placeholder_test.dart
    - test/widgets/eden_template_builder/eden_template_builder_canvas_test.dart
  modified:
    - lib/src/widgets/eden_template_builder/eden_template_builder_exports.dart
decisions:
  - "Layout engine base is `abstract class` (not `sealed`) — Dart's sealed requires same-library subclasses; abstract documents the closed-set expectation while allowing experimentation. Canvas throws StateError on unknown subtypes."
  - "Canvas exposes `handleReorderForTest(oldIndex, newIndex)` so unit tests can drive the public reorder pipeline without touching ReorderableListView's gesture stack. Documented as internal."
  - "Freeform mode wraps EdenDiagram in SizedBox(height: 600) for stable rendering; consumer can wrap canvas in their own height-controlling parent for different sizing."
  - "ReorderableListView uses `buildDefaultDragHandles: false` + ReorderableDragStartListener wrappers so the placeholder's existing drag-indicator icon area is the drag trigger (not a default trailing reorder handle)."
  - "Footer indicator parameters `currentPage` + `totalPages` exposed on the canvas API; default both to 1 (consumer-driven pagination integration)."
  - "iPhone-narrow fallback strict <1200pt boundary; 1200pt itself shows full canvas (Material 3 desktop tier breakpoint)."
metrics:
  duration_minutes: 15
  completed: 2026-05-17
  tests_added: 24
  files_created: 6
  files_modified: 1
---

# Objective 021 TRD 021-03: EdenTemplateBuilderCanvas + LayoutEngine + Placeholder Summary

**One-liner:** Editable template canvas with 3-section tabs, pluggable layout engines (vertical-stack default with ReorderableListView; freeform composes obj 006's EdenDiagram), DragTarget drop zone with candidate-highlight ring, footer-page indicator, and strict <1200pt narrow fallback.

## What was built

- `EdenTemplateLayoutEngine` (abstract) + `EdenTemplateVerticalStackLayout` (const, default) + `EdenTemplateFreeformLayout` (const) — two const-equal layout strategies.
- `EdenTemplateBlockPlaceholder` (StatelessWidget) — bordered Row with icon + label (with content.label → content.text → descriptor.displayName fallback chain) + italic subtext + optional delete IconButton + optional drag-indicator. Material 3 surface tokens (no hard-coded colors).
- `EdenTemplateBuilderCanvas` (StatefulWidget) — owns `_activeSection`; LayoutBuilder routes to either narrow fallback or full canvas; full canvas = section tab bar + DragTarget-wrapped centered document page (max 720pt) + per-layout-engine content (ReorderableListView or EdenDiagram).
- Footer indicator strip shows 'Page Footer' + 'Page N of M' when activeSection == footer.
- Drop-from-palette: DragTarget builder shows 2pt primary border when `candidate.isNotEmpty`.
- Reorder API hides Flutter's `oldIndex < newIndex ? newIndex - 1 : newIndex` quirk — consumer receives clean indices.

## Tasks completed

| Task | Name | Commit | Files |
|---|---|---|---|
| 1 | Layout engine + placeholder | `01af58e` (combined) | template_layout_engine.dart, eden_template_block_placeholder.dart, fixtures, placeholder test |
| 2 | Canvas | (same commit) | eden_template_builder_canvas.dart, canvas test |
| 3 | Wire exports | (same commit) | eden_template_builder_exports.dart |

## Task Evidence

| Task | Verify Command | Exit Code | Status |
|---|---|---|---|
| 1: placeholder | `flutter test test/widgets/eden_template_builder/eden_template_block_placeholder_test.dart` | 0 | PASS (10 tests incl 3 layout-engine) |
| 2: canvas | `flutter test test/widgets/eden_template_builder/eden_template_builder_canvas_test.dart` | 0 | PASS (14 tests) |
| full template_builder | `flutter test test/widgets/eden_template_builder/` | 0 | PASS (108 tests) |
| analyze | `flutter analyze lib/src/widgets/eden_template_builder/` | 0 | PASS — no issues |
| no off-limits diff | `git diff --stat HEAD lib/src/widgets/eden_diagram/ lib/src/widgets/eden_process_canvas/ lib/src/widgets/eden_workflow_canvas/` | 0 | PASS — empty diff |

## TDD Evidence

| Phase | Command | Exit Code | Expected |
|---|---|---|---|
| Task 1 RED | placeholder test before impl | 1 | FAIL (correct — class absent) |
| Task 1 GREEN | placeholder test after impl | 0 | PASS (10) |
| Task 2 RED | canvas test before impl | 1 | FAIL (correct — class absent) |
| Task 2 GREEN | canvas test after impl | 0 | PASS (14) |

## Deviations from Plan

**1. [Rule 3 - blocking] Fixture file missing flutter_test import**
- **Found during:** Task 2 GREEN run
- **Issue:** `pumpCanvas` helper used `WidgetTester` and `addTearDown` but the fixture file only imported `package:eden_ui_flutter/eden_ui.dart` + `flutter/material.dart`.
- **Fix:** Added `import 'package:flutter_test/flutter_test.dart';`.
- **Files modified:** test/widgets/eden_template_builder/_fixtures/eden_template_canvas_fixtures.dart
- **Commit:** `01af58e`

## Self-Check: PASSED

- 6 created + 1 modified file all exist: VERIFIED
- 108 template_builder tests pass: VERIFIED
- analyze clean: VERIFIED
- No obj 006 / eden_workflow_canvas / eden_process_canvas modifications: VERIFIED (empty git diff)

## Post-TRD Verification

- Auto-fix cycles used: 1 (fixture import)
- Must-haves verified: 12/12
- Gate failures: none new

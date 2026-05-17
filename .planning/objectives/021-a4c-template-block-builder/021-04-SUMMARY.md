---
objective: 021-a4c-template-block-builder
trd: "021-04"
subsystem: template-builder
tags: [wave-3, editor-panels, controlled-pattern, variables, styles, layout]
requires:
  - EdenTemplateVariablesRegistry
  - EdenTemplateStyleSettings (with copyWith)
  - EdenTemplateLayoutSettings (with copyWith)
provides:
  - EdenTemplateVariablesPanel
  - EdenTemplateStylesPanel
  - EdenTemplateLayoutPanel
affects:
  - lib/src/widgets/eden_template_builder/eden_template_builder_exports.dart
  - test/widgets/eden_template_builder/eden_template_models_test.dart (added copyWith tests)
tech-stack:
  added: []
  patterns:
    - controlled-component-pattern (value + onChange)
    - blur-commit-numeric-field (onSubmitted + onTapOutside)
    - segmented-button-enum-typed
    - registry-driven-search-filter
key-files:
  created:
    - lib/src/widgets/eden_template_builder/eden_template_variables_panel.dart
    - lib/src/widgets/eden_template_builder/eden_template_styles_panel.dart
    - lib/src/widgets/eden_template_builder/eden_template_layout_panel.dart
    - test/widgets/eden_template_builder/_fixtures/eden_template_panels_fixtures.dart
    - test/widgets/eden_template_builder/eden_template_variables_panel_test.dart
    - test/widgets/eden_template_builder/eden_template_styles_panel_test.dart
    - test/widgets/eden_template_builder/eden_template_layout_panel_test.dart
  modified:
    - lib/src/widgets/eden_template_builder/eden_template_builder_exports.dart
    - test/widgets/eden_template_builder/eden_template_models_test.dart
decisions:
  - "All 3 panels follow CONTROLLED pattern — consumer owns state; panel takes `value` + `onChange` callback. Internal state is transient only (text-field controllers, search query)."
  - "copyWith methods were proactively added in TRD 021-01 (matches must-haves: 'copyWith' wasn't an explicit TRD-01 must-have but enabling Wave 3 panel ergonomics drove early addition); TRD 021-04 only added the 2 verification tests, not the methods themselves."
  - "Numeric font-size and margin fields commit on `onSubmitted` OR `onTapOutside` — not on every keystroke (prevents callback spam during typing)."
  - "Invalid numeric input REVERTS to previous value (no callback fired) rather than crashing or showing inline error — matches donor's lightweight UX."
  - "DropdownButtonFormField uses isExpanded:true + ellipsis on items so font names fit at 240pt."
  - "Variables panel search is case-insensitive substring on FIELD names only (not group names) — narrower filter is more predictable."
metrics:
  duration_minutes: 13
  completed: 2026-05-17
  tests_added: 29
  files_created: 7
  files_modified: 2
---

# Objective 021 TRD 021-04: Editor Panels Summary

**One-liner:** 3 right-rail editor panels (Variables/Styles/Layout) with controlled-pattern callbacks, blur-commit numeric fields, segmented buttons for enum-typed page-size/orientation, registry-driven variables search; all safe at 240pt (donor right-rail) and 390pt (iPhone).

## What was built

- **EdenTemplateVariablesPanel** — StatefulWidget for search; reads `EdenTemplateVariablesRegistry`; renders search field + grouped scrolling list of `{{group.field}}` tokens. Empty registry shows informative placeholder. Empty search match shows 'No matching fields'. Tap fires `onInsertField(token)` with full `{{group.field}}` string.
- **EdenTemplateStylesPanel** — controlled (value + onChangeStyle); 6 brand-color circle swatches (Wrap, configurable list), font-family DropdownButtonFormField (configurable list), header/body font-size editable TextFields with `FilteringTextInputFormatter` numeric input + clamp-on-blur via min/max params.
- **EdenTemplateLayoutPanel** — controlled (value + onChangeLayout); 3-segment page-size button (Letter/A4/Legal), 2-segment orientation button (Portrait/Landscape), 2x2 margins grid with editable TextFields (clamp-on-blur), 2 compact CheckboxRows (differentFirstPageHeader, pageNumbersInFooter).

## Tasks completed

| Task | Name | Commit | Files |
|---|---|---|---|
| 1 | copyWith tests for settings | (combined) | template_models_test.dart |
| 2-4 | Variables / Styles / Layout panels | `1eaa102` | 3 panel files + 3 tests + fixtures |
| 5 | Wire exports | (same) | eden_template_builder_exports.dart |

## Task Evidence

| Task | Verify Command | Exit Code | Status |
|---|---|---|---|
| copyWith | `flutter test test/widgets/eden_template_builder/eden_template_models_test.dart` | 0 | PASS (36 tests) |
| variables panel | `flutter test test/widgets/eden_template_builder/eden_template_variables_panel_test.dart` | 0 | PASS (8 tests) |
| styles panel | `flutter test test/widgets/eden_template_builder/eden_template_styles_panel_test.dart` | 0 | PASS (10 tests) |
| layout panel | `flutter test test/widgets/eden_template_builder/eden_template_layout_panel_test.dart` | 0 | PASS (9 tests) |
| full template_builder | `flutter test test/widgets/eden_template_builder/` | 0 | PASS (137 tests) |
| analyze | `flutter analyze lib/src/widgets/eden_template_builder/` | 0 | PASS — no issues |

## TDD Evidence

| Phase | Command | Exit Code | Expected |
|---|---|---|---|
| RED | panel tests before impl | 1 | FAIL (correct — classes absent) |
| GREEN | panel tests after impl | 0 | PASS (29 net new tests across 3 panels + copyWith) |
| REFACTOR | analyze fixes (const constructors) | 0 | PASS — clean |

## Deviations from Plan

**1. [Rule 3 - blocking] Styles panel DropdownButtonFormField overflows at 240pt**
- **Found during:** Styles panel narrow-width test
- **Issue:** Default DropdownButtonFormField is unbounded; 'Plus Jakarta Sans' label exceeds 240pt by 115px.
- **Fix:** Added `isExpanded: true` to DropdownButtonFormField + `overflow: TextOverflow.ellipsis` on each DropdownMenuItem's Text.
- **Files modified:** eden_template_styles_panel.dart
- **Commit:** `1eaa102`

**2. [Rule 2 - critical] copyWith pre-shipped in TRD 021-01**
- **Found during:** TRD 021-04 planning review (Task 1 description)
- **Issue:** TRD-04 plan called for adding copyWith to template_models.dart as part of TRD-04. Both methods were already added in TRD-01 to support Wave 3 ergonomics proactively.
- **Fix:** Added 2 verification tests in template_models_test.dart instead of modifying template_models.dart. No behavior change; documented in this summary.

## Self-Check: PASSED

- 7 created + 2 modified file all exist: VERIFIED
- 137 template_builder tests pass: VERIFIED
- analyze clean: VERIFIED
- No obj 006 / eden_workflow_canvas / eden_process_canvas modifications: VERIFIED

## Post-TRD Verification

- Auto-fix cycles used: 2 (dropdown overflow + 6 const-constructor lints)
- Must-haves verified: 11/11
- Gate failures: none new

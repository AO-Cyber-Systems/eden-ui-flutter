---
objective: 021-a4c-template-block-builder
trd: "021-02"
subsystem: template-builder
tags: [wave-2, palette, draggable, registry-driven]
requires:
  - EdenTemplateBlockRegistry
  - EdenTemplateBlockDescriptor
provides:
  - EdenTemplateBlockPalette
affects:
  - lib/src/widgets/eden_template_builder/eden_template_builder_exports.dart
tech-stack:
  added: []
  patterns:
    - registry-driven-stateless-widget
    - flutter-draggable-source
    - mouseregion-hover-state
key-files:
  created:
    - lib/src/widgets/eden_template_builder/eden_template_block_palette.dart
    - test/widgets/eden_template_builder/_fixtures/eden_template_palette_fixtures.dart
    - test/widgets/eden_template_builder/eden_template_block_palette_test.dart
  modified:
    - lib/src/widgets/eden_template_builder/eden_template_builder_exports.dart
decisions:
  - "Palette is StatelessWidget; reactive registry updates are consumer's responsibility (setState in parent after register())."
  - "ALL cards wrapped in Draggable in _BlockGrid (not the default card) so consumer cardBuilder still gets drag-source semantics."
  - "MouseRegion hover lives inside _DefaultBlockCard (private StatefulWidget); palette itself stays stateless."
  - "Empty registry renders a helpful placeholder (not crash) with the exact reset incantation."
metrics:
  duration_minutes: 8
  completed: 2026-05-17
  tests_added: 13
  files_created: 3
  files_modified: 1
---

# Objective 021 TRD 021-02: EdenTemplateBlockPalette Summary

**One-liner:** Registry-driven left-rail palette with categorized 2-column GridView of Draggable cards, hover state via MouseRegion, click-to-add fallback, consumer-overridable cardBuilder and emptyPlaceholder.

## What was built

- `EdenTemplateBlockPalette` StatelessWidget — reads from `EdenTemplateBlockRegistry`; renders ListView of per-category sections (section header + 2-column GridView). Defaults to alphabetical category order; `categories` param overrides.
- `_DefaultBlockCard` (private StatefulWidget) — hover state via MouseRegion; tap fires `onAddBlock`; visual style: icon (20pt) + displayName (11pt bold) + description (9pt ellipsis) in bordered Container.
- `_BlockGrid` (private) — shrinkWrap + NeverScrollableScrollPhysics GridView; wraps EVERY card (default or consumer) in `Draggable<EdenTemplateBlockDescriptor>` so drag-source works regardless of cardBuilder.
- `_DefaultEmptyPlaceholder` (private) — informative empty-state with the exact `resetToDefaults()` incantation.

## Tasks completed

| Task | Name | Commit | Files |
|---|---|---|---|
| 1 | Palette widget + tests | `bebaf7a` | eden_template_block_palette.dart, fixtures, test |
| 2 | Wire exports | (same commit) | eden_template_builder_exports.dart |

## Task Evidence

| Task | Verify Command | Exit Code | Status |
|---|---|---|---|
| 1: palette | `flutter test test/widgets/eden_template_builder/eden_template_block_palette_test.dart` | 0 | PASS (13 tests) |
| analyze | `flutter analyze lib/src/widgets/eden_template_builder/eden_template_block_palette.dart` | 0 | PASS — no issues |

## TDD Evidence

| Phase | Command | Exit Code | Expected |
|---|---|---|---|
| RED | `flutter test test/widgets/eden_template_builder/eden_template_block_palette_test.dart` | 1 | FAIL (correct — class absent) |
| GREEN | (same) | 0 | PASS (13 tests) |

## Deviations from Plan

**1. [Rule 3 - blocking] Test surface too small for full palette rendering**
- **Found during:** Task 1 GREEN run
- **Issue:** Flutter test default surface is 800×600; full palette + 12 cards in a ListView extends beyond viewport, so ADVANCED header / Image card / Conditional card render off-screen and finders fail.
- **Fix:** Added `pumpTall(tester, child)` helper that sets `tester.binding.setSurfaceSize(Size(1200, 2400))` with auto-teardown; replaced `wrap(...)` calls with `pumpTall(...)`.
- **Files modified:** test file only
- **Commit:** `bebaf7a`

## Self-Check: PASSED

- 3 created + 1 modified file all exist: VERIFIED
- 13 palette tests pass: VERIFIED
- analyze clean: VERIFIED
- No obj 006 / TRD-01 modifications: VERIFIED

## Post-TRD Verification

- Auto-fix cycles used: 1 (test surface size)
- Must-haves verified: 11/11
- Gate failures: none new

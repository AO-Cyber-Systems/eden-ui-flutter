---
objective: 021-a4c-template-block-builder
trd: "021-01"
subsystem: template-builder
tags: [foundation, value-classes, registry, resolver, wave-1]
requires:
  - dart-flutter
provides:
  - EdenTemplateGraph
  - EdenTemplateBlock
  - EdenTemplateSection
  - EdenTemplatePageSize
  - EdenTemplateOrientation
  - EdenTemplateLayoutSettings
  - EdenTemplateStyleSettings
  - EdenTemplateBlockDescriptor
  - EdenTemplateVariableGroup
  - EdenTemplateMissingVariableException
  - EdenTemplateBlockRegistry
  - EdenTemplateVariablesRegistry
  - EdenTemplateVariablesResolver
affects:
  - lib/eden_ui.dart (appended Wave 1 export section)
tech-stack:
  added: []
  patterns:
    - registry-singleton-with-reset (mirrors obj 006 R-1/R-2 pattern)
    - pure-function-resolver
    - value-class-with-toJson-fromJson
key-files:
  created:
    - lib/src/widgets/eden_template_builder/template_models.dart
    - lib/src/widgets/eden_template_builder/template_block_registry.dart
    - lib/src/widgets/eden_template_builder/template_variables_registry.dart
    - lib/src/widgets/eden_template_builder/template_variables_resolver.dart
    - lib/src/widgets/eden_template_builder/eden_template_builder_exports.dart
    - test/widgets/eden_template_builder/_fixtures/eden_template_models_fixtures.dart
    - test/widgets/eden_template_builder/eden_template_models_test.dart
    - test/widgets/eden_template_builder/eden_template_block_registry_test.dart
    - test/widgets/eden_template_builder/eden_template_variables_registry_test.dart
    - test/widgets/eden_template_builder/eden_template_variables_resolver_test.dart
  modified:
    - lib/eden_ui.dart
decisions:
  - "Block type field is String (registry-driven), not Dart enum — donor's `BlockType` enum replaced for extensibility."
  - "Variables registry register() APPENDS to existing group fields (does NOT replace) — additive vertical registration semantics."
  - "Default brand color 0xFFD4A853 (donor gold) — matches existing tokens/colors.dart MaterialColor.gold."
  - "Block registry ships 12 defaults (10 Content + 2 Advanced); donor's 14-enum approvalStamp + calculation deferred to consumers."
  - "EdenTemplateBlockPaletteItem collapsed INTO EdenTemplateBlockDescriptor (no separate palette-item class) — descriptor has icon + displayName + description + category sufficient for palette grid."
  - "Color serialization uses toARGB32() (not deprecated .value) to match newer codebase pattern in eden_signature_pad."
metrics:
  duration_minutes: 12
  completed: 2026-05-17
  tests_added: 71
  files_created: 10
  files_modified: 1
---

# Objective 021 TRD 021-01: Foundation Summary

**One-liner:** Established the template-builder value vocabulary (3 enums, 7 value classes, 1 exception), two locked singleton registries (block + variables) with reset semantics, and pure-function variables resolver with dotted-path walk + throw-on-missing — choke point for Waves 2-4.

## What was built

- **3 enums:** `EdenTemplateSection` (header/body/footer), `EdenTemplatePageSize` (letter/a4/legal with `widthInches/heightInches/widthMm/heightMm` extension getters), `EdenTemplateOrientation` (portrait/landscape).
- **7 value classes** (all const + immutable, all with `==`/`hashCode` based on id where applicable, all with toJson/fromJson where relevant):
  - `EdenTemplateBlock` (id, type as String, content as Map, order, section)
  - `EdenTemplateGraph` (id, name, category, version, status, blocks, optional createdAt/updatedAt; `isPublished` getter)
  - `EdenTemplateLayoutSettings` (pageSize, orientation, 4 margins, differentFirstPageHeader, pageNumbersInFooter; copyWith)
  - `EdenTemplateStyleSettings` (brandColor, fontFamily, headerFontSize, bodyFontSize; copyWith; Color via toARGB32)
  - `EdenTemplateBlockDescriptor` (id, displayName, description, icon, category, isAdvanced, optional placeholderBuilder callback)
  - `EdenTemplateVariableGroup` (groupName, fields list)
- **1 exception:** `EdenTemplateMissingVariableException(path)` with informative `toString()`.
- **2 registries** (mirroring obj 006's pattern):
  - `EdenTemplateBlockRegistry` ships 12 defaults (10 Content + 2 Advanced); singleton with `register`/`lookup`/`all` (sorted by category, displayName)/`byCategory`/`reset`/`resetToDefaults`.
  - `EdenTemplateVariablesRegistry` ships EMPTY; `register(group, fields)` APPENDS to existing group; provides `lookup`/`all`/`groups` (sorted)/`reset`.
- **Pure-function resolver:** `EdenTemplateVariablesResolver.resolve(text, data, {throwOnMissing, missingPlaceholder})` — regex `\{\{\s*([a-zA-Z_][a-zA-Z0-9_.]*)\s*\}\}` with strict identifier character class; dotted-path walk treats null/non-Map intermediates as missing.

## Tasks completed

| Task | Name | Commit | Files |
|---|---|---|---|
| 1 | Value classes + enums + exception | `308d249` | template_models.dart, fixtures, models_test |
| 2 | Block + variables registries | `962deab` | template_block_registry.dart, template_variables_registry.dart + tests |
| 3 | Variables resolver pure function | `970ba6f` | template_variables_resolver.dart + test |
| 4 | Public exports + wire into eden_ui.dart | (combined into task 1) | eden_template_builder_exports.dart, eden_ui.dart |
| docs | Deferred items + close | `621e7a9` | deferred-items.md |

## Task Evidence

| Task | Verify Command | Exit Code | Status |
|---|---|---|---|
| 1: value classes | `flutter test test/widgets/eden_template_builder/eden_template_models_test.dart` | 0 | PASS (34 tests) |
| 2: registries | `flutter test test/widgets/eden_template_builder/eden_template_{block,variables}_registry_test.dart` | 0 | PASS (22 tests) |
| 3: resolver | `flutter test test/widgets/eden_template_builder/eden_template_variables_resolver_test.dart` | 0 | PASS (15 tests) |
| Full suite regression | `flutter test` | 1 | 3772 pass, 8 pre-existing FAIL (deferred) |
| Analyze | `flutter analyze lib/src/widgets/eden_template_builder/` | 0 | PASS — no issues |

## TDD Evidence

| Phase | Command | Exit Code | Expected |
|---|---|---|---|
| Task 1 RED | `flutter test test/widgets/eden_template_builder/eden_template_models_test.dart` | 1 | FAIL (correct — compile errors, classes absent) |
| Task 1 GREEN | `flutter test test/widgets/eden_template_builder/eden_template_models_test.dart` | 0 | PASS (correct — 34 tests) |
| Task 1 REFACTOR | `flutter test ...` + `flutter analyze` | 0 | PASS (migrated Color.value → toARGB32) |
| Task 2 RED | `flutter test test/widgets/eden_template_builder/eden_template_{block,variables}_registry_test.dart` | 1 | FAIL (correct) |
| Task 2 GREEN | (same) | 0 | PASS (22 tests) |
| Task 3 RED | `flutter test test/widgets/eden_template_builder/eden_template_variables_resolver_test.dart` | 1 | FAIL (correct) |
| Task 3 GREEN | (same) | 0 | PASS (15 tests) |

## Deviations from Plan

**1. [Rule 2 - critical] Color.value → toARGB32 migration**
- **Found during:** Task 1 (post-GREEN refactor)
- **Issue:** `flutter analyze` flagged `info • 'value' is deprecated and shouldn't be used. Use component accessors like .r or .g, or toARGB32 for an explicit conversion`.
- **Fix:** Migrated `brandColor.value` → `brandColor.toARGB32()` in toJson and updated tests to match. Pattern is consistent with existing eden_signature_pad.dart codebase usage.
- **Files modified:** lib/src/widgets/eden_template_builder/template_models.dart + tests
- **Commit:** Part of `308d249`

## Self-Check: PASSED

- All 10 files created exist on disk: VERIFIED
- All commits exist in git log: `308d249`, `962deab`, `970ba6f`, `621e7a9` — VERIFIED
- `flutter analyze lib/src/widgets/eden_template_builder/` clean: VERIFIED
- Pre-existing failures documented in deferred-items.md: VERIFIED
- No modifications to lib/src/widgets/eden_diagram/ or eden_process_canvas/ or eden_workflow_canvas/: VERIFIED (git diff shows no changes)

## Post-TRD Verification

- Auto-fix cycles used: 1 (deprecation migration)
- Must-haves verified: 17/17
- Gate failures: None new — 8 pre-existing failures deferred (eden_intake_form_builder, eden_client_sms_thread, eden_memorable_date, eden_permission_matrix)

---
objective: 021-a4c-template-block-builder
kind: ui-lib
work: feature
status: planned
estimated_effort: 2 weeks Claude execution
trd_count: 5
waves: 4
---

# Objective 021 — A4-c Template Block Builder

## Goal

Ship a generic, vertical-agnostic, transport-agnostic **template block builder** primitive in `eden-ui-flutter` that downstream Eden Biz vertical apps compose for any block-structured authoring surface — email templates, document templates (PDF / printable), form templates, receipt templates, AVS / chart-note templates, official-correspondence templates. After this objective ships, every Eden Biz vertical (trades, salon, medical, fuel, retail, gov) composes a template builder with the same block palette + drag-to-canvas + variables-panel + styles/layout-editing affordance — without re-implementing any of it. This is the **third visual-builder consumer** of `eden_diagram`, after obj 006 (Visual Process Canvas) and obj 020 (Workflow Designer).

**Generic / transport-agnostic positioning (locked):**
- The template builder does NOT bind to a specific output format. It emits a typed block tree (`EdenTemplateGraph`); the consumer renders that tree to HTML / email / PDF / Markdown / Word / whatever transport.
- Template **block types are pluggable via registry** (`EdenTemplateBlockRegistry`). The library ships a sensible default set (~12 block types: text, heading, image, divider, spacer, button, table, list, signature, qr_code, conditional, repeater); consumers register vertical-specific blocks (e.g., `PaymentLine` for retail receipts, `VitalsBlock` for medical AVS, `LineItemTable` for invoices, `RouteSummary` for fuel-delivery PDFs).
- **Variables** (merge fields) are also pluggable via registry (`EdenTemplateVariablesRegistry`). The library ships an empty registry; consumers populate `customer.*`, `company.*`, `appointment.*`, etc. The variables resolver substitutes `{{customer.name}}` tokens in a preview given a sample-data Map.

**Composes `eden_diagram` (obj 006) for the canvas surface:**
- Reuses the drag-from-toolbox / drop-target hit-test / multi-handle-ports / context-menus / editor-dialogs infrastructure already shipped by obj 006.
- Two layout modes (template-specific): **vertical-stack** (default — emails, documents, receipts; blocks flow top-to-bottom) and **freeform** (forms — blocks placed at x,y for arbitrary form layouts). Both layout engines are template-builder-specific (`EdenTemplateVerticalStackLayout`, `EdenTemplateFreeformLayout`) — they implement the same `EdenProcessLayoutEngine`-like contract from obj 006 but tuned for block-document semantics (full-width children, no edges by default for vertical-stack; arbitrary x,y for freeform).
- The template builder does NOT use edges (connections) in vertical-stack mode (blocks have implicit sibling ordering by `sortOrder`). Freeform mode permits user-drawn connectors (donor `EdenDiagram` user-edges) when the consumer needs them (e.g., form-field dependency arrows).

**Parity definition (acceptance):** every donor feature in the **Donor-parity checklist** below is implemented as a generic library widget under `lib/src/widgets/eden_template_builder/`, has at least one widget or unit test (hand-built fixtures), and is visible in the dev catalog under a new `template_builder_screen.dart`. Side-by-side review of a populated `EdenVisualTemplateBuilder` demo vs the donor (trades-flutter `lib/features/templates/presentation/widgets/builder_canvas.dart` + companion panels) shows the same feature set is present (same block-palette categorization, same right-rail panel layout, same variables-panel UX, same layout/styles editors).

## Why now

- **Locked decisions (deep-audit 2026-05-15 §6 + §7):** template block builder is the third visual-builder consumer of `eden_diagram` — engine extensions and the canvas pattern landed in obj 006, sub-system A4-b (Workflow Designer, obj 020) reused them, and A4-c (this objective) reuses them again. Engine cost is ≈0 (obj 006 already paid it).
- **Generic positioning (locked):** template builder stays GENERIC + vertical-agnostic per deep-audit §7.1's process-builder analogue. Block types and variables are registry-driven (mirrors obj 006's R-1 / R-2 entity-type and runtime-component registries). The same registry pattern hits the same correctness budget.
- **Donor stability:** trades-flutter `lib/features/templates/` (12 dart files: `template_model.dart` + `builder_canvas.dart` + 6 panel widgets + sidebar + toolbar + page + repository + providers) is mature, builds clean, follows the right-rail-with-4-icon-tabs UX pattern that maps cleanly to a library primitive.
- **Cross-vertical demand stacking:**
  - **Salon** — appointment-confirmation email templates, marketing-email templates (donor-style block flow: header → body text → CTA button → footer).
  - **Medical** — AVS (after-visit-summary) templates composing `EdenAVSGenerator` from obj 017 as a block; chart-note templates; intake-form layouts using freeform mode.
  - **Trades** — quote-PDF templates, invoice-PDF templates, work-order forms (this is the donor's home vertical).
  - **Retail** — receipt templates (composes `EdenLineItemEditor.readOnly` from obj 012 as a block), promotional-email templates.
  - **Fuel** — delivery-confirmation templates, route-summary PDFs (composes `EdenRouteStopList` from obj 005 as a block).
  - **Gov** — FOIA-response templates (composes obj 011 USWDS-compliant primitives), official-correspondence templates.
- **Engine reuse:** obj 006 already shipped drag-from-toolbox, multi-handle ports (unused here), drop-target hit-test, context-menus, editor-dialog patterns. Re-using them costs ~30% of an equivalent green-field build. Library widget LOC target: <1500 LOC total across 5 TRDs.
- **Cadence proven:** objectives 001-005 GREEN; objective 006 (visual process canvas, 15 TRDs / 4 weeks) shipped per the same generic-registry-driven pattern this objective copies. TDD discipline + test-list-first + hand-built fixtures + outside-in proven across ~445+ widget tests.

## Donor-parity checklist (derived from `trades-flutter/lib/features/templates/`)

The donor exposes the following UX-observable features. Each row is a parity target — every TRD lists which rows it satisfies.

### B. Block types (12 default, registry-driven)

| ID | Donor surface | Library target | TRD |
|---|---|---|---|
| B-1 | `BlockType.text` — static text content (donor `text` / 'Text Block') | `EdenTemplateTextBlock` (default registry entry) | 021-01 |
| B-2 | `BlockType.field` — merge-field placeholder ({{variable}} token rendering) | `EdenTemplateFieldBlock` (default registry entry; renders variable token) | 021-01 |
| B-3 | `BlockType.table` — data table layout | `EdenTemplateTableBlock` (default registry entry) | 021-01 |
| B-4 | `BlockType.list` — bulleted/numbered list | `EdenTemplateListBlock` (default registry entry) | 021-01 |
| B-5 | `BlockType.photoGrid` — image gallery grid | `EdenTemplatePhotoGridBlock` (default registry entry) | 021-01 |
| B-6 | `BlockType.signature` — signature capture area | `EdenTemplateSignatureBlock` (default registry entry) | 021-01 |
| B-7 | `BlockType.divider` — horizontal separator | `EdenTemplateDividerBlock` (default registry entry) | 021-01 |
| B-8 | `BlockType.spacer` — vertical whitespace | `EdenTemplateSpacerBlock` (default registry entry) | 021-01 |
| B-9 | `BlockType.image` — uploaded image | `EdenTemplateImageBlock` (default registry entry) | 021-01 |
| B-10 | `BlockType.qrCode` — QR code | `EdenTemplateQrCodeBlock` (default registry entry) | 021-01 |
| B-11 | `BlockType.conditional` — show/hide by rule (advanced) | `EdenTemplateConditionalBlock` (default registry entry) | 021-01 |
| B-12 | `BlockType.repeater` — repeating row group (advanced) | `EdenTemplateRepeaterBlock` (default registry entry) | 021-01 |

### P. Block palette (left rail / drag source)

| ID | Donor surface | Library target | TRD |
|---|---|---|---|
| P-1 | `BlockPalettePanel` — 2-column grid of block cards, scrollable list with section headers ('CONTENT BLOCKS' / 'ADVANCED') | `EdenTemplateBlockPalette` (registry-driven; consumer overrides categories) | 021-02 |
| P-2 | Hover state — border + light-bg highlight on card hover | `EdenTemplateBlockPalette` card hover state | 021-02 |
| P-3 | Drag source — block card is a Flutter `Draggable<EdenTemplateBlockPaletteItem>` (donor uses snackbar today; library upgrades to real drag) | `EdenTemplateBlockPalette` Draggable behavior | 021-02 |
| P-4 | Click-to-add fallback — taps still work for touch / no-drag contexts | `EdenTemplateBlockPalette.onAddBlock(blockType)` callback | 021-02 |
| P-5 | Categorization — donor splits Content (10) vs Advanced (4); library registers categories via block-registry `category` field | `EdenTemplateBlockRegistry.byCategory(String)` API | 021-01 |

### C. Builder canvas (the editable surface)

| ID | Donor surface | Library target | TRD |
|---|---|---|---|
| C-1 | Builder canvas with toolbar + white document page + right rail (240pt) | `EdenTemplateBuilderCanvas` shell layout | 021-03 |
| C-2 | Vertical-stack layout — blocks flow top→bottom as full-width children (default for emails/docs/receipts) | `EdenTemplateVerticalStackLayout` (compose into `EdenDiagram` if useful, or render a Column directly — TRD decides) | 021-03 |
| C-3 | Freeform layout — blocks at arbitrary (x, y); used for form layouts | `EdenTemplateFreeformLayout` (composes `EdenDiagram` w/o auto-layout) | 021-03 |
| C-4 | Section tabs (Header / Body / Footer) — filters which blocks visible | `EdenTemplateBuilderCanvas.activeSection` (3-state segmented control) | 021-03 |
| C-5 | Empty-section state — "No blocks in {section} — Add blocks from the palette" message | `EdenTemplateBuilderCanvas` empty placeholder | 021-03 |
| C-6 | Footer section indicator — shaded strip showing 'Page Footer' + 'Page {page} of {total}' token | `EdenTemplateBuilderCanvas` footer chrome (when section == footer) | 021-03 |
| C-7 | Block placeholder rendering — icon + label + 'click to edit, drag to reorder' subtext + drag handle | `EdenTemplateBlockPlaceholder` (compact block representation; consumer-overridable via registry `placeholderBuilder`) | 021-03 |
| C-8 | Drag-to-reorder — reorder blocks within section (Flutter `ReorderableListView` for vertical-stack; arbitrary drag for freeform) | `EdenTemplateBuilderCanvas` reorder callbacks (`onReorderBlock(sectionId, oldIndex, newIndex)`) | 021-03 |
| C-9 | iPhone-narrow fallback — at <600pt, donor hides the right rail | `EdenTemplateBuilderCanvas` LayoutBuilder; rail hidden at <1200pt per OBJECTIVE responsive baseline (template builder is desktop primarily) | 021-03 |

### V. Variables panel (merge fields)

| ID | Donor surface | Library target | TRD |
|---|---|---|---|
| V-1 | `VariablesPanel` — search field + grouped scrolling list of fields | `EdenTemplateVariablesPanel` (registry-driven) | 021-04 |
| V-2 | Field groups — donor hard-codes 5 groups (Company / Customer / Project / Invoice / Line Items); library reads from registry | `EdenTemplateVariablesRegistry` (group → fields map) | 021-01 |
| V-3 | Search — filters fields by substring across all groups | `EdenTemplateVariablesPanel` search behavior | 021-04 |
| V-4 | Field rendering — monospace `{{group.field}}` token; hover highlight; tap-to-insert (callback) | `EdenTemplateVariablesPanel` field item w/ `onInsertField(token)` callback | 021-04 |
| V-5 | Empty state — "No matching fields" when search yields nothing | `EdenTemplateVariablesPanel` empty placeholder | 021-04 |
| V-6 | **Variables resolver** — substitute `{{customer.name}}` tokens in a template against a `Map<String, dynamic>` sample data; used for preview rendering | `EdenTemplateVariablesResolver.resolve(String text, Map<String, dynamic> data)` (pure function on the registry — TRD-01 surface) | 021-01 |

### S. Styles panel (typography / color / spacing)

| ID | Donor surface | Library target | TRD |
|---|---|---|---|
| S-1 | `StylesPanel` — brand color swatches (6 default colors), font-family dropdown, header/body font-size inputs | `EdenTemplateStylesPanel` | 021-04 |
| S-2 | Brand color swatches — circular swatches; selected one has white border + glow shadow | `EdenTemplateStylesPanel.brandColorSwatches` (config-driven; default 6) | 021-04 |
| S-3 | Font-family dropdown — donor offers 4 (Plus Jakarta Sans / Inter / Outfit / System Default); library config-driven default + consumer override | `EdenTemplateStylesPanel.fontFamilies` (config-driven; default 4) | 021-04 |
| S-4 | Font-size inputs — header + body (donor is read-only placeholders; library makes them editable) | `EdenTemplateStylesPanel` editable size fields with min/max validation | 021-04 |
| S-5 | `EdenTemplateStyleSettings` value type — brandColor, fontFamily, headerFontSize, bodyFontSize | `EdenTemplateStyleSettings` value class (TRD-01 surface) | 021-01 |

### L. Layout panel (page size / orientation / margins / page breaks)

| ID | Donor surface | Library target | TRD |
|---|---|---|---|
| L-1 | `LayoutPanel` — page size SegmentedButton (Letter / A4 / Legal) + orientation (Portrait / Landscape) + 2×2 margins grid + page-breaks checkboxes | `EdenTemplateLayoutPanel` | 021-04 |
| L-2 | Page-size enum — Letter (8.5"×11"), A4 (210mm×297mm), Legal (8.5"×14") | `EdenTemplatePageSize` enum + extension exposing dimensions | 021-01 |
| L-3 | Orientation enum — Portrait, Landscape | `EdenTemplateOrientation` enum | 021-01 |
| L-4 | Margins — 4 inputs (top, right, bottom, left) — donor read-only placeholders; library editable | `EdenTemplateLayoutSettings` value class with editable margins | 021-01 |
| L-5 | Page breaks — 2 checkboxes (Different first page header, Page numbers in footer) | `EdenTemplateLayoutSettings.differentFirstPageHeader` + `pageNumbersInFooter` | 021-01 |
| L-6 | `EdenTemplateLayoutSettings` value type — pageSize, orientation, marginTop/Right/Bottom/Left, page-break flags | `EdenTemplateLayoutSettings` value class (TRD-01 surface) | 021-01 |

### G. Graph (data + serialization)

| ID | Donor surface | Library target | TRD |
|---|---|---|---|
| G-1 | `Template` value class — id, name, category, version, status, blocks list, timestamps | `EdenTemplateGraph` value class (renamed; "graph" matches the eden_diagram-consumer pattern) | 021-01 |
| G-2 | `TemplateBlock` value class — id, type (String), content (Map), order, section | `EdenTemplateBlock` value class | 021-01 |
| G-3 | JSON round-trip — donor `Template.fromJson` / `toJson` + `TemplateBlock.fromJson` / `toJson` | `EdenTemplateGraph.toJson()` / `fromJson()`; same for `EdenTemplateBlock` | 021-01 |
| G-4 | Section enum — header / body / footer | `EdenTemplateSection` enum | 021-01 |
| G-5 | Block content as `Map<String, dynamic>` slot — donor stores arbitrary block content (text, label, image URL, etc.) | `EdenTemplateBlock.content: Map<String, dynamic>` (vertical-agnostic slot) | 021-01 |

### R. Registry (block types + variables)

| ID | Locked decision | Library target | TRD |
|---|---|---|---|
| R-1 | Block types are registry-driven (NOT enum-locked). Verticals register their block types. | `EdenTemplateBlockRegistry` singleton with `register/lookup/all/byCategory/reset` + `resetToDefaults` (re-registers the 12 built-ins) | 021-01 |
| R-2 | Variables (merge fields) are registry-driven. Library ships empty; consumers fill it per vertical. | `EdenTemplateVariablesRegistry` singleton with `register(group, fields)/lookup/all/reset` | 021-01 |

### X. Composite root

| ID | Donor surface | Library target | TRD |
|---|---|---|---|
| X-1 | `BuilderCanvas` widget composes toolbar + canvas + right rail with 4 icon tabs (Blocks / Variables / Layout / Styles) — switches panel via tap | `EdenVisualTemplateBuilder` composite root | 021-05 |
| X-2 | Right rail icon tabs — 4 icons (Icons.dashboard / .data_object / .article_outlined / .palette_outlined), active state highlight | `EdenVisualTemplateBuilder` right-rail tab strip | 021-05 |
| X-3 | Dev catalog screen — `template_builder_screen.dart` demonstrates the populated builder | `lib/dev_app/screens/template_builder_screen.dart` + home_screen.dart tile | 021-05 |

## Wave structure (parallelism map)

| Wave | TRDs | Theme | Parallelism |
|---|---|---|---|
| **1** | 021-01 | Foundation — value classes (`EdenTemplateBlock`, `EdenTemplateGraph`, layout/style settings, enums) + block-type registry + variables registry + variables resolver | Single TRD (foundational); blocks everything else |
| **2** | 021-02, 021-03 | Palette + canvas — block palette (drag source) + builder canvas (right-rail-less shell + vertical-stack + freeform + section tabs + block-placeholder rendering) | Parallel; different files; both depend on Wave 1 |
| **3** | 021-04 | Editors — variables panel + styles panel + layout panel (3 panels co-located in one TRD since they're stateless + sibling-shaped) | Single TRD; depends on Wave 1 |
| **4** | 021-05 | Composite root — `EdenVisualTemplateBuilder` composes palette + canvas + right-rail tab strip + dev catalog screen + integration smoke test + home-screen nav tile | Single TRD; depends on Waves 2 + 3; HUMAN-VERIFY checkpoint |

**File-collision discipline:**
- `lib/eden_ui.dart` — every TRD that adds a public surface appends 1-2 export lines under a NEW section header `// Objective 021 — Template builder Wave N`. Mark each TRD `co_modified_files: [lib/eden_ui.dart]` so the orchestrator serializes the edit step within a wave.
- `lib/src/widgets/eden_template_builder/eden_template_builder_exports.dart` — every TRD appends exports. Within a wave, the dependency-graph-implied TRD ordering (e.g., TRD 02 before TRD 03 if 03 imports from 02) drives serialization; usually safe to parallel since they own distinct files but the exports barrel is shared. Resolve via wave-internal serialization on this file.
- `lib/dev_app/screens/home_screen.dart` — TRD 05 ONLY (single owner). Earlier TRDs do NOT modify the dev catalog.
- `lib/dev_app/screens/template_builder_screen.dart` — TRD 05 ONLY (new file).
- NO modifications to existing obj 006 files (`lib/src/widgets/eden_diagram/`, `lib/src/widgets/eden_process_canvas/`). The template builder COMPOSES `EdenDiagram` (when freeform mode needs canvas affordances) but does NOT extend it. If a missing engine capability is discovered mid-objective, raise a follow-up obj 006-extension ticket — DO NOT silently patch eden_diagram.

## Constraints (locked, do not revisit)

1. **Composes `eden_diagram`, does NOT extend it.** The template builder is a third library subsuite under `lib/src/widgets/eden_template_builder/`. Where the freeform layout needs canvas affordances (drag, zoom, pan), the widget instantiates `EdenDiagram` and feeds it a derived `EdenDiagramData` graph. The vertical-stack layout uses plain `Column` + `ReorderableListView`; no `EdenDiagram` involvement.
2. **Generic + vertical-agnostic.** No trades-specific, salon-specific, medical-specific fields anywhere. Block types and variables are registry-driven (mirrors obj 006's R-1 / R-2 lock). Domain shapes (`EdenTemplateGraph`, `EdenTemplateBlock`) use generic `Map<String, dynamic> content` slots; verticals project their domain config into the slot.
3. **Transport-agnostic.** No new pubspec deps. NO PDF rendering library. NO email-templating library. NO HTML-rendering library. The block tree is the output; consumers transform it to their target format. The dev catalog renders block placeholders (icon + label + subtext); it does NOT render to PDF or HTML.
4. **TDD strict (Iron Law) + test-list-first.** Per resolver intent (`tdd: strict`, `test_list_first: required`, `fixture_strategy: generators`) and user playbook (`~/.claude/CLAUDE.md` TDD Playbook): every TRD's testable tasks carry `tdd="true"`. Test-list checklist at the top of every TRD enumerating happy/edge/failure cases BEFORE any test code. **Hand-built fixture builders only** — `no_llm_test_data` constraint active. Fixture files named `test/widgets/eden_template_builder/_fixtures/eden_template_<aspect>_fixtures.dart` with header line `// Do NOT regenerate via LLM — hand-built fixtures for EdenTemplate<Aspect>.`. One test at a time RED → GREEN → REFACTOR per playbook habits 1–4.
5. **Outside-in for UI flows.** Per playbook habit 5: pure-logic helpers (variables resolver, layout engine math) start at unit level. Composite widgets (`EdenVisualTemplateBuilder` in TRD 05) get system-level widget tests asserting "given a `EdenTemplateGraph`, renders N block placeholders in the body section; dragging a Text item from the palette appends a block to the active section; tapping a variable inserts the token". Individual panel widgets get isolated widget tests.
6. **No anti-patterns from constraints:** no `.feature` / Gherkin files; no property-based testing libraries; no LLM-generated test data.
7. **Test pattern locked.** `testWidgets('renders ...', (tester) async {...})` with `wrap()` helper at the top of each test file. Mirror `test/widgets/eden_alert_test.dart`. Widget tests, NOT integration tests.
8. **iPhone-narrow safe (≥390pt) — template builder is desktop/tablet primarily; <1200pt fallback.** The template builder is a 1200pt+ desktop UX (Material 3 Expanded tier). At <1200pt, `EdenVisualTemplateBuilder` MUST render a **read-only fallback** message ("Template builder requires tablet/desktop width — use mobile preview instead") rather than overflow. Individual panel widgets (palette, variables, styles, layout) MUST themselves not overflow at 390pt — they're tested in isolation at narrow widths and render compactly.
9. **Material 3 + tokens.** Use `EdenSpacing`, `EdenRadii`, `EdenColors`, `EdenTypography` from `lib/src/tokens/` where they apply. Donor uses hard-coded colors and pixel values — map to tokens; if no equivalent, hard-code with comment `// donor color — keep until token system has equivalent`.
10. **Visual catalog entry.** TRD 05 creates `lib/dev_app/screens/template_builder_screen.dart` with a populated demo (a 3-section template with ~6 blocks in header, ~10 in body, ~3 in footer; sample variables registered for `company.*`, `customer.*`, `appointment.*`; sample style + layout settings). TRD 05 also adds one nav tile to `home_screen.dart`. Earlier TRDs do NOT modify the dev catalog (per file-collision discipline).
11. **No breaking changes to existing widgets.** Existing 51+ widget exports + ~445+ tests must continue to pass. This objective is purely additive to the public surface (`lib/eden_ui.dart`). NO changes to obj 006 files.
12. **No new pubspec dependencies.** Period. If a TRD believes it needs one, it MUST justify in `<context>` and add it explicitly; default assumption is no new deps.
13. **Registries are SINGLETONS but reset-able for tests.** Both `EdenTemplateBlockRegistry.instance` and `EdenTemplateVariablesRegistry.instance` expose `register()`, `lookup()`, `all()`, `reset()` (clears all), `resetToDefaults()` (re-registers built-in defaults). Tests MUST call `resetToDefaults()` (or `reset()` for variables-registry which ships empty) in `setUp` to avoid bleed across tests.
14. **Decomposition principle — generic, hand-rolled, NOT 1:1 donor translation.** Donor `BuilderCanvas` is 387 LOC of trades-specific React-styled chrome with hard-coded dark canvas color `0xFF0A0A0A`, hard-coded gold `0xFFD4A853` section-tab color, etc. The Dart library equivalent (`EdenTemplateBuilderCanvas` in TRD 03) uses Material 3 surface tokens, exposes color choices via `EdenTemplateStyleSettings`, and targets <400 LOC. If a TRD approaches donor's LOC, it's translating too literally — re-grep the donor for the LOGIC, drop the styling specifics.
15. **Layout engine pluggability.** `EdenTemplateBuilderCanvas` exposes `layout: EdenTemplateLayoutEngine` (sealed-ish): `EdenTemplateVerticalStackLayout()` (default) | `EdenTemplateFreeformLayout()` | custom subclass. Swap is a constructor parameter; vertical-stack is `Column` + `ReorderableListView`; freeform composes `EdenDiagram`.
16. **Callbacks, not state.** Mirroring obj 006: the canvas is **uncontrolled** by default but accepts a controller for advanced usage. Edits emit callbacks (`onAddBlock`, `onUpdateBlock`, `onDeleteBlock`, `onReorderBlock`, `onUpdateGraph(EdenTemplateGraph)`). Consumer owns persistence — fully transport-agnostic.
17. **Variables resolver lives in TRD-01 as a pure function on the registry.** No widget dependency. Signature: `EdenTemplateVariablesResolver.resolve(String text, Map<String, dynamic> data, {bool throwOnMissing = false, String missingPlaceholder = ''}) → String`. Substitutes `{{group.field}}` tokens. Edge: dotted paths (`{{customer.address.line1}}`) resolve nested Map keys. Edge: missing tokens replaced with `missingPlaceholder` unless `throwOnMissing: true`. Unit-tested in TRD 01.
18. **No drag-and-drop animation library.** Use Flutter's built-in `Draggable`, `DragTarget`, `ReorderableListView`. No `flutter_reorderable_grid_view` or similar. Same constraint as obj 006.

## Success criteria (must-haves, observable truths)

1. All 5 TRDs ship; `flutter analyze` clean; `flutter test` passes (existing tests still pass + ~60-90 new template-builder tests pass).
2. Every parity-checklist row (B-1..B-12, P-1..P-5, C-1..C-9, V-1..V-6, S-1..S-5, L-1..L-6, G-1..G-5, R-1..R-2, X-1..X-3) is implemented and has at least one widget or unit test that proves it. Each TRD's `<verify>` references the checklist rows it satisfies.
3. Existing obj-006 consumers (process_builder_screen.dart, eden_diagram demo) compile and render without change. Backward-compat invariant: nothing in `lib/src/widgets/eden_diagram/` or `lib/src/widgets/eden_process_canvas/` is modified by this objective.
4. `lib/dev_app/screens/template_builder_screen.dart` exists and `just dev-ui` renders a template-builder demo screen with: 3-section template (Header / Body / Footer), ~12-15 placeholder blocks across sections, working right-rail with 4 icon tabs (Blocks / Variables / Layout / Styles), variables panel with 5 sample groups (company / customer / appointment / invoice / line_items each with 3-5 fields registered), styles panel showing 6 brand-color swatches + font-family dropdown, layout panel showing page-size + orientation + margins + page-breaks affordances.
5. **Drag-from-palette works** in widget tests AND in the dev catalog: `tester.drag(find.byType(EdenTemplateBlockPaletteCard).at(0), Offset(400, 200))` simulates the drag onto the canvas (or `tester.tap` for click-to-add fallback), and on drop the `onAddBlock(blockType, section)` callback fires with the expected block type and section.
6. **Variables resolver works:** `EdenTemplateVariablesResolver.resolve('Hello {{customer.name}}', {'customer': {'name': 'Mark'}})` returns `'Hello Mark'`. Edge: nested dotted path. Edge: missing token returns `''` by default (or `missingPlaceholder`). Edge: `throwOnMissing: true` throws `EdenTemplateMissingVariableException`. Unit tests cover all four behaviors.
7. **Block-type registry works:** `EdenTemplateBlockRegistry.instance.resetToDefaults()` registers 12 block types; `lookup('text')` returns the text block descriptor; `byCategory('Content')` returns 10 content blocks; `byCategory('Advanced')` returns 2 advanced blocks; `register(EdenTemplateBlockDescriptor(id: 'payment_line', ...))` adds it and `lookup('payment_line')` returns it.
8. **Variables registry works:** `EdenTemplateVariablesRegistry.instance.register('customer', ['name', 'email', 'phone'])` makes the group available via `lookup('customer')` → ['name', 'email', 'phone']; `all()` returns Map; `reset()` clears.
9. **Vertical-stack layout works:** with `layout: EdenTemplateVerticalStackLayout()`, blocks in the active section render top-to-bottom as a Column / ReorderableListView; drag-to-reorder works; section tabs filter visible blocks.
10. **Freeform layout works:** with `layout: EdenTemplateFreeformLayout()`, blocks render at (x, y) coordinates from `EdenTemplateBlock.content['x'], content['y']`; the canvas composes `EdenDiagram` underneath.
11. **Section tabs work:** clicking Header / Body / Footer switches `activeSection`; only matching blocks render; empty-section placeholder shows when section has no blocks.
12. **Right-rail panel switch works:** clicking Blocks / Variables / Layout / Styles icon switches the visible panel.
13. **All 4 panels render correctly in isolation:**
    - `EdenTemplateBlockPalette` — 2-column grid of block cards; section headers per category; hover highlight; tap fires `onAddBlock`.
    - `EdenTemplateVariablesPanel` — search field + grouped scrolling list; tap fires `onInsertField('{{group.field}}')`; search filter narrows visible items; empty state when search yields nothing.
    - `EdenTemplateStylesPanel` — 6 color swatches (selected has white border + glow); font-family dropdown with 4 defaults; editable header/body font-size fields with min/max validation; fires `onChangeStyle(EdenTemplateStyleSettings)`.
    - `EdenTemplateLayoutPanel` — page-size SegmentedButton + orientation SegmentedButton + 2×2 margins grid (editable) + 2 page-break checkboxes; fires `onChangeLayout(EdenTemplateLayoutSettings)`.
14. **Bidirectional sync works:** `EdenTemplateGraph` round-trips through `toJson/fromJson` losslessly; consumer mutations via callbacks update local state; the canvas re-renders reflecting new state.
15. **All widget/unit tests use hand-built fixtures** (no LLM-generated test data). Every fixture file has the header line `// Do NOT regenerate via LLM — hand-built fixtures for EdenTemplate<Aspect>.`.
16. **No new pubspec deps added** — verified by grep on `pubspec.yaml` showing no additions.
17. **Backward compat verified:** all existing tests (~445+ widget tests, including obj 006's ~120-180 process-canvas tests) pass unchanged across all 5 TRDs.
18. **iPhone-narrow safe (≥390pt) — template builder fallback** — every panel widget tested in isolation at `SizedBox(width: 390)` shows no `RenderFlex overflowed` warnings. The full `EdenVisualTemplateBuilder` tested at `SizedBox(width: 390)` shows the fallback message (not an overflow).
19. **Roadmap updated:** objective 021 added under Active Objectives with TRD checklist (all `[ ]`).

## Out of scope (deferred to later objectives or skipped entirely)

- **PDF rendering** — library is transport-agnostic; PDF generation is a downstream `eden-platform-flutter` or app-layer concern.
- **Email-HTML rendering** — same as above. The block tree is the output; consumer-app transforms to email-safe HTML.
- **Real-time collaborative template editing.** Not in donor; consumer concern if needed later.
- **Undo/redo stack.** Not in donor; consumer-owned.
- **Block-content editing UI (rich text editor for the `text` block; image picker for `image` block).** The library exposes block placeholders + `onUpdateBlock(blockId, content)` callbacks; consumers wire up their own content editors (Quill, fleather, etc.). Library v1 ships placeholder rendering only — clicking a block opens a stub edit dialog with a single TextField for the `label` content field, demonstrating the callback wiring.
- **Variables resolver with conditionals (`{{#if customer.vip}}...{{/if}}`).** Out of scope v1; resolver is straight token substitution. Conditional logic is a TRD candidate for a follow-up objective if downstream needs it.
- **Image/asset upload.** Library exposes `EdenTemplateImageBlock` with a `Map<String, dynamic> content` slot for `url` — consumer is responsible for upload + serving the URL. Composes obj-001-07 `EdenAuthenticatedImage` at render time (if needed).
- **Template versioning + publishing flow.** Donor `Template` exposes `version` + `status` (draft/published) fields; library `EdenTemplateGraph` preserves them as data slots but does NOT implement the publish workflow. Same as obj 006's "isPublished / hasUnpublishedChanges" treatment.
- **AI-suggested template structure.** Future enhancement; not in donor; not a library concern.
- **Template marketplace / catalog.** Out of scope for a UI primitive.
- **Visual regression baselines** (VRT-01 v2 future objective).
- **Real-device iOS / Android testing** (downstream apps gate this; template builder is desktop/tablet UX anyway).
- **Multi-page preview rendering** (showing what the template looks like with sample data substituted). Out of scope v1; the dev catalog renders placeholder blocks. A `EdenTemplatePreview` widget composing the variables resolver is a follow-up TRD if downstream needs it.

## References

**Primary donor (trades-flutter — exact parity target):**
- `/Users/markemerson/Source/AOCyber-Trades/trades-flutter/lib/features/templates/domain/template_model.dart` (313 LOC — value classes: `Template`, `TemplateBlock`, `TemplateBundle`, `BlockType` enum, `BlockPaletteItem`, `MergeFieldGroup`, `LayoutSettings`, `StyleSettings`)
- `/Users/markemerson/Source/AOCyber-Trades/trades-flutter/lib/features/templates/presentation/widgets/builder_canvas.dart` (387 LOC — the composite root with toolbar + canvas + right rail + section tabs + block-placeholder rendering)
- `/Users/markemerson/Source/AOCyber-Trades/trades-flutter/lib/features/templates/presentation/widgets/block_palette_panel.dart` (277 LOC — palette with 2-column grid + content/advanced sections)
- `/Users/markemerson/Source/AOCyber-Trades/trades-flutter/lib/features/templates/presentation/widgets/variables_panel.dart` (240 LOC — search + grouped fields + monospace tokens)
- `/Users/markemerson/Source/AOCyber-Trades/trades-flutter/lib/features/templates/presentation/widgets/styles_panel.dart` (170 LOC — brand color swatches + font-family + font-size)
- `/Users/markemerson/Source/AOCyber-Trades/trades-flutter/lib/features/templates/presentation/widgets/layout_panel.dart` (234 LOC — page size + orientation + margins + page breaks)
- `/Users/markemerson/Source/AOCyber-Trades/trades-flutter/lib/features/templates/presentation/widgets/builder_toolbar.dart` (top toolbar — title + actions; library can SKIP if MVP — defer to consumer)
- `/Users/markemerson/Source/AOCyber-Trades/trades-flutter/lib/features/templates/presentation/widgets/template_sidebar.dart` (left rail with templates list — NOT a library concern; consumer-driven)
- `/Users/markemerson/Source/AOCyber-Trades/trades-flutter/lib/features/templates/presentation/widgets/bundle_detail_view.dart` (template bundle UI — out of scope for v1)

**Secondary references (inspiration for Dart idioms):**
- `lib/src/widgets/eden_process_canvas/` (obj 006 — third visual builder; same registry pattern, same controller pattern, same callback pattern)
- `lib/src/widgets/eden_diagram/` (obj 006 canvas engine — composed in freeform mode)

**Library context:**
- `.planning/PROJECT.md` (transport-agnostic constraint, test pattern, validation commands)
- `.planning/TRADES_REMAP_DEEP_AUDIT_2026-05-15.md` §2.3 (A4-c sub-system spec) + §6 (sub-system tracks) + §7 (locked decisions — generic, registry-driven)
- `.planning/objectives/006-a4a-visual-process-canvas/OBJECTIVE.md` (canonical visual-builder objective shape; A4-c follows the same pattern but smaller scope)
- `lib/dev_app/screens/process_builder_screen.dart` (obj 006 dev catalog; pattern reference for `template_builder_screen.dart`)
- `lib/dev_app/screens/home_screen.dart` (nav tile pattern)
- `eden-libs/CLAUDE.md` ("Keep platform logic in `eden-platform-flutter`, not in `eden-ui-flutter`")
- `~/.claude/CLAUDE.md` TDD Playbook (global — strict TDD + test-list-first + hand-built fixtures + outside-in for UI)

## Resolved planner intent

Per `df-tools intent resolve --objective 021`:
- **kind:** ui-lib (PROJECT.md)
- **work:** feature (inherited from PROJECT.md default_work; matches the work shape — net-new widget primitives + composite + dev catalog screen)
- **tdd:** strict (user playbook + defaults table)
- **depth:** comprehensive
- **fixture_strategy:** generators (hand-built factory functions)
- **test_list_first:** required
- **back_compat:** none (purely additive)
- **security_isolation:** n/a (ui-lib)
- **Active constraints:** `no_llm_test_data`, `no_property_based_default`, `no_gherkin_layer`
- **Applied directives:** `~/.claude/CLAUDE.md` (TDD Playbook absorbed at planning time)

---
objective: 014-b-retail-back-office
kind: ui-lib
work: feature
status: planned
estimated_effort: 1.5-2 weeks Claude execution
trd_count: 6
waves: 3
---

# Objective 014 — B-Retail Back-Office + Cross-Vertical Polish

## Goal

Ship the 6 retail-specific (and cross-vertical-leverage) UI primitives + composites that close the **`0 FULL / 1 PARTIAL / 4 BLOCKED` of 5 retail screens** rating from `VERTICAL_WIREFRAMES_VALIDATION_2026-05-17.md` §3.3. After this objective ships:

- A cashier renders a full **POS register** (left quick-add grid · center cart · right tender · receipt slide-out) on web + iPad via `EdenPOSRegisterScaffold` — the headline missing surface.
- A merchandiser composes **`EdenQuickAddProductGrid`** with photo + name + price + stock indicator tiles into POS register **and** trades quick-quote / fuel parts pick / salon retail front-counter.
- A merchant previews / prints / emails a receipt via **`EdenReceiptPreview`** (header → line items → tax/discount/promo → tender summary → footer) with print template and email/SMS variants.
- An inventory manager edits SKU rows inline (cost / price / on-hand / reorder-point / location) via **`EdenInventoryRowEditor`** with bulk-edit affordance — composes the obj-003 `EdenStockLevelIndicator`.
- A receiving clerk walks the **PO receiving flow** (scan PO → expected-vs-received variance → cost update → receive-partial/full/damaged) via **`EdenReceivingFlow`** composing read-only `EdenLineItemEditor`.
- An owner reads a **sales analytics dashboard** (KPI strip + trend chart + top-products + top-categories donut) via **`EdenSalesAnalyticsScaffold`** — composable into trades / fuel / salon analytics too.

These widgets are the lowest-layer retail-domain primitives. **Backend codegen, transport, and orchestration belong in `eden-biz-flutter` / `eden-platform-flutter`, not here.** Per `eden-libs/CLAUDE.md`: "Keep platform logic in `eden-platform-flutter`, not in `eden-ui-flutter`."

Parallelizable with obj-013 after obj-012 ships. Plans assume obj-012 composables (`EdenLineItemEditor`, `EdenSplitTender`, `EdenAggregateKpiStrip`, `EdenSparkline`, `EdenDonutChart` if added) are available; where they're not yet shipped, TRDs plan against the obj-012 TRD spec (`VERTICAL_WIREFRAMES_VALIDATION_2026-05-17.md` §5 Obj-012 proposal) and use the existing `EdenBarChart` + `EdenSparkline` already shipped in `lib/src/widgets/eden_chart.dart`.

## Why now

- **Retail is the BLOCKED vertical.** Per wireframes §3.3 synthesis: 4 of 5 retail screens are unshippable without these primitives. POS register, receiving, sales analytics all require new compositions; inventory list is partial.
- **Locked decision B-R1 from coverage assessment §6:** POS keypad ships **web + iPad/POS terminal native from v1.** Avoid the rebuild-later cost; touch-first gesture model + a11y posture have to be designed in, not retrofitted. ~2× scope, but locked.
- **Compose obj-012 commerce primitives heavily.** Of 6 widgets, the POS register + receiving flow + analytics scaffold all compose obj-012 outputs (`EdenLineItemEditor`, `EdenSplitTender`, `EdenAggregateKpiStrip`, `EdenSparkline`). Plans against TRD spec if obj-012 lands later; downstream wiring is a one-line constructor swap.
- **Cross-vertical reuse beyond retail.**
  - `EdenQuickAddProductGrid` → trades quick-quote (parts catalog), fuel delivery (product picker), salon retail front-counter.
  - `EdenReceiptPreview` → trades invoice preview, salon ticket preview, fuel delivery receipt, restaurant check (read-only mode).
  - `EdenInventoryRowEditor` → salon back-bar inventory, trades truck stock, fuel parts inventory.
  - `EdenReceivingFlow` → trades materials receiving, salon product replenishment.
  - `EdenSalesAnalyticsScaffold` → trades / fuel / salon owner dashboards (date range + KPI + trend + top-N pattern is universal).
  - `EdenPOSRegisterScaffold` → salon retail front-counter (with appointment context substituted for product grid), medical co-pay collection, gov cashier surfaces.
- **Pattern proven across objectives 001-011.** ~700+ tests shipped on the same `wrap()` helper, hand-built fixtures, dev catalog screen pattern.

## Components in scope

| ID | Component | Composes | Donor / Source |
|---|---|---|---|
| 014-02 | `EdenQuickAddProductGrid` | `EdenCard` + `EdenAuthenticatedImage` + `EdenStockLevelIndicator` + `EdenCurrencyDisplay` | New — generic touch-friendly tile grid; Apple HIG POS guidance (60pt+ targets) |
| 014-03 | `EdenReceiptPreview` | `EdenLineItemEditor` (obj-012, read-only mode) + `EdenCurrencyDisplay` | New — composes obj-012 line-item primitive + tax/discount/promo breakdown |
| 014-04 | `EdenInventoryRowEditor` | `EdenStockLevelIndicator` + `EdenInput` + `EdenCurrencyDisplay` | New — inline-edit row pattern; bulk-edit affordance |
| 014-05 | `EdenReceivingFlow` | `EdenLineItemEditor` (obj-012, read-only "expected" + editable "received") + variance reason picker | New multi-step flow — composes obj-012 + photo callback |
| 014-06 | `EdenSalesAnalyticsScaffold` | `EdenAggregateKpiStrip` (obj-012) + `EdenBarChart` + `EdenSparkline` (existing in `eden_chart.dart`) + `EdenQuickDateRange` + EdenDonutChart (obj-012 or behavioural shim) | New composite — analytics shell |
| 014-01 | `EdenPOSRegisterScaffold` | `EdenQuickAddProductGrid` (014-02) + `EdenBarcodeScanner` + `EdenSearchInput` + `EdenLineItemEditor` (obj-012) + `EdenSplitTender` (obj-012) + `EdenMembershipTierBadge` + `EdenReceiptPreview` (014-03) | Capstone — full retail POS register surface |

## Wave structure

| Wave | TRDs | Theme | Parallelism |
|---|---|---|---|
| **1 — Atomic primitives** | 014-02 (`EdenQuickAddProductGrid`), 014-03 (`EdenReceiptPreview`), 014-04 (`EdenInventoryRowEditor`) | Three atomic widgets, no inter-dependencies. 014-02 creates `lib/dev_app/screens/retail_screen.dart` (lowest sub-id wins create); 014-03 + 014-04 append Section() entries. Run parallel. | All 3 parallel; `co_modified_files` serializes `lib/eden_ui.dart` + `retail_screen.dart` within the wave |
| **2 — Flow composers** | 014-05 (`EdenReceivingFlow`), 014-06 (`EdenSalesAnalyticsScaffold`) | Both compose Wave 1 primitives (014-05 reuses `EdenLineItemEditor` read-only mode shared by 014-03; 014-06 stands alone but is logically Wave 2 because it gates the capstone). Run parallel. | 2 parallel; `co_modified_files` serializes shared files |
| **3 — Capstone POS register** | 014-01 (`EdenPOSRegisterScaffold`) | Final composite — depends on 014-02 (quick-add grid) + 014-03 (receipt slide-out) + obj-012 line-item editor + obj-012 split tender. Touch-target / a11y / responsive verification | Serial — single TRD |

**File-collision discipline:**
- `lib/eden_ui.dart` — every TRD appends export line(s) under section header `// Objective 014 — B-Retail back-office Wave N`. Mark each TRD `co_modified_files: [lib/eden_ui.dart]`.
- `lib/dev_app/screens/retail_screen.dart` — **new file, created by TRD 014-02 (Wave 1, lowest sub-id)**. Subsequent TRDs (014-03..06, then 014-01) each APPEND one Section() entry. TRDs 014-03..06 mark `co_modified_files: [lib/dev_app/screens/retail_screen.dart]`.
- `lib/dev_app/screens/home_screen.dart` — **register the `RetailScreen` `_Category` entry once in TRD 014-02** with subtitle covering all 6 widgets. Later TRDs do NOT modify `home_screen.dart`.

## Obj-012 dependency policy

This objective composes obj-012 outputs heavily (`EdenLineItemEditor`, `EdenSplitTender`, `EdenAggregateKpiStrip`, `EdenDonutChart` if shipped). Two scenarios:

**Scenario A — obj-012 shipped before obj-014 executes.** TRDs 014-03, 014-05, 014-06, 014-01 import from `package:eden_ui_flutter/eden_ui.dart` directly. No special handling.

**Scenario B — obj-012 not yet shipped (parallel planning).** Each affected TRD includes a **`<obj_012_dependency_strategy>`** subsection in its `<context>` block enumerating:
1. The specific obj-012 widget being composed.
2. The expected obj-012 public API surface per `VERTICAL_WIREFRAMES_VALIDATION_2026-05-17.md` §5 Obj-012 proposal.
3. **Behavioural shim:** if obj-012 widget absent at execution time, the executor uses an inline `_ReadOnlyLineItemTable` (or equivalent shim) inside the TRD-014 widget. Shim is a private widget — replaced one-liner when obj-012 lands.
4. **Detection rule:** executor checks `lib/src/widgets/eden_line_item_editor.dart` at TRD start. Present → import + compose; absent → inline shim + add a `TODO(obj-014→obj-012 swap):` marker comment.

The receipt-preview shim (014-03) uses a private `_LineItemTable` rendering `ListView` of `Row(SKU, name, qty, unitPrice, subtotal)` cells. The split-tender shim (014-01) uses a private `_TenderForm` collecting `cashAmount + cardAmount + checkAmount`. Both are minimal and stay private — the user-facing widget API in objective-014 is unchanged whether shim or real.

## Critical design constraints (locked, do not revisit)

1. **TDD strict (Iron Law) + test-list-first.** Every TRD's testable tasks carry `tdd="true"`. Test-list checklist at the top of every TRD enumerating happy/edge/failure cases BEFORE any test code. Hand-built fixture builders only (`no_llm_test_data` active). Fixture files named `test/widgets/_fixtures/eden_{component}_fixtures.dart` with header `// Do NOT regenerate via LLM — hand-built fixtures for Eden{Component}.`. RED → GREEN → REFACTOR. One test at a time. Per `~/.claude/CLAUDE.md` TDD Playbook habits 1-4.
2. **Outside-in for UI.** Per Playbook habit 5: static rendering tests first, then interaction tests, then helper unit tests. For composites (014-01, 014-05, 014-06): assert outer layout / zones / scaffolding BEFORE inner widget composition tests.
3. **Test pattern locked.** `testWidgets('renders ...', (tester) async {...})` with `wrap()` helper at the top of each test file. Mirror `test/widgets/eden_alert_test.dart` + obj-005 examples. Widget tests, NOT integration tests.
4. **Transport-agnostic.** No `dio`/`http`/`connectrpc`/`grpc`/`stripe_terminal`/`square_reader`. Card-entry uses obj-011's `EdenSecretField.classified` clipboard mode (already shipped). Photo capture is a callback parameter (`onPhotoCapture`); consumer wires `image_picker` / `camera` in their app.
5. **Material 3 + tokens.** Use `EdenSpacing`, `EdenRadii`, `EdenColors`, `EdenTypography` from `lib/src/tokens/`. Touch targets ≥48pt on tablet (per Apple HIG for POS); ≥44pt minimum elsewhere.
6. **iPhone-narrow safe (≥390pt).** Every TRD's test list includes a 390pt-width test asserting no `RenderFlex overflowed` warnings. `EdenPOSRegisterScaffold` collapses to **single-zone with tab strip at <1024pt** (explicit narrow-mode test required).
7. **Web + iPad-native responsive (locked decision B-R1, coverage assessment §6 item 4).** `EdenPOSRegisterScaffold` 3-zone layout at ≥1024pt logical width; collapses to single-zone tabbed layout at <1024pt. Touch targets ≥48pt on tablet. Test coverage MUST include both modes via `tester.binding.setSurfaceSize(...)`.
8. **PCI-aware via obj-011's `EdenSecretField` classified mode** for card-number entry in `EdenPOSRegisterScaffold` tender zone. **Re-use only — no new card-handling widgets in this objective.** Verify by `grep -E "card_number|cvv|pan" lib/src/widgets/eden_pos_register_scaffold.dart` returning empty (no hand-rolled PAN UI).
9. **Theme-profile aware.** `EdenThemeProfile.retailVibrant` (shipped via obj-009) for POS register prominence. Widgets don't hard-code retail-vibrant colors; they read from theme via `Theme.of(context)` so theme switching just works.
10. **Compact pinning per locked decision E rule 3.** Where a widget exposes Compact / Medium / Expanded variants (`EdenPOSRegisterScaffold` is the primary one in this objective), it respects `EdenAdaptiveTierScope.maybeOf(context)` AND explicit `forceCompact:` / `forceExpanded:` overrides. Mirror obj 002-05 `EdenCompanionShell` pattern.
11. **Generic types — don't bind to retail domain.** Every component takes a generic value class:
    - `EdenQuickAddProductGrid` accepts `List<EdenQuickAddProduct>` — generic `id + name + price + photoUrl? + onHand? + categoryId?`. Consumer maps domain.
    - `EdenReceiptPreview` accepts `EdenReceiptData(storeHeader, lineItems, tax, discount, promo?, tenderSummary, footer?)`.
    - `EdenInventoryRowEditor` accepts `EdenInventoryRowData(sku, name, cost?, price?, onHand?, reorderPoint?, location?)` with editable mode.
    - `EdenReceivingFlow` accepts `EdenReceivingDoc(poNumber, vendor, expectedItems, receivedItems)`.
    - `EdenSalesAnalyticsScaffold` accepts `EdenSalesAnalyticsData(dateRange, kpis, trendSeries, topProducts, topCategories)`.
    - `EdenPOSRegisterScaffold` accepts `EdenPosSession(cartItems, customer?, appliedPromos, tenderState)` — consumer maps everything.
12. **No backend bind.** No Stripe / Square / Toast / Shopify API knowledge in lib. Receipt printing is a callback (`onPrint: () async => ...`). Email/SMS send is a callback (`onSendEmail: (recipient) async => ...` / `onSendSms: ...`).
13. **No new pubspec deps.** Default: `flutter/material.dart` + `dart:math` + existing eden-ui-flutter primitives only. No `intl`, no `provider`, no `riverpod`, no `flutter_pos_printer_platform`. Receipt print is a CALLBACK; consumer wires platform print plugin in their app.
14. **No breaking changes to existing widgets.** Existing ~700+ widget exports must continue to pass `flutter test`. This objective is purely additive.
15. **Visual catalog entry per component.** Every TRD appends a Section() to `lib/dev_app/screens/retail_screen.dart`. TRD 014-02 creates the file with the QuickAddProductGrid section.
16. **Anti-pattern constraints (resolver-enforced):**
    - `no_llm_test_data` — Fixture builders hand-built (header line locked, no opt-out).
    - `no_property_based_default` — No `rapid`/`gopter`/`fast_check`. Descriptive `testWidgets('...')` names.
    - `no_gherkin_layer` — No `.feature` files, no Cucumber.

## Success criteria (must-haves, observable truths)

1. All 6 TRDs ship; `flutter analyze` clean; `flutter test` passes (existing ~700+ tests still pass + ~90-130 new retail-widget tests pass).
2. **`EdenQuickAddProductGrid` renders tile grid with photo + name + price + stock indicator.** Configurable `crossAxisCount` (4 / 6 / 8 columns), configurable tile size (default 96pt; ≥48pt touch target enforced). Drag-to-cart via Flutter `Draggable<EdenQuickAddProduct>` + `LongPressDraggable` (consumer wires `DragTarget` on cart side). Tap-to-add via `onTap(EdenQuickAddProduct)` callback. Category-filter horizontal chip strip optional via `categoryIds + onCategorySelected`. Composes `EdenAuthenticatedImage` for photos (handles `null` photo URL → placeholder icon) + `EdenStockLevelIndicator` corner-overlay when `onHand != null` + `EdenCurrencyDisplay` for price.
3. **`EdenReceiptPreview` renders configurable receipt layout** with 4 mode variants via `EdenReceiptPreviewMode { web, print, email, sms }`: web = scrollable preview, print = paginated `Container` template constrained to 80mm / 58mm widths (POS thermal printer common widths) + `pageBreakAfter` markers, email = single-column HTML-friendly column layout, sms = text-only flat layout. Header section (`storeName`, `address`, `phone`?), line items via `EdenLineItemEditor.readOnly` (obj-012) OR private `_ReadOnlyLineItemTable` shim, tax/discount/promo breakdown row, tender summary row, optional footer (return policy / tax ID). Composes `EdenCurrencyDisplay`.
4. **`EdenInventoryRowEditor` renders SKU / name / cost / price / on-hand / reorder-point / location inline-edit row.** Editable mode toggle via `editable: bool` constructor param. Bulk-edit affordance: a `selected: bool` checkbox at leading edge wired to consumer `onSelectionChanged(rowId, bool)` callback. Composes `EdenStockLevelIndicator(value: onHand / reorderPoint? * 2)` for the visual cue (consumer can override the formula). Composes `EdenInput` for editable text + `EdenCurrencyDisplay` for read-only money columns. Form changes emit `EdenInventoryRowDraft(rowId, changes)` on `onCommit` callback.
5. **`EdenReceivingFlow` walks 4-step PO receiving multi-step.** Step 1 (`SelectPo`) — search/scan input wired to `onPoLookup(query)` callback. Step 2 (`Variance`) — split-pane: left = read-only `EdenLineItemEditor` "expected" + right = editable `EdenLineItemEditor` (or shim) for "received qty"; row-level variance reason picker via `EdenSelect<EdenVarianceReason>` (damaged / shortQty / overShipped / wrongItem / unopened / other). Step 3 (`CostUpdate`) — optional new unit-cost input per line item where variance is set. Step 4 (`Disposition`) — three radio actions: `receivePartial` / `receiveFull` / `damaged`. Photo callback (`onPhotoCapture: () => Future<String?>`) for damaged dispositions. Emits `EdenReceivingDraft` on `onSubmit` callback.
6. **`EdenSalesAnalyticsScaffold` composite analytics shell:** header KPI strip (composes `EdenAggregateKpiStrip` from obj-012 OR private `_KpiStripShim` showing 5 `EdenStatCard`s in a `Wrap` for behavioural-shim fallback), trend chart row (composes `EdenBarChart` and/or `EdenSparkline` already shipped in `eden_chart.dart`), top-products list (`EdenListGroup` with rank + name + units + revenue + trend arrow), top-categories chart (composes `EdenDonutChart` from obj-012 OR `EdenBarChart` horizontal fallback). Date-range filter via existing `EdenQuickDateRange`. Composable into trades / fuel / salon analytics — generic value class, no retail-specific binding.
7. **`EdenPOSRegisterScaffold` 3-zone POS register surface.** At ≥1024pt logical width: 3-zone row layout — LEFT (`EdenQuickAddProductGrid` + top-strip `EdenSearchInput` + `EdenBarcodeScanner` icon button), CENTER (composes `EdenLineItemEditor` for cart OR `_CartShim`; quick-add header), RIGHT (composes `EdenSplitTender` for tender OR `_TenderShim`). Customer-attach affordance: top-of-center `EdenButton('Attach customer')` opens modal; once attached, top renders `EdenMembershipTierBadge` + name. Receipt slide-out via right-edge drawer composing `EdenReceiptPreview` (014-03). At <1024pt logical width: collapses to single-zone with 3-tab strip (`Products` / `Cart` / `Tender`). Touch targets ≥48pt on tablet. Composes obj-011 `EdenSecretField.classified` for PAN entry inside the tender zone (no hand-rolled card UI).
8. **Hand-built fixtures with locked header line.** Every fixture file under `test/widgets/_fixtures/eden_{component}_fixtures.dart` has line 1: `// Do NOT regenerate via LLM — hand-built fixtures for Eden{Component}.`. Verified by `grep -L 'Do NOT regenerate' test/widgets/_fixtures/eden_*_fixtures.dart` (NEW retail fixture files) returning empty.
9. **Dev catalog entry.** `lib/dev_app/screens/retail_screen.dart` exists and is registered in `home_screen.dart` `_categories` list with subtitle: `'POS register, quick-add grid, receipt preview, inventory row editor, receiving flow, sales analytics'`. `just dev-ui` → tap "B-Retail — Back-Office + POS" tile → all 6 components render with sample data. POS register section shows narrow-mode + wide-mode toggle.
10. **Exports section.** `lib/eden_ui.dart` has `// Objective 014 — B-Retail back-office + cross-vertical polish` section with sub-headers `Wave 1` / `Wave 2` / `Wave 3` and 6 export lines.
11. **Backward compat — no regressions.** `flutter test` runs all ~700+ existing tests successfully. No public API changes to any existing widget. New widgets are purely additive.
12. **iPhone-narrow safe (≥390pt)** — every TRD's test list includes a `tester.binding.setSurfaceSize(Size(390, 800))` test asserting no `RenderFlex overflowed` warnings. POS register has an additional explicit `tester.binding.setSurfaceSize(Size(390, 800))` test asserting collapse to single-zone tab strip.
13. **No new pubspec deps.** `pubspec.yaml` unchanged across all 6 TRDs. Verified by `git diff pubspec.yaml` returning empty after objective completes.
14. **Roadmap updated:** objective 014 added to Active Objectives with TRD checklist (all `[ ]`).

## Out of scope (deferred or skipped)

- **`EdenLoyaltyMemberDetail`** — punted to v2 (014-07 optional in orchestrator brief). Sales analytics shell covers loyalty KPIs adequately. Tracked as future TRD: `014-future: EdenLoyaltyMemberDetail`.
- **`EdenRefundFlow`** — punted to v2 (014-08 optional in orchestrator brief). Mirror of receiving flow shape; can ship after objective-014 lands. Tracked as future TRD: `014-future: EdenRefundFlow`.
- **Stripe Terminal / Square Reader integration.** Library is transport-agnostic. Card entry via obj-011 `EdenSecretField.classified` + consumer-owned reader integration.
- **Thermal printer driver wiring.** Receipt print is a callback (`onPrint: () async => ...`); consumer wires `flutter_pos_printer_platform` or vendor SDK.
- **Real-time inventory sync.** `EdenInventoryRowEditor` is a presentation primitive; consumer re-renders on backend update.
- **POS hardware-keyboard shortcuts** (e.g., F-key quick-add). Deferred to consumer; if widely needed will surface as a v2 enhancement.
- **Multi-store / multi-location** — value classes single-store. Multi-store is a consumer composition concern (route to a different `EdenPOSRegisterScaffold` per store).
- **Visual regression baselines** (VRT-01 v2 future objective).
- **Real-device iOS / Android / web testing** (downstream apps gate this).

## References

**Primary spec:**
- `.planning/VERTICAL_WIREFRAMES_VALIDATION_2026-05-17.md` §3.3 retail (BLOCKED rating, gap inventory) + §5 Obj-014 proposal
- `.planning/VERTICAL_UX_RESEARCH_2026-05-16.md` §1.5 retail research (Square POS / Shopify POS / Lightspeed / Toast UX patterns)
- `.planning/VERTICAL_COVERAGE_ASSESSMENT_2026-05-15.md` §6 B-R1 locked decision (web + iPad/POS native v1)

**Dependency: obj-012 commerce primitives (parallel or upstream):**
- `.planning/objectives/012-cross-vertical-commerce-primitives/` (planning in progress) — `EdenLineItemEditor`, `EdenSplitTender`, `EdenPaymentEntry`, `EdenAggregateKpiStrip`, `EdenSparkline` (already shipped), `EdenDonutChart`
- `.planning/VERTICAL_WIREFRAMES_VALIDATION_2026-05-17.md` §5 Obj-012 proposal — interface spec to plan against

**Existing widgets composed:**
- `lib/src/widgets/eden_authenticated_image.dart` (obj 001-07) — composed by 014-02
- `lib/src/widgets/eden_stock_level_indicator.dart` (obj 003-04) — composed by 014-02, 014-04
- `lib/src/widgets/eden_currency_display.dart` (obj 001-04) — composed by 014-02, 014-03, 014-04
- `lib/src/widgets/eden_membership_tier_badge.dart` (obj 001-06) — composed by 014-01
- `lib/src/widgets/eden_chart.dart` — already exports `EdenBarChart` + `EdenSparkline` + `EdenLineChart` — composed by 014-06
- `lib/src/widgets/eden_quick_date_range.dart` — composed by 014-06
- `lib/src/widgets/eden_barcode_scanner.dart` — composed by 014-01
- `lib/src/widgets/eden_secret_field.dart` (obj 011-08 classified mode) — composed by 014-01 (PAN entry)
- `lib/src/widgets/eden_adaptive_layout.dart` (`EdenAdaptiveTierScope`) — composed by 014-01 (responsive collapse)

**Theme / tokens:**
- `lib/src/theme/eden_theme_profile.dart` (`EdenThemeProfile.retailVibrant` — obj-009 ships) — POS prominence
- `lib/src/tokens/colors.dart`, `spacing.dart`, `radii.dart`, `typography.dart`

**Library context:**
- `.planning/PROJECT.md` (transport-agnostic constraint, test pattern, validation commands, iPhone-narrow ≥390pt baseline)
- `eden-libs/CLAUDE.md` ("Keep platform logic in eden-platform-flutter, not in eden-ui-flutter")
- `~/.claude/CLAUDE.md` TDD Playbook (global — strict TDD + test-list-first + hand-built fixtures + outside-in for UI + one test at a time)

**Pattern references (canonical TRD shape):**
- `.planning/objectives/005-b-fuel-components/005-01-TRD.md` through `005-06-TRD.md` — same wave structure (atomic → composing → capstone) + `co_modified_files` discipline + per-screen dev catalog pattern
- `.planning/objectives/011-compliance-overlay-primitives/011-01-TRD.md` — bootstrap-screen-from-first-TRD pattern

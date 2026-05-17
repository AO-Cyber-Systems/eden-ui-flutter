---
objective: 012-cross-vertical-commerce-primitives
type: full-objective
trd_count: 7
subsystem: commerce
tags: [line-item-editor, kpi-strip, payment-entry, split-tender, sparkline, bar-chart, donut-chart, dev-catalog]
dependency-graph:
  requires:
    - lib/src/widgets/eden_data_table.dart (obj 010-06, EdenDataTable.dense)
    - lib/src/widgets/eden_card.dart (obj 010-07, EdenCard.interactive)
    - lib/src/widgets/eden_currency_display.dart (obj 001-04, cents-based renderer)
    - lib/src/widgets/eden_chip.dart (existing — EdenChoiceChip used by PaymentEntry)
    - lib/src/widgets/eden_banner.dart (existing — variant-based)
    - lib/src/widgets/eden_button.dart (existing — used by SplitTender add-row)
    - lib/src/widgets/eden_empty_state.dart (existing — used by LineItemEditor)
    - lib/src/widgets/eden_chart.dart (existing — extended by Wave 3 TRDs)
    - lib/src/theme/eden_status_palette.dart (obj 009-02, dangerFg/successFg with graceful fallback)
  provides:
    - EdenLineItem<T> generic value class + EdenLineItemColumn enum
    - EdenLineItemEditor<T> StatefulWidget (table + stacked-card responsive modes)
    - EdenKpiTile + EdenKpiAggregate value classes + EdenKpiTrendPolarity + EdenKpiAggregateMode enums
    - EdenAggregateKpiStrip StatelessWidget (horizontal scroll + sticky aggregate footer)
    - EdenPaymentMethod enum (8 values w/ displayLabel + iconData)
    - EdenPaymentDraft value class + EdenPaymentEntry StatefulWidget
    - EdenSplitTender StatefulWidget (composes EdenPaymentEntry)
    - EdenSparkline additive params (minValue/maxValue/referenceLines/nullablePoints)
    - EdenBarChart additive params (xAxisLabel/yAxisLabel/minValue/maxValue/referenceLines)
    - EdenChartLegendPosition enum
    - EdenPieChart additive centerLabelSlot
    - EdenDonutChart NEW named widget
    - CommerceScreen dev-catalog screen (7 sections across all 7 TRDs)
  affects:
    - lib/eden_ui.dart (Obj 012 Wave 1/2/3 export sections — Wave 3 is comment-only because eden_chart.dart was already exported)
    - lib/dev_app/screens/home_screen.dart (new 'Commerce Primitives' tile)
tech-stack:
  added: []  # no new pubspec deps — pure Dart + Flutter
  patterns: [generic-value-class, fully-controlled-stateful-widget, slot-based-extension, composition-over-inheritance, customPainter-additive-params, transport-agnostic-draft]
key-files:
  created:
    - lib/src/widgets/eden_line_item_editor.dart
    - lib/src/widgets/eden_aggregate_kpi_strip.dart
    - lib/src/widgets/eden_payment_entry.dart
    - lib/src/widgets/eden_split_tender.dart
    - lib/dev_app/screens/commerce_screen.dart
    - test/widgets/_fixtures/eden_line_item_editor_fixtures.dart
    - test/widgets/_fixtures/eden_aggregate_kpi_strip_fixtures.dart
    - test/widgets/_fixtures/eden_payment_entry_fixtures.dart
    - test/widgets/_fixtures/eden_split_tender_fixtures.dart
    - test/widgets/_fixtures/eden_chart_sparkline_fixtures.dart
    - test/widgets/_fixtures/eden_chart_bar_fixtures.dart
    - test/widgets/_fixtures/eden_chart_donut_fixtures.dart
    - test/widgets/eden_line_item_editor_test.dart
    - test/widgets/eden_aggregate_kpi_strip_test.dart
    - test/widgets/eden_payment_entry_test.dart
    - test/widgets/eden_split_tender_test.dart
    - test/widgets/eden_chart_sparkline_test.dart
    - test/widgets/eden_chart_bar_test.dart
    - test/widgets/eden_chart_donut_test.dart
    - test/dev_app/commerce_screen_test.dart
  modified:
    - lib/src/widgets/eden_chart.dart  # additive params on EdenSparkline + EdenBarChart + EdenPieChart; new EdenDonutChart + EdenChartLegendPosition
    - lib/eden_ui.dart  # 3 wave sections (Wave 1 + Wave 2 export lines; Wave 3 marker comment only)
    - lib/dev_app/screens/home_screen.dart  # 'Commerce Primitives' tile registration
decisions:
  - "EdenLineItem<T> is generic over a payload type T (cart entry, quote line, claim posting, fuel grade, service entry). Consumer maps domain → library. Slot-based extension via customColumnBuilder for vertical-specific add-on chips."
  - "EdenLineItemEditor is fully controlled — never owns item state; items + onItemsChanged are required. Local state limited to TextEditingController buffers + announced-negative-id set."
  - "TextEditingControllers keyed by '<item.id>-<column.name>' so cursor position survives parent rebuilds; sync controller text on prop change only when text actually differs. Disposed in dispose()."
  - "Decimal input formatter widened to RegExp(r'[0-9.]') after the anchored regex stripped valid inputs. tryParse handles multi-period strings (e.g. '2.5.3' returns null → no emit, no exception)."
  - "Tax-rate input needs 4-decimal precision (0.0825); single shared formatter covers quantity + unitPrice + discount + tax via [0-9.] charset + tryParse fallthrough."
  - "EdenAggregateKpiStrip default tile height = 140 (NOT 96 from initial design). 96pt overflows when tile renders label + titleMedium value + bottom-row with arrow + secondaryLabel + trailing sparkline simultaneously."
  - "EdenChip has no built-in selection API. PaymentEntry uses EdenChoiceChip (existing widget, selected: bool + onSelected: ValueChanged<bool>) — not EdenChip."
  - "EdenCurrencyDisplay uses cents: int (NOT amount: double). Editor wraps with cents = (lineTotal * 100).round()."
  - "EdenBanner uses variant: EdenBannerVariant (NOT severity). Values: info/success/warning/danger."
  - "intl is NOT in pubspec. PaymentEntry + SplitTender hand-format currency using the same symbol map ('USD/CAD/AUD'→\$, 'EUR'→€, 'GBP'→£) that EdenCurrencyDisplay uses. No new dep."
  - "Amount-mismatch tolerance bumped to 0.011 (not 0.01 strict) to absorb IEEE 754 noise from (99.99 - 100.0).abs() = 0.01000000000000156."
  - "EdenSplitTender cash change-due rule: when allowOverCapacity=true + sum > total, show change-due only when last-modified row method is cash. Falls back to tail row when no edits have occurred (initialDrafts-hydration scenario)."
  - "EdenSplitTender rows keyed by ValueKey('st-row-N') stable IDs so widget state survives reorder/remove (prevents controller bleed between rows)."
  - "_SparklinePainter rewritten to walk contiguous-non-NaN segments rather than one big Path. Same single-segment behavior for backwards-compat input; gaps render correctly when nullablePoints=true."
  - "EdenBarChart with neither xAxisLabel nor yAxisLabel returns the bare CustomPaint (preserves exact backwards-compat layout). Column wrap only activates when at least one axis label is provided."
  - "EdenDonutChart renders its own legend Wrap (not EdenPieChart's internal legend) so it can control legendPosition (bottom/right). Inner EdenPieChart called with showLegend: false to suppress the duplicate."
  - "EdenPieChart's centerLabelSlot suppresses the painter-drawn centerLabel string by passing null centerLabel to the inner _PieChartPainter — avoids double-painting when slot is set."
  - "Catalog smoke tests resize tester.view.physicalSize wider+taller than default because ListView lazily renders Section children. Each new TRD's smoke test sets a viewport tall enough to materialize sections through that point."
metrics:
  duration_minutes: ~120  # 7 TRDs, sequential by wave
  completed_date: 2026-05-17
  tests_added: 165  # 2389 - 2224 baseline (includes 1 pre-existing skip)
  total_tests_after: 2389  # 2388 +1 skipped
  commits: 15  # 2-3 per TRD (test/feat/feat-catalog pattern)
  pushes: 4  # post-Wave-1 / post-012-03 / post-012-04 / post-objective
---

# Objective 012 — Cross-Vertical Commerce Primitives Summary

Seven foundational commerce primitives that 6+ blocked screens across all 4 verticals (medical / fuel / retail / trades) depend on. After this objective ships, downstream `eden-biz-flutter` and any vertical-specific app can compose a POS register, quote builder, invoice surface, claim posting form, fuel pricing card, customer dashboard, KPI strip, or analytics screen out of library primitives — without re-implementing the line-item editor, the payment-method picker, the split-tender composer, the multi-KPI strip with aggregate footer, or the chart family. Per `VERTICAL_WIREFRAMES_VALIDATION_2026-05-17.md` §4.2: the **single highest-leverage objective in the entire roadmap** (every widget reused in ≥3 verticals).

## Waves shipped

| Wave | TRDs | Outcome |
|---|---|---|
| 1 — Foundation primitives | 012-01, 012-02 | `EdenLineItemEditor<T>` (generic line-item table — THE most foundational primitive) + bootstrapped commerce_screen + home_screen tile; `EdenAggregateKpiStrip` (N-tile strip + sticky aggregate footer) |
| 2 — Payment composers | 012-03, 012-04 | `EdenPaymentEntry` (transport-agnostic draft with 8-method enum + method-specific reference hints + amount-mismatch banner) → `EdenSplitTender` composes N PaymentEntry rows with 5-state capacity banners (balanced/under/over/change-due/overage) |
| 3 — Chart family enhancements | 012-05, 012-06, 012-07 | Closed coverage gap on already-shipping EdenSparkline + EdenBarChart + EdenPieChart (was 0 tests, now 43 across the 3 chart test files) + 4/5/3 additive params per widget + `EdenDonutChart` named-widget wrapper + `EdenChartLegendPosition` enum |

Within-wave order:
- **Wave 1** — 012-01 bootstrapped `commerce_screen.dart` (NEW file) + registered `home_screen` tile; 012-02 APPENDED a Section beneath the anchor comment.
- **Wave 2** — 012-03 → 012-04 sequential (04 composes 03). Both APPEND Sections.
- **Wave 3** — 012-05 / 012-06 / 012-07 are independent (different test files, different append anchors) but executed sequentially in this run; could parallelize.

## Components shipped

| # | Component | Type | Verticals served |
|---|---|---|---|
| 012-01 | `EdenLineItemEditor<T>` + `EdenLineItem` + `EdenLineItemColumn` | Net-new | Medical · Retail · Trades · Fuel · Salon |
| 012-02 | `EdenAggregateKpiStrip` + `EdenKpiTile` + `EdenKpiAggregate` + 2 enums | Net-new | All 4 + Salon (8 screens per validation §4.1) |
| 012-03 | `EdenPaymentEntry` + `EdenPaymentDraft` + `EdenPaymentMethod` | Net-new | Medical (copay) · Retail (POS) · Trades (invoice) · Fuel (POD) · Salon |
| 012-04 | `EdenSplitTender` (composes 012-03) | Net-new | Retail (POS) · Trades (invoice) · Medical (billing) · Salon (high-ticket) |
| 012-05 | `EdenSparkline` enhancements + tests + dev catalog | Coverage + extension | Medical (lab trends) · Retail (sales trend) · Fuel (tank history) · all KPI tiles |
| 012-06 | `EdenBarChart` enhancements + tests + dev catalog | Coverage + extension | Retail (analytics) · Fuel (volume) · Medical (claim mix) · Trades (revenue) |
| 012-07 | `EdenDonutChart` (NEW named) + `EdenPieChart.centerLabelSlot` + `EdenChartLegendPosition` + tests + dev catalog | Coverage + extension | All 4 (analytics screens) · Salon (service mix) |

## Deviations from plan

| # | Deviation | Reason |
|---|---|---|
| 1 | **EdenChip → EdenChoiceChip** for the PaymentEntry method picker. | TRD spec referenced `EdenChip(selected: bool, onTap: ...)` but `EdenChip` only supports `variant/icon/onDeleted`. The selection API lives on the sibling `EdenChoiceChip`. (Caught at TRD-execute time per the TRD's own "Verify the actual API at TRD-execute time" gotcha.) |
| 2 | **EdenBanner uses `variant:`, not `severity:`** with values `info/success/warning/danger`. PaymentEntry + SplitTender call sites adjusted accordingly. |
| 3 | **EdenCurrencyDisplay uses `cents: int`**, not `amount: double` + `currencyCode`. LineItemEditor + PaymentEntry banner converts via `(amount * 100).round()`. |
| 4 | **`intl` package NOT in pubspec.** PaymentEntry + SplitTender hand-format currency using the same `_currencySymbols` map that `EdenCurrencyDisplay` already ships. Mirrors the existing in-house pattern; no new dependency added. |
| 5 | **AggregateKpiStrip tile height bumped from 96 → 140**. RenderFlex overflow when label + value + trend + secondaryLabel + trailingSlot composed in a 96pt-tall tile. 140pt absorbs all 5 elements without truncation. |
| 6 | **Amount-mismatch tolerance bumped to 0.011** in PaymentEntry. Strict `<= 0.01` triggered false positives because `(99.99 - 100.0).abs()` produces `0.01000000000000156` due to IEEE 754 rounding. Slightly-relaxed tolerance absorbs the noise. |
| 7 | **Decimal input formatter widened to `[0-9.]`** in LineItemEditor (was anchored `^\d*\.?\d{0,3}`). The anchored regex stripped valid trailing digits when char-by-char input went through the formatter. Falls back to `double.tryParse` to discard genuinely malformed input (e.g. multi-period strings → no emit). |
| 8 | **Decimal precision bumped 3 → 4 decimals** to support tax-rate inputs like `0.0825` for 8.25% (3-decimal cap truncated to 0.082). |
| 9 | **Catalog smoke tests resize tester.view** to a wide+tall physical-size before pumping CommerceScreen. ListView lazily renders Section children; without a tall viewport, later sections (BarChart, DonutChart) drop off-frame and tests fail with `findsNothing`. |
| 10 | **EdenDonutChart renders its own legend Wrap** rather than passing `legendPosition` down to EdenPieChart. EdenPieChart's internal legend is hardcoded to the right side via a Row — `legendPosition: bottom` requires a Column-based layout. Cleanest approach: `EdenPieChart(showLegend: false)` + EdenDonutChart owns the legend widget. |
| 11 | **`SemanticsService.announce` is deprecated** in Flutter 3.41 (replaced by `sendAnnouncement` which requires a FlutterView arg). LineItemEditor uses the deprecated form with an `// ignore: deprecated_member_use` comment because the replacement API surface varies across SDK versions and the deprecated method still functions correctly on 3.41. |

All deviations were inline auto-fixes — no architectural decisions required user intervention.

## Tests

- **Total project tests**: 2389 pass + 1 skip (was 2224 baseline = +165 from this objective).
- **Per-TRD breakdown**:
  - 012-01 EdenLineItemEditor: 34 widget + 2 catalog smoke
  - 012-02 EdenAggregateKpiStrip: 29 widget + 1 catalog smoke
  - 012-03 EdenPaymentEntry: 32 widget + 1 catalog smoke
  - 012-04 EdenSplitTender: 19 widget + 1 catalog smoke
  - 012-05 EdenSparkline: 14 widget + 1 catalog smoke (first-ever tests on chart family)
  - 012-06 EdenBarChart: 13 widget + 1 catalog smoke (first-ever tests)
  - 012-07 EdenDonutChart + EdenPieChart: 16 widget + 1 catalog smoke (first-ever tests on EdenPieChart)
- **TDD discipline**: hand-built fixtures with `// Do NOT regenerate via LLM` header for every test file; outside-in test order per the global Playbook (widget rendering → editing → a11y).
- **`flutter analyze`**: zero new issues across all created/modified files. Pre-existing 199 issues in `test/widgets/scheduler/` are out-of-scope per the deviation rules and have been there since obj 008.

## Key implementation patterns (reusable for downstream objectives)

1. **Fully controlled stateful primitives** — LineItemEditor + PaymentEntry + SplitTender never own domain data; they only own ephemeral UI buffers (TextEditingController draft text, last-modified-index, etc.). Consumers re-render on every callback.
2. **Generic-over-payload pattern** — `EdenLineItemEditor<T>` accepts a typed payload so consumers map domain models without library coupling. Downstream pattern: every primitive that wraps "a row of consumer-owned data" should be generic.
3. **Slot-based extension** — `itemPickerSlot` / `footerSlot` / `customColumnBuilder` / `trailingSlot` / `centerLabelSlot` all give consumers escape hatches for vertical-specific content (CPT-code picker, fuel-grade chips, KPI sparkline) without baking domain logic into the library.
4. **Transport-agnostic value objects** — `EdenPaymentDraft` produces *intent*; consumer wires Stripe/Square/Adyen processing downstream. No `dio`/`http`/`connectrpc` in the library.
5. **Additive constructor params with default-preserving behavior** — every chart enhancement (012-05 sparkline, 012-06 barChart, 012-07 pieChart) is purely additive; old call sites compile and render unchanged.
6. **Composition over inheritance for chart variants** — `EdenDonutChart` wraps `EdenPieChart(donut: true)` rather than subclassing or duplicating painter code.
7. **Per-row ValueKey via stable IDs** — SplitTender's row state stays attached to its draft across reorder/remove because each row has a `ValueKey(_rowIds[i])`. Same pattern repeated in LineItemEditor's TextEditingController keying.
8. **Theme-extension graceful fallback** — every place that reads `Theme.of(context).extension<EdenStatusPalette>()` falls back to `EdenColors.success`/`.error`/`.neutral` when the extension is absent (obj 009 not wired into consumer's app).
9. **Catalog viewport resize for ListView lazy rendering** — `tester.view.physicalSize = const Size(W, H)` with `addTearDown(tester.view.resetPhysicalSize)` ensures lazy ListView children materialize for smoke tests.

## Downstream unblocked

- **Obj 013 (B-Medical Clinical Primitives)** — claim posting + copay + billing screens compose `EdenLineItemEditor` + `EdenPaymentEntry` + `EdenSplitTender` + `EdenDonutChart` (claim mix).
- **Obj 014 (B-Retail Back-Office)** — analytics composites use `EdenAggregateKpiStrip` + `EdenBarChart` + `EdenSparkline` + `EdenDonutChart`.
- **`eden-biz-flutter` shell** — POS register, quote builder, invoice surface, customer dashboards all directly compose these primitives.

## Commits

15 commits across 7 TRDs, following the test/feat/feat-catalog pattern per the TDD Playbook:

| Hash | TRD | Subject |
|---|---|---|
| a47517d | 012-01 | feat: EdenLineItem<T> + EdenLineItemEditor table mode |
| 75f6cbb | 012-01 | feat: editing handlers, reorder, stacked-card mode, slots, a11y |
| 8fbe6c3 | 012-01 | feat: bootstrap commerce_screen dev catalog + home_screen tile |
| 2e04597 | 012-02 | feat: EdenAggregateKpiStrip + KpiTile/KpiAggregate value classes |
| 011bdff | 012-02 | feat: append AggregateKpiStrip dev catalog section across 4 verticals |
| bb3ee7c | 012-03 | feat: EdenPaymentEntry + EdenPaymentMethod + EdenPaymentDraft |
| 993e736 | 012-03 | feat: append PaymentEntry dev catalog section across 4 verticals |
| 922c485 | 012-04 | feat: EdenSplitTender multi-method composer |
| 80bfb2a | 012-04 | feat: append SplitTender dev catalog section across 3 scenarios |
| f84f456 | 012-05 | feat: EdenSparkline additive params + first coverage tests |
| eef94c2 | 012-05 | feat: append Sparkline dev catalog section + Wave 3 export marker |
| d9466c6 | 012-06 | feat: EdenBarChart additive params + first coverage tests |
| 4985713 | 012-06 | feat: append BarChart dev catalog section across 4 verticals |
| e3a061a | 012-07 | feat: EdenDonutChart + EdenPieChart centerLabelSlot + legend positioning |
| 1c0cd66 | 012-07 | feat: append DonutChart dev catalog section + CLOSE objective 012 |

All commits via `df-tools commit` (DevFlow plan-scoped). Pushed to `AO-Cyber-Systems/eden-ui-flutter#main` across 4 pushes (after Wave 1, after 012-03, after 012-04, and at objective close).

## Self-Check

- [x] All 7 widgets / value-class groups shipped + exported under their wave sections in `lib/eden_ui.dart`.
- [x] All 7 widget test files exist under `test/widgets/` with hand-built `_fixtures/` files (each starting with `// Do NOT regenerate via LLM`).
- [x] `commerce_screen.dart` ships 7 Sections (LineItemEditor + AggregateKpiStrip + PaymentEntry + SplitTender + Sparkline + BarChart + DonutChart) with all placeholder anchor comments resolved.
- [x] `home_screen.dart` registers the `Commerce Primitives` tile.
- [x] `flutter test` — 2389/2389 pass + 1 skip (no regressions vs the 2224 baseline).
- [x] `flutter analyze` — zero new issues in created/modified files (pre-existing 199 are out-of-scope per deviation rules).
- [x] Backwards-compat preserved on all chart enhancements — every existing `EdenSparkline` / `EdenBarChart` / `EdenPieChart` call site continues to render unchanged.
- [x] 15 commits made via `df-tools commit`; 4 pushes to origin; objective 012 closed.

**Status: COMPLETE 2026-05-17.**

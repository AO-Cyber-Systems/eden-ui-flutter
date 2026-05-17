---
objective: 012-cross-vertical-commerce-primitives
kind: ui-lib
work: feature
status: planned
github_repo: AO-Cyber-Systems/eden-libs
---

# Objective 012 — Cross-Vertical Commerce Primitives

## Goal

Ship the 7 foundational commerce primitives that **6+ blocked screens across all 4 verticals (medical / fuel / retail / trades)** depend on. After this objective ships, downstream `eden-biz-flutter` and any vertical-specific app can compose a POS register, quote builder, invoice surface, claim posting form, fuel pricing card, customer dashboard, KPI strip, or analytics screen out of library primitives — without re-implementing the line-item editor, the payment-method picker, the split-tender composer, the multi-KPI strip with aggregate footer, the sparkline, the bar chart, or the donut chart.

Per `VERTICAL_WIREFRAMES_VALIDATION_2026-05-17.md` §4.2: this is the **single highest-leverage objective in the entire roadmap** (every widget reused in ≥3 verticals). **MUST ship before objectives 013 (medical) and 014 (retail back-office)** because three of obj 013's screens (claim, copay, billing) need `EdenLineItemEditor` and obj 014's analytics composites need `EdenAggregateKpiStrip`.

## Scope

7 TRDs across 3 waves (~2 wk Claude execution):

**Wave 1 — Foundation primitives** (2 TRDs, parallel)
- 012-01 — `EdenLineItemEditor<T>` + `EdenLineItem` value class + slot-based extension
- 012-02 — `EdenAggregateKpiStrip` + `EdenKpiTile` value class + responsive horizontal scroll + sticky aggregate footer

**Wave 2 — Payment composers** (2 TRDs, sequential — 04 composes 03)
- 012-03 — `EdenPaymentEntry` + `EdenPaymentDraft` + configurable allowed-method allowlist
- 012-04 — `EdenSplitTender` (composes `EdenPaymentEntry`; over/under-capacity error states)

**Wave 3 — Chart family — test coverage + dev catalog + missing surface area** (3 TRDs, parallel)
- 012-05 — `EdenSparkline` test coverage + dev catalog enrichment + nullable-data + reference-line slot (extends already-shipping widget)
- 012-06 — `EdenBarChart` test coverage + dev catalog enrichment + grouped-by-x mode + axis-label support (extends already-shipping widget)
- 012-07 — `EdenDonutChart` API extraction (alias / variant of `EdenPieChart(donut: true)`) + test coverage + dev catalog enrichment + center-label-slot widening + legend-position option

### Codebase discovery (PLANNING-TIME FINDING — surface to user)

**The chart family already exists in `lib/src/widgets/eden_chart.dart`.** `EdenLineChart`, `EdenBarChart`, `EdenPieChart` (with `donut: true` parameter + `centerLabel`), and `EdenSparkline` ship today as public widgets, exported from `lib/eden_ui.dart`. The validation doc statement "EdenChart family is line-only" (§3 and §4.2) is **stale**. Three implications for Wave 3 TRDs:

1. **No "build EdenBarChart from scratch" work.** It exists.
2. **Coverage gap is real.** Zero test file (`test/widgets/eden_chart_test.dart` does not exist) — these widgets currently ship with no behavioral assertion of grid drawing, label rendering, value placement, donut hole rendering, or sparkline area fill.
3. **API gap is small but real.** `EdenBarChart` ships as flat grouped — but the dispatch between "grouped bar" and "stacked bar" relies on `stacked: bool` (already there). Missing: grouped-by-x category labels, axis-label slots, reference lines (needed for sparkline "in table cell" usage), and `EdenDonutChart` as a named widget rather than `EdenPieChart(donut: true)` shorthand.

Wave 3 TRDs scope to: **close the coverage gap + close the small API gap + ship the dev catalog**. Downstream analytics screens depend on test confidence + API completeness, not on net-new widgets.

## Components shipped

| # | Component | Type | Reuse |
|---|---|---|---|
| 012-01 | `EdenLineItemEditor<T>` + `EdenLineItem` + `EdenLineItemColumn` | Strict net-new | POS · quote builder · invoice · claim posting · pricing admin · trades estimate |
| 012-02 | `EdenAggregateKpiStrip` + `EdenKpiTile` | Strict net-new | 8 screens (M5 · F4 · F5 · R2 · R3 · R4 · R5 · T3) |
| 012-03 | `EdenPaymentEntry` + `EdenPaymentDraft` + `EdenPaymentMethod` enum | Strict net-new | POS · POD payment · invoice payment · medical copay · split-tender base |
| 012-04 | `EdenSplitTender` | Strict net-new (composes 012-03) | Retail POS · trades invoice · medical billing |
| 012-05 | `EdenSparkline` enhancements + tests + dev catalog | Coverage + extension | Lab trends · sales trend · tank-level history · in-table cell trends |
| 012-06 | `EdenBarChart` enhancements + tests + dev catalog | Coverage + extension | Sales analytics · fuel volume · pricing · trades revenue |
| 012-07 | `EdenDonutChart` (named) + center-slot widening + tests + dev catalog | Coverage + extension | Category mix · payment-method split · inventory categories · revenue distribution |

## Constraints

- **No new pubspec deps.** All work in pure Dart + Flutter. Charts continue to use `CustomPainter` (the existing pattern; see `_BarChartPainter`, `_PieChartPainter`, `_SparklinePainter` in `eden_chart.dart`).
- **Transport-agnostic.** `EdenPaymentEntry` returns an `EdenPaymentDraft` value object; consumer wires actual payment processing. No `dio` / `http` / `connectrpc`.
- **Generic types.** `EdenLineItemEditor<T>` accepts a typed line-item value class. Consumer maps domain model (cart entry, quote line, invoice line, claim posting line) to library value classes. Slot-based extension via `customColumnBuilder` for vertical-specific item-picker chips or per-row custom fields.
- **Composes existing widgets.**
  - `EdenLineItemEditor` uses `EdenDataTable.dense` (obj 010, shipped) for the table chrome
  - `EdenPaymentEntry` uses `EdenCurrencyDisplay` (obj 001, shipped) for amount display + standard `TextFormField` for amount entry
  - `EdenAggregateKpiStrip` uses `EdenCard.interactive` (obj 010, shipped) per tile + horizontal `ListView` for scroll
  - `EdenSplitTender` composes `EdenPaymentEntry` rows
- **Theme-profile aware (graceful fallback).** Read `EdenStatusPalette` (obj 009, shipped) for variance highlighting (negative balance red, positive green) and payment-status colors. If theme extension absent, fall back to `EdenColors.success` / `.warning` / `.error` constants.
- **iPhone-narrow (≥390pt) responsive.** No `RenderFlex overflowed` warnings. Line-item editor degrades to a stacked card view at narrow widths (auto-route via `LayoutBuilder` — see EdenDataTable.dense pattern). KPI strip horizontally scrolls. Payment method picker wraps.
- **Test-pairing rule enforced.** Every source file with logic has a paired `test/widgets/eden_*_test.dart` file. New chart tests for already-shipping widgets land alongside the API extensions.
- **Hand-built fixtures only.** No LLM-generated test data. Fixture files start with `// Do NOT regenerate via LLM — hand-built fixtures for {WidgetName}.`
- **TDD strict per user CLAUDE.md playbook.** Test-list-first (habit 2), one test at a time (habit 3), fixture builders ahead of first behavior test (habit 4), outside-in for UI surfaces (habit 5 — widget rendering tests first, then unit helper tests for math).
- **Backwards-compatible chart work.** `EdenBarChart`, `EdenPieChart`, `EdenSparkline` enhancements are ADDITIVE constructor params with defaults that preserve current behavior. All existing call sites (dev catalog screens that demo these chart widgets) compile and behave identically without changes. `EdenDonutChart` is a NEW name that wraps `EdenPieChart(donut: true)` — does not replace `EdenPieChart`.

## Cross-vertical re-use

Every primitive exposes a generic-enough API for ≥3 verticals:

| Widget | Verticals served | Notes |
|---|---|---|
| `EdenLineItemEditor<T>` | Medical · Retail · Trades · Fuel | Generic value class; slot-based custom columns |
| `EdenAggregateKpiStrip` | All 4 + Salon (already) | Slot-based per-tile content |
| `EdenPaymentEntry` | Medical (copay) · Retail (POS) · Trades (invoice) · Fuel (POD) · Salon | Configurable method allowlist per consumer/tenant |
| `EdenSplitTender` | Retail (POS) · Trades (invoice) · Medical (billing) · Salon (high-ticket) | Composes EdenPaymentEntry |
| `EdenSparkline` | Medical (lab trends) · Retail (sales trend) · Fuel (tank history) · all KPI tiles | In-table-cell + standalone |
| `EdenBarChart` | Retail (analytics) · Fuel (volume) · Medical (claim mix) · Trades (revenue) | Grouped + stacked + horizontal modes |
| `EdenDonutChart` | All 4 (analytics screens) · Salon (service mix) | Center-label slot + legend |

## Verification

- All 7 widgets render correctly on iPhone-narrow (≥390pt) without `RenderFlex overflowed`.
- All 7 widgets have widget tests using the `wrap()` helper pattern.
- `EdenLineItemEditor` integration test composes with `EdenCurrencyDisplay` (obj 001) + `EdenDataTable.dense` (obj 010) without breaking either.
- `EdenSplitTender` integration test verifies the over-capacity error state activates when `paymentDrafts.sum > total` and clears when balanced.
- New dev catalog screen `lib/dev_app/screens/commerce_screen.dart` showcases all 7 widgets with realistic cross-vertical examples (retail cart, medical claim, trades quote, fuel POD).
- Wave-specific export sections in `lib/eden_ui.dart`:
  - `// Objective 012 — Cross-vertical commerce primitives Wave 1` (012-01, 012-02)
  - `// Objective 012 — Cross-vertical commerce primitives Wave 2` (012-03, 012-04)
  - `// Objective 012 — Cross-vertical commerce primitives Wave 3` (012-05 .. 012-07 — adds new exports; existing `eden_chart.dart` export stays where it is)
- All existing ~1000+ tests pass unchanged (backwards-compat gate).

## Output (per wave landing)

- 4 new widget files + 3 chart-family enhancements under `lib/src/widgets/`:
  - `lib/src/widgets/eden_line_item_editor.dart` (NEW)
  - `lib/src/widgets/eden_aggregate_kpi_strip.dart` (NEW)
  - `lib/src/widgets/eden_payment_entry.dart` (NEW)
  - `lib/src/widgets/eden_split_tender.dart` (NEW)
  - `lib/src/widgets/eden_chart.dart` (ENHANCED — additive params + EdenDonutChart class)
- 7 new test files under `test/widgets/`:
  - `eden_line_item_editor_test.dart`
  - `eden_aggregate_kpi_strip_test.dart`
  - `eden_payment_entry_test.dart`
  - `eden_split_tender_test.dart`
  - `eden_chart_sparkline_test.dart` (NEW — covers already-shipping EdenSparkline)
  - `eden_chart_bar_test.dart` (NEW — covers already-shipping EdenBarChart)
  - `eden_chart_donut_test.dart` (NEW — covers EdenDonutChart + EdenPieChart donut mode)
- 7 new fixture files under `test/widgets/_fixtures/`
- 1 new dev catalog screen `lib/dev_app/screens/commerce_screen.dart`
- 1 new home_screen tile ("Commerce Primitives")
- 3 wave export sections in `lib/eden_ui.dart`
- ROADMAP.md entry marked complete when objective ships

## Sequencing

Wave order is by **dependency direction**:

- Wave 1 (line-item + KPI strip) ships first. Both Wave 1 TRDs are parallel — no file overlap.
- Wave 2 (payment composers) ships second. 012-04 composes 012-03, so 04 depends on 03.
- Wave 3 (chart family) is independent of Waves 1/2 and could parallelize with Wave 1, but the user's locked wave order says it ships LAST so we honor it. All 3 Wave 3 TRDs are parallel (independent test files; only 012-05 / 012-06 / 012-07 each append a Section() to `commerce_screen.dart`, append order is alphabetical-by-TRD-number — 05 → 06 → 07).

Within Wave 3, **TRD 012-05 bootstraps `commerce_screen.dart`** (NEW file, registers `home_screen` tile). 012-06 and 012-07 APPEND Section() entries.

Wait — let me re-check: Wave 1 TRDs come first chronologically. 012-01 bootstraps `commerce_screen.dart`. 012-02 + Wave 2 TRDs + Wave 3 TRDs all APPEND sections.

## Dependency notes

- **Obj 001 dependencies (Wave A):** `EdenCurrencyDisplay` (001-04, SHIPPED). Used by 012-01 (line-total cell), 012-03 (amount display).
- **Obj 010 dependencies:** `EdenDataTable.dense` (010-06, SHIPPED), `EdenCard.interactive` (010-07, SHIPPED). Used by 012-01 and 012-02.
- **Obj 009 dependency (advisory):** `EdenStatusPalette` ThemeExtension (009-02, SHIPPED). Used for variance highlighting in 012-02 + payment-status in 012-03. Graceful fallback to `EdenColors.success/warning/error` if theme extension absent.
- **Already-shipping but untested:** `EdenLineChart`, `EdenBarChart`, `EdenPieChart`, `EdenSparkline` in `eden_chart.dart` — Wave 3 closes their coverage gap.
- **Existing widgets composed (no edits required):** `EdenCurrencyDisplay`, `EdenDataTable.dense`, `EdenCard.interactive`, `EdenButton`, `EdenChip`, `EdenSelect` (if needed for method picker — verify at TRD-write time).

## Related research / locked decisions

- `.planning/VERTICAL_WIREFRAMES_VALIDATION_2026-05-17.md` §5 (Obj 012 proposal — primary spec), §4.1 (frequency-ranked gap inventory), §4.2 (objective sequencing rationale)
- `.planning/VERTICAL_UX_RESEARCH_2026-05-16.md` §3 (line-item editor density + Polaris/shadcn/Material 3 patterns)
- `.planning/objectives/00{9,10,11}-*/OBJECTIVE.md` (canonical TRD shape + Wave-pattern precedent)
- `~/.claude/CLAUDE.md` TDD Playbook — strict TDD, test-list-first, hand-built fixtures, outside-in (widget-rendering tests → unit helper tests for math)

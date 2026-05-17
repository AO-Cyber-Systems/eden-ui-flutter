---
objective: 019-trades-polish-fuel-quick-wins
kind: ui-lib
work: feature
status: planned
estimated_effort: 3-4 weeks Claude execution
trd_count: 7
waves: 2
---

# Objective 019 — Trades Polish + Fuel Quick Wins

## Goal

Close the remaining launch-blocking gaps in two launch-adjacent verticals (trades + fuel) by shipping 7 widgets that cluster around the highest-leverage cross-vertical recommendations from `USE_CASES_TRADES_2026-05-17.md` (Recs #1, #2, #9) and `USE_CASES_FUEL_2026-05-17.md` (Recs #1, #2, #3, #4). After this objective ships:

- **Eden Biz trades SKU** can compose the ServiceTitan-moat surfaces (Pricebook Pro depth, Equipment + Warranty, polished Dispatch composite) without re-implementing them per vertical app.
- **Eden Biz fuel SKU** can credibly compete in the commercial / fleet-fueling segment (fuel-card payment), match Otodata / Tank-Utility's dealer-portal table-stakes (fleet map), make Routific / OptimoRoute optimization value visible (before / after diff), and close the per-delivery audit trail (variance card).
- **Cross-vertical reuse** spans salon (service catalog reuse for PriceBook), medical home-visit (DispatchPage), and any route-driven vertical (route optimization + variance).

These widgets are mid-layer composites — they stack on existing primitives from obj 001 (Wave A scaffolds, currency, address, intake form), obj 004 (EdenScheduler swimlane + drag), obj 005 (EdenTankGauge, EdenRouteStopList, EdenFuelPriceTicker, EdenTruckInventoryCard), obj 007 (EdenLocationMapPage, EdenCheckInPage, EdenPhotoCapturePage), and obj 012 (EdenLineItemEditor, EdenPaymentEntry, EdenSplitTender, EdenAggregateKpiStrip). Per `eden-libs/CLAUDE.md`: "Keep platform logic in `eden-platform-flutter`, not in `eden-ui-flutter`." Library remains transport-agnostic.

## Why now

- **Trades + fuel are launch-adjacent.** Per `USE_CASES_TRADES_2026-05-17.md` §7.5, the trades vertical is at 100% must-launch coverage but flagged 4 BLOCKED items (UC-32 EquipmentRecord, UC-39 WarrantyClaim, UC-58 Commissions, UC-67 Workflow). This objective closes UC-32 + UC-39 (Rec #9) directly, and ships the dispatch composite (Rec #2) + price-book builder (Rec #1) that the launch-readiness 8-week sprint identifies as the top priorities. Per `USE_CASES_FUEL_2026-05-17.md` §6.6 ship-sequence: Recs #1 (FuelCardPayment), #2 (TankFleetMap), #3 (RouteOptimization), #4 (DeliveryVariance) are explicitly called out as "land first" — gating the commercial / fleet-fueling segment + dealer-portal table-stakes.
- **Foundations are GREEN.** Wave A primitives (obj 001), companion shell (obj 002), Phase 1 donations (obj 003), EdenScheduler enhancement (obj 004), B-Fuel components (obj 005), B-Trades field/companion (obj 007), Commerce primitives (obj 012) are all GREEN. The 7 widgets in scope here are compositions on top of a stable substrate — no new foundation work.
- **Cross-vertical reuse is genuine, not aspirational.** Per use-case docs cross-vertical column:
  - `EdenPriceBookBuilder` → trades flat-rate pricing + salon service catalog + fuel-type pricing tier.
  - `EdenDispatchPage` → trades crew dispatch + fuel multi-truck routing + medical home-visit dispatch (per obj 005 OBJECTIVE.md `EdenRouteStopList` cross-vertical note).
  - `EdenRouteOptimizationResult` → fuel route building + trades multi-stop tech day.
  - `EdenDeliveryVarianceCard` → fuel scheduled-vs-actual gallons + trades scheduled-vs-actual labor hours.
  - `EdenEquipmentRecordCard` + `EdenWarrantyClaim` → trades HVAC / plumbing equipment lifecycle + fuel customer-tank warranty (cross-pollinates with obj 005 `EdenTankGauge`).
  - `EdenFuelCardPaymentEntry` + `EdenTankFleetMap` → fuel-specific but built on cross-vertical `EdenPaymentEntry` (obj 012) + `EdenMapPreview` (obj 001).
- **Trades + fuel parallel launch unlock.** Per `USE_CASES_TRADES_2026-05-17.md` §7.6 recommended sequencing: dispatch composite (wk 1-2) → price book pack (wk 2-3) → equipment + warranty (wk 4-5). Per `USE_CASES_FUEL_2026-05-17.md` §6.6: fuel-card + variance (wk 1-2) → fleet-map (wk 3-4) → route-optimization (wk 5-6). This objective lands the launch-blocking subset of both critical paths in 3-4 weeks of parallel Claude execution.

## Components in scope (7 TRDs)

| TRD | Component | Vertical leverage | Composes | Donor / Origin |
|---|---|---|---|---|
| 019-01 | `EdenPriceBookBuilder` | Trades + salon + fuel | `EdenLineItemEditor` (obj 012), `EdenDataTable.dense`, `EdenFormWizard`, `EdenCurrencyDisplay`, `EdenStatusBadge` | New design — ServiceTitan Pricebook Pro / FieldEdge good-better-best informs shape; no donor (per use-case docs, no library widget today) |
| 019-02 | `EdenEquipmentRecordCard` + `EdenWarrantyClaim` | Trades (HVAC/plumbing) + fuel (customer-tank) | `EdenTimeline`, `EdenDescriptionList`, `EdenCertificateCard`, `EdenStatusBadge`, `EdenFormWizard`, `EdenPhotoCapturePage` (obj 007), `EdenSignaturePad` | New design — ServiceTitan's flagship moat; per use-case docs, the singular highest-leverage trades gap |
| 019-03 | `EdenDispatchPage` (composite) | Trades + fuel + medical home-visit | `EdenSchedulerSwimlaneView` (obj 004-09), `EdenMapPreview` (obj 001-15), `EdenListPageScaffold` (obj 001-01), `EdenRouteStopList` (obj 005-02), `EdenAiPanel` (obj 003-11) | Composite — wraps existing primitives into the canonical dispatch screen |
| 019-04 | `EdenFuelCardPaymentEntry` | Fuel (commercial / fleet) | `EdenPaymentEntry` (obj 012-03), `EdenSecretField`, `EdenInput`, `EdenFormWizard` | New design — FleetCor / Wex / Voyager / EFS ISO-8583-extension prompt shape |
| 019-05 | `EdenTankFleetMap` | Fuel (dealer-portal table stakes) | `EdenMapPreview` (obj 001-15), `EdenMapView` (existing), `EdenTankGauge` (obj 005-01), `EdenListPageScaffold` (obj 001-01), `EdenStockLevelIndicator` (obj 003-04) | New design — Otodata Nee-Vo + Tank Utility dealer dashboard inspire shape |
| 019-06 | `EdenRouteOptimizationResult` | Fuel + trades route planning | `EdenRouteStopList` (obj 005-02), `EdenDiffViewer` (existing), `EdenProgressRing`, `EdenStatCard`, `EdenAggregateKpiStrip` (obj 012-02) | New design — Routific / OptimoRoute before / after visualization |
| 019-07 | `EdenDeliveryVarianceCard` | Fuel + trades scheduled-vs-actual | `EdenStatCard`, `EdenSelect`, `EdenAlert`, `EdenInput`, `EdenCurrencyDisplay` (obj 001-04), `EdenMeterReadingEntry` (obj 005-03) | New design — codifies the per-delivery variance reconciliation pattern |

## Wave structure

| Wave | TRDs | Theme | Parallelism |
|---|---|---|---|
| **1** — Cross-vertical primitives | 019-01, 019-03, 019-06, 019-07 | PriceBookBuilder + DispatchPage + RouteOptimizationResult + DeliveryVarianceCard | All 4 run parallel; no shared files except `lib/eden_ui.dart` (co-modified, orchestrator serializes within wave) and the dev catalog screens (each TRD owns its own catalog section append; orchestrator serializes within wave) |
| **2** — Trades equipment + fuel ops | 019-02, 019-04, 019-05 | EquipmentRecord + WarrantyClaim + FuelCardPayment + TankFleetMap | All 3 run parallel; no cross-dependencies; Wave 1 primitives are not preconditions (these widgets compose obj 001/004/005/007/012 primitives only) |

**Why this wave structure (and NOT all-7-parallel):**
- Wave 1 primitives are the simplest compositions (no new value-class hierarchies beyond what's already in obj 012 / obj 005).
- Wave 2 widgets are denser: 019-02 composes 2 sub-widgets (record card + claim wizard), 019-04 has the FleetCor / Wex / Voyager prompt-flow complexity, 019-05 has the map-clustering + severity-marker algorithm. Staggering keeps the dev-catalog screen edits clean (Wave 1 lands its sections first, Wave 2 appends below).
- **No genuine technical dependency between waves.** Splitting is purely a context-budget + screen-edit-coordination concern. If executor capacity is high, both waves can overlap.

**File-collision discipline:**
- `lib/eden_ui.dart` — every TRD appends 1-2 export lines under section headers `// Objective 019 — Trades polish + Fuel quick wins Wave N`. Mark each TRD `co_modified_files: [lib/eden_ui.dart]` so the orchestrator serializes the edit step within a wave.
- `lib/dev_app/screens/trades_screen.dart` (existing) — TRDs 019-01, 019-02, 019-03 append `Section(...)` entries. Mark `co_modified_files: [lib/dev_app/screens/trades_screen.dart]`.
- `lib/dev_app/screens/fuel_screen.dart` (existing, bootstrapped by obj 005-01) — TRDs 019-03 (cross-vertical), 019-04, 019-05, 019-06, 019-07 append `Section(...)` entries. Mark `co_modified_files: [lib/dev_app/screens/fuel_screen.dart]`.
- `lib/dev_app/screens/home_screen.dart` — NOT modified (`trades_screen` + `fuel_screen` already registered by prior objectives).

## Constraints (locked, do not revisit)

1. **TDD strict (Iron Law) + test-list-first.** Every testable task carries `tdd="true"`. Test-list checklist at the top of every TRD enumerating happy / edge / failure cases BEFORE any test code. **Hand-built fixture builders only (no LLM-generated test data)** — `no_llm_test_data` constraint active. Fixture files named `test/widgets/_fixtures/eden_{component}_fixtures.dart` with header line 1: `// Do NOT regenerate via LLM — hand-built fixtures for Eden{Component}.`. One test at a time through RED → GREEN → REFACTOR. Per `~/.claude/CLAUDE.md` TDD Playbook habits 1-4.
2. **Outside-in for UI.** Per `~/.claude/CLAUDE.md` Playbook habit 5: start at the highest user-observable layer and drill in. Each widget TRD: static rendering tests first (renders required slots), then interaction tests (drag, callback fires, mode switch), then helper / utility unit tests.
3. **Test pattern locked.** `testWidgets('renders ...', (tester) async {...})` with `wrap()` helper at the top of each test file. Mirror `test/widgets/eden_line_item_editor_test.dart` (closest comparable composite). Widget tests, NOT integration tests.
4. **Transport-agnostic.** No `dio` / `http` / `connectrpc` / `geolocator` / `image_picker` / `camera_awesome` / `flutter_riverpod` / `routific_sdk` / `optimoroute_sdk` / `fleetcor_sdk` / `tank_utility_sdk` / `otodata_sdk`. All side-effecting capabilities (route optimization API, fuel-card auth, telemetry feeds, map providers, camera / GPS) come in as **CALLBACKS or value-typed props from the consumer**. Library renders the UX; consumer wires the platform.
5. **Generic types — don't bind to specific verticals where genuinely cross-vertical.** Per use-case docs cross-vertical column:
   - `EdenPriceBookBuilder` accepts `EdenPriceBookData` (categories + items + price overrides + tax matrix) — works for trades flat-rate, salon service catalog, fuel-type pricing.
   - `EdenDispatchPage` accepts `EdenDispatchData` (scheduler + crew swimlane + work-queue + optional map slot) — works for trades, fuel, medical home-visit.
   - `EdenRouteOptimizationResult` accepts `EdenRouteOptimizationData` (before / after stops, miles delta, capacity util) — works for any multi-stop route.
   - `EdenDeliveryVarianceCard` accepts `EdenDeliveryVarianceData` (scheduled vs actual scalar + reason + threshold) — works for fuel gallons, trades labor hours, medical visit duration.
   - `EdenEquipmentRecordCard` accepts `EdenEquipmentRecordData` (equipment + warranty + agreement + history) — works for trades equipment AND fuel customer tank.
   - `EdenWarrantyClaim` accepts `EdenWarrantyClaimDraft` (equipment ref + part + failure description + photos) — works for any warranty filing.
   - `EdenFuelCardPaymentEntry` is fuel-card-specific (FleetCor / Wex / Voyager / EFS) — generic over network via `EdenFuelCardNetwork` enum, but the prompt structure IS fuel-card-specific. This is intentional per use-case docs Rec #1 ("the ONLY widget-shaped capability gap with competitive consequences").
   - `EdenTankFleetMap` is fuel-specific in name but generic in shape — accepts `EdenFleetMapData` (markers + severity + clustering + sidebar). Could equally render a chemical-storage fleet, a water-utility fleet, an HVAC unit fleet. Naming follows the canonical use-case (fuel) per Rec #2.
6. **Theme-profile aware.** All widgets read `Theme.of(context).extension<EdenStatusPalette>()` (obj 009) for status colors with `EdenColors` fallback when the extension is null (consumer hasn't wrapped in `EdenAdaptiveTheme`). Composes cleanly with `EdenThemeProfile.commercialWarm` (trades default) / `.medicalInstitutional` / `.govFederal` / `.retailVibrant` / `.legalNavy` per obj 009 §3.1.
7. **iPhone-narrow safe (≥390pt).** Every TRD's test list includes a responsive test at 390pt logical width with no `RenderFlex overflowed` warnings. Composites that are inherently desktop-shaped (`EdenDispatchPage`, `EdenTankFleetMap`) collapse to single-zone tabbed mode below 1024pt per the obj 014-01 `EdenPOSRegisterScaffold` precedent.
8. **Material 3 + tokens.** Use `EdenSpacing`, `EdenRadii`, `EdenColors`, `EdenTypography` from `lib/src/tokens/`. No third-party widget libs except those already in `pubspec.yaml` (`google_fonts`, `highlight`, `flutter_highlight`, `showcaseview`, `qr_flutter`).
9. **No new pubspec deps.** Photo capture, GPS, route-optimization API, fuel-card network auth — all come in via consumer callbacks. No `image_picker`, no `geolocator`, no network SDKs.
10. **No breaking changes to existing widgets.** All ~230+ widget exports + ~1000+ tests must continue to pass. This objective is purely additive to the public surface (`lib/eden_ui.dart`).
11. **Visual catalog entry per component.** Every TRD that adds a publicly-exported widget appends a `Section(...)` to the appropriate dev catalog screen (`trades_screen.dart` or `fuel_screen.dart`). No new top-level catalog screens — both are pre-existing.
12. **Anti-pattern constraints (resolver-enforced):**
    - `no_llm_test_data` — Fixture builders hand-built (header line locked, no opt-out).
    - `no_property_based_default` — No `rapid` / `gopter` / `fast_check` style libraries. Descriptive `testWidgets('...')` names carry the meaning.
    - `no_gherkin_layer` — No `.feature` files, no Cucumber. Descriptive test names only.

## Success criteria (must-haves, observable truths)

1. All 7 TRDs ship; `flutter analyze` clean; `flutter test` passes (existing ~1000+ tests still pass + ~80-120 new tests pass).
2. **`EdenPriceBookBuilder`** ships a 4-section composite (Categories tree + Items per category + Price overrides per customer-tier + Tax matrix per jurisdiction). Categories support drag-reorder + nested children (1 level deep — flat-rate trades pricebooks don't need deeper). Items compose `EdenLineItemEditor` (obj 012) for the item-row editing. Customer-tier pricing exposes a slot for per-tier override input. Tax matrix is a `EdenDataTable.dense` grid (jurisdictions × item-types). Good-better-best tier presentation is rendered via 3-column `Row` at >=900pt collapsing to vertical stack at <900pt. Emits `EdenPriceBookDraft` on save callback.
3. **`EdenEquipmentRecordCard` + `EdenWarrantyClaim`** ship as paired widgets in ONE TRD (per use-case Rec #9). RecordCard composes equipment metadata (`EdenDescriptionList`), service history (`EdenTimeline` from `eden_timeline.dart`), warranty status (`EdenCertificateCard` + days-remaining countdown), agreement status pill (`EdenMembershipTierBadge`), photo gallery (composes existing `eden_photo_gallery`). WarrantyClaim is a 3-step `EdenFormWizard` (Equipment & Part selection → Failure description + Photos → Review & Submit) emitting `EdenWarrantyClaimDraft`. Both work for trades equipment (HVAC compressor) AND fuel customer tanks (regulator, line, pressure-relief valve).
4. **`EdenDispatchPage` composite** ships as a composite widget that arranges 4 named slots: scheduler swimlane (composes `EdenSchedulerSwimlaneView` from obj 004-09), crew swimlane sidebar (composes `EdenListPageScaffold` with crew avatars + status), open work-queue drag-source (drag from queue onto scheduler), map slot (optional — composes consumer-supplied `EdenMapPreview` widget OR no-op placeholder). 3-zone Row at >=1280pt; 2-zone (scheduler + queue) at >=1024pt; tabbed single-zone at <1024pt. Drag-from-queue-to-scheduler wiring is callback-based (`onDispatchAssignment(workId, crewId, slot)`).
5. **`EdenFuelCardPaymentEntry`** ships with `EdenFuelCardNetwork` enum (`fleetCor`, `wex`, `voyager`, `efs`, `generic`). Form steps per network: card swipe / manual entry (PAN via `EdenSecretField.classified`) → required prompts (driver ID, vehicle ID, odometer, trip number, custom prompt label / value pairs — network-specific) → amount entry (composes `EdenPaymentEntry` from obj 012-03) → confirmation. Emits `EdenFuelCardPaymentDraft` on submit. Network-prompt-shape definitions are declarative (`EdenFuelCardPromptSpec` value classes) so consumer can extend.
6. **`EdenTankFleetMap`** ships a clustered map view with severity-tinted markers (full=green, warning=amber, critical=red, stale-telemetry=neutral-with-pulse). Zoom-aware clustering (markers within 50px screen-distance combine into cluster pin with count badge). Sidebar list (composes `EdenListPageScaffold`) synced to map viewport bounds — pan/zoom updates the list filter. Multi-select via long-press → emits `onMultiSelect(List<tankId>)`. Map provider is pluggable via `EdenMapProvider` (obj 001-03 interface) — NoOpMapProvider degrades to placeholder grid view per Wave A pattern.
7. **`EdenRouteOptimizationResult`** ships a 2-row + 1-strip layout: Top strip = `EdenAggregateKpiStrip` (obj 012-02) with 4 KPIs (total stops Δ, total miles Δ, total time Δ, capacity utilization %). Two rows = side-by-side `EdenRouteStopList` (before) and `EdenRouteStopList` (after) at >=900pt collapsing to vertical stack at <900pt. Per-truck capacity utilization bar (composes `EdenProgressRing` per truck). Infeasible-stop badge marks stops violating time windows. Emits `onAccept()` / `onReject()` callbacks.
8. **`EdenDeliveryVarianceCard`** ships a side-by-side scheduled-vs-actual layout with variance %, threshold band visualization (color shifts when variance > threshold), reason picker (`EdenSelect` with `EdenDeliveryVarianceReason` enum), optional photo attachment (composes existing `eden_photo_gallery`), optional note (`EdenInput`), driver / office disposition pill. Configurable variance type (gallons / hours / minutes / fee) via `EdenVarianceMetric` enum. Emits `EdenDeliveryVarianceDraft`.
9. **Hand-built fixtures with locked header line.** Every fixture file under `test/widgets/_fixtures/eden_{component}_fixtures.dart` has line 1: `// Do NOT regenerate via LLM — hand-built fixtures for Eden{Component}.`. Verified by `grep -L 'Do NOT regenerate' test/widgets/_fixtures/eden_price_book_*.dart test/widgets/_fixtures/eden_equipment_*.dart test/widgets/_fixtures/eden_warranty_*.dart test/widgets/_fixtures/eden_dispatch_*.dart test/widgets/_fixtures/eden_fuel_card_*.dart test/widgets/_fixtures/eden_tank_fleet_*.dart test/widgets/_fixtures/eden_route_optimization_*.dart test/widgets/_fixtures/eden_delivery_variance_*.dart` returning empty.
10. **Dev catalog entries.**
    - `lib/dev_app/screens/trades_screen.dart` appended with PriceBookBuilder + EquipmentRecord+Warranty + DispatchPage sections (3 new sections).
    - `lib/dev_app/screens/fuel_screen.dart` appended with DispatchPage (cross-vertical demo) + FuelCardPayment + TankFleetMap + RouteOptimizationResult + DeliveryVarianceCard sections (5 new sections).
    - `just dev-ui` → all 7 components render with sample data.
11. **Exports section.** `lib/eden_ui.dart` has `// Objective 019 — Trades polish + Fuel quick wins Wave 1` and `// Objective 019 — Trades polish + Fuel quick wins Wave 2` section headers with 1-2 export lines each per TRD.
12. **Backward compat — no regressions.** `flutter test` runs all ~1000+ existing tests successfully. No public API changes to any existing widget. New widgets are purely additive.
13. **iPhone-narrow safe** — every TRD's test list includes a `SizedBox(width: 390)` test asserting no `RenderFlex overflowed` warnings. Composites (`EdenPriceBookBuilder`, `EdenDispatchPage`, `EdenTankFleetMap`, `EdenRouteOptimizationResult`) collapse to single-zone tabbed mode at narrow widths.
14. **No new pubspec deps.** `pubspec.yaml` unchanged across all 7 TRDs. Verified by `git diff pubspec.yaml` returning empty after objective completes.
15. **Roadmap updated:** objective 019 added to Active Objectives with TRD checklist (all `[ ]`).

## Out of scope (deferred or skipped)

- **Real route optimization algorithms.** `EdenRouteOptimizationResult` renders the BEFORE / AFTER diff — the optimization itself is a Routific / OptimoRoute backend integration deferred to `eden-biz/go/.planning/objectives/110-fuel-routing-real`. Library accepts a `EdenRouteOptimizationData` value class with both routes already computed.
- **Real fuel-card network authorization.** `EdenFuelCardPaymentEntry` collects the form data; the actual ISO-8583 swipe + network round-trip happens in the consumer's backend (or a fuel-card vendor SDK like Comdata / WEX merchant API). Library emits `EdenFuelCardPaymentDraft` for the consumer to wire.
- **Real telemetry feeds.** `EdenTankFleetMap` renders markers from `List<EdenFleetMapMarker>` the consumer supplies. Telemetry polling / WebSocket / push from Otodata / Tank Utility / Anova is the consumer's job. Per obj 005 OBJECTIVE.md constraint 4: "Live data sources are CALLBACK parameters."
- **Pricebook versioning + audit trail.** v1 is single-version. Multi-version diff / approval workflow / restore-from-history is deferred. Per obj 012-01 pattern, the editor emits a snapshot; the consumer persists with version metadata.
- **Pricebook Pro features.** Convex / dynamic pricing / surge pricing logic ServiceTitan ships in Pricebook Pro is OUT of scope. v1 = flat-rate + good-better-best tier columns + customer-tier overrides. Sub-features like client-specific overrides at the item level (rather than tier level), promotional pricing windows, kit pricing — all v2.
- **Equipment OCR nameplate scanning.** Per `USE_CASES_TRADES_2026-05-17.md` BLOCKED item #4: `EdenNameplateScanner` capture-and-confirm UX is NOT in this objective. Defers to future objective; this one focuses on the RECORD itself (post-creation), not the scan-to-create flow.
- **Warranty manufacturer-portal submission.** `EdenWarrantyClaim` emits a draft; the actual mfr-portal submission (Trane / Goodman / Carrier API / portal scrape) is the consumer's job.
- **Workflow automation builder (UC-67).** Per use-case docs BLOCKED #1: `EdenWorkflowDesigner` rides obj 006-a4a Process Canvas + a follow-on A4-b port. Out of scope here.
- **Commissions rules editor (UC-58).** Per use-case docs BLOCKED #5: future objective.
- **Conditional-form-builder for ops (UC-13 template authoring).** Per use-case docs BLOCKED #2: future objective; field execution exists (`eden_inspection_form_page` obj 007-01), template authoring doesn't.
- **Service-agreement composite (Rec #7).** Per `USE_CASES_TRADES_2026-05-17.md` §7.6 week 3-4: `EdenServiceAgreementCard` + `EdenRecurringBillingWidget` + `EdenAgreementRenewalPipeline` is a SEPARATE 3-widget pack. Not bundled here to keep scope tight.
- **Lead-source tag picker + ROI chart (Rec #4).** Small effort, low priority vs the launch-blocking subset shipped here.
- **Financing offer card (Rec #10).** Small effort, table-stakes parity. Future objective.
- **Telemetry-pair card (`EdenTelemetryPairCard`, fuel Rec #5).** Onboarding friction widget — deferred to future objective.
- **Projected-depletion strip (`EdenProjectedDepletionStrip`, fuel Rec #6).** Mini-widget for customer portal — deferred.
- **Stop insertion preview (`EdenStopInsertionPreview`, fuel Rec #7).** Mid-day urgent-stop insertion modal — deferred.
- **Fuel tax breakdown row (`EdenFuelTaxBreakdownRow`, fuel Rec #8).** Codified content pattern — deferred.
- **Degree-day overlay (`EdenDegreeDayOverlay`, fuel Rec #9).** Heating-oil-segment-only V2.
- **Credential dashboard (`EdenCredentialDashboard`, fuel Rec #10).** Composes from existing — V2.
- **Real-device iOS / Android testing.** Downstream apps gate this.
- **Visual regression baselines.** VRT-01 v2 future objective.

## References

**Primary inspirations (use-case docs):**
- `.planning/USE_CASES_TRADES_2026-05-17.md` Recs #1, #2, #9 (PriceBookBuilder, DispatchPage, EquipmentRecord + WarrantyClaim)
- `.planning/USE_CASES_FUEL_2026-05-17.md` Recs #1, #2, #3, #4 (FuelCardPayment, TankFleetMap, RouteOptimizationResult, DeliveryVarianceCard)

**Foundation objectives consumed:**
- `objectives/001-wave-a-cross-vertical-fundamentals/` — Wave A scaffolds (`EdenListPageScaffold`, `EdenDetailPageScaffold`), `EdenCurrencyDisplay`, `EdenAddressInput`, `EdenMapPreview`, `EdenMapProvider` interface, `EdenIntakeForm`, `EdenFormWizard`, `EdenConsentFlow`
- `objectives/002-companion-shell-foundation/` — `EdenAdaptiveLayout`, `EdenAdaptiveTierScope` for Compact pinning
- `objectives/003-phase-1-widget-donations/` — `EdenStockLevelIndicator`, `EdenCertificateCard`, `EdenAiPanel` (optional slot in DispatchPage)
- `objectives/004-eden-scheduler-enhancement/` — `EdenSchedulerSwimlaneView` (obj 004-09), `EdenSchedulerEventBlock` drag-to-reschedule (obj 004-10) for DispatchPage
- `objectives/005-b-fuel-components/` — `EdenTankGauge` (obj 005-01), `EdenRouteStopList` (obj 005-02), `EdenMeterReadingEntry` (obj 005-03), `EdenFuelPriceTicker` (obj 005-05), `EdenTruckInventoryCard` (obj 005-06)
- `objectives/007-b-trades-a-field-companion/` — `EdenCheckInPage` (obj 007-05), `EdenLocationMapPage` (obj 007-06), `EdenPhotoCapturePage` (obj 007-04)
- `objectives/012-cross-vertical-commerce-primitives/` — `EdenLineItemEditor` (obj 012-01), `EdenAggregateKpiStrip` (obj 012-02), `EdenPaymentEntry` (obj 012-03), `EdenSplitTender` (obj 012-04)

**Library context:**
- `.planning/PROJECT.md` (transport-agnostic constraint, test pattern, iPhone-narrow ≥390pt baseline)
- `eden-libs/CLAUDE.md` ("Keep platform logic in `eden-platform-flutter`, not in `eden-ui-flutter`")
- `~/.claude/CLAUDE.md` TDD Playbook (global — strict TDD + test-list-first + hand-built fixtures + outside-in for UI + one test at a time)

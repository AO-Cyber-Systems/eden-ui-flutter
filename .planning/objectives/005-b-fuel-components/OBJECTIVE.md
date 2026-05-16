---
objective: 005-b-fuel-components
kind: ui-lib
work: feature
status: planned
estimated_effort: 2-3 weeks Claude execution
trd_count: 6
waves: 3
---

# Objective 005 — B-Fuel Components: Fuel-delivery vertical primitives

## Goal

Ship the 6 generic UI primitives that fuel-delivery downstream apps (`eden-biz-flutter` fuel admin + companion driver app) compose to render the fuel-delivery domain. Generic = the widgets don't bind to fuel domain entities — consumers map their domain (`fuel_tanks`, `fuel_deliveries`, `delivery_routes`, `meter_readings`, `truck_inventories`, `fuel_prices`, `hazmat_documents`) to library value classes (`EdenTankGaugeData`, `EdenRouteStopData`, etc.). After this objective ships:

- A fuel-delivery driver app renders a tank's current vs capacity with a configurable mode (linear/segmented/dial) using `EdenTankGauge`.
- A dispatcher renders an ordered list of route stops with drag-reorder + ETA + status badges using `EdenRouteStopList`.
- A driver captures a meter reading (gallons + photo + source + audit metadata) using `EdenMeterReadingEntry` — composing `EdenAuthenticatedImage` for signed-URL photo display.
- A driver/admin reviews a DOT manifest + MSDS overlay + cert pill using `EdenHazmatDocViewer` — composing `EdenAttachmentPreview` for the underlying file rendering.
- A forefront/dashboard renders a real-time price ticker with delta-since-yesterday using `EdenFuelPriceTicker` — composing `EdenCurrencyDisplay`.
- A fleet detail page renders a per-truck capacity + current load + fuel-type card using `EdenTruckInventoryCard` — composing `EdenStockLevelIndicator`.

These widgets are the lowest-layer fuel-domain primitives. **Backend codegen, transport, and orchestration belong in `eden-biz-flutter` / `eden-platform-flutter`, not here.** Per `eden-libs/CLAUDE.md`: "Keep platform logic in `eden-platform-flutter`, not in `eden-ui-flutter`."

## Why now

- **Backend foundation landing in parallel.** `eden-biz/go/.planning/objectives/100-fuel-delivery-foundation/OBJECTIVE.md` builds the 9-table schema + Connect RPCs (TankService, DeliveryService, RouteService, FuelPriceService) that drive these widgets. Backend ships proto + Go handler + dart codegen; this objective ships the widgets that consume the codegen at the next layer up.
- **Pattern proven across objectives 001-004.** 67 widgets across 4 objectives shipped on the same `wrap()` test pattern, hand-built fixtures, dev catalog, exports section. TDD discipline, fixture builders, outside-in for UI — all proven.
- **Compose existing primitives.** Of the 6 widgets, 4 compose existing eden-ui-flutter primitives (`EdenAuthenticatedImage`, `EdenAttachmentPreview`, `EdenCurrencyDisplay`, `EdenStockLevelIndicator`) rather than building from scratch — keeps surface area small + leverages prior work.
- **Cross-vertical reuse beyond fuel.** Several widgets are genuinely cross-vertical:
  - `EdenTankGauge` → any liquid/quantity gauge (water utilities, chemical storage, fertilizer tanks, beverage stock).
  - `EdenRouteStopList` → any ordered-stop sequence (medical home-visits, delivery routes, courier dispatch, sales call sequences).
  - `EdenMeterReadingEntry` → any photo-backed measurement (utility meter reads, inventory counts, spot inspections).
  - `EdenHazmatDocViewer` → any document-with-overlay-cert viewer (insurance certs, OSHA cards, contractor licenses).
  - `EdenFuelPriceTicker` → any market-price ticker (commodities, metals, electricity spot prices).
  - `EdenTruckInventoryCard` → any vehicle-capacity card (delivery vans, service trucks, tanker capacity).
- **B-trades pattern continues.** Per `TRADES_REMAP_DEEP_AUDIT_2026-05-15.md` §5, the "B-{vertical} components" wave-structure is the right shape for per-vertical library primitives. Trades, salon, medical, gov, retail follow the same pattern.

## Components in scope

| ID | Component | Composes | Donor / Source |
|---|---|---|---|
| 005-01 | `EdenTankGauge` | none (primitive) | New — fuel domain (no Flutter or React donor available) |
| 005-02 | `EdenRouteStopList` | uses `EdenAddress` value type | `trades/client/src/pages/Map.tsx` (1098 LOC) + `DispatchMap.tsx` (384 LOC) as secondary inspiration; Flutter `ReorderableListView` as primary mechanism |
| 005-03 | `EdenMeterReadingEntry` | `EdenAuthenticatedImage` | New — composes existing primitives |
| 005-04 | `EdenHazmatDocViewer` | `EdenAttachmentPreview` + `EdenAttachment` | New — domain-shaped wrapper |
| 005-05 | `EdenFuelPriceTicker` | `EdenCurrencyDisplay` | New — generic market-tile pattern (no trades-react fuel price tile exists; confirmed via grep) |
| 005-06 | `EdenTruckInventoryCard` | `EdenStockLevelIndicator` | `trades-flutter/lib/features/fleet/presentation/widgets/truck_inventory_section.dart` (Flutter port — Riverpod-stripped, made generic) |

## Wave structure

| Wave | TRDs | Theme | Parallelism |
|---|---|---|---|
| **1** | 005-01, 005-02 | Independent primitives — TankGauge + RouteStopList | Both run parallel; no shared files except `lib/eden_ui.dart` export-line append (`co_modified_files` discipline) |
| **2** | 005-03, 005-04 | Composing widgets — MeterReadingEntry + HazmatDocViewer | Both run parallel; depend on existing primitives (`EdenAuthenticatedImage`, `EdenAttachmentPreview`); no Wave-1 dependency |
| **3** | 005-05, 005-06 | Small primitives — FuelPriceTicker + TruckInventoryCard | Both run parallel; depend on existing primitives (`EdenCurrencyDisplay`, `EdenStockLevelIndicator`); no Wave-1/2 dependency |

**File-collision discipline:**
- `lib/eden_ui.dart` — every TRD appends 1 export line under a NEW section header per wave (`// Objective 005 — B-Fuel components Wave N`). Mark each TRD `co_modified_files: [lib/eden_ui.dart]` so the orchestrator serializes the edit step within a wave.
- **Dev catalog landing:** new file `lib/dev_app/screens/fuel_screen.dart` is created in TRD 005-01 (Wave 1 first TRD), then extended by subsequent TRDs. Each TRD appends one or two Section(...) entries. Mark `co_modified_files: [lib/dev_app/screens/fuel_screen.dart]` from TRD 005-02 onward so the orchestrator serializes within a wave. Decision rationale: 6 fuel widgets earn their own screen (density justifies it) rather than scattering across `data_display_screen.dart` + `misc_screen.dart`; mirrors the `companion_screen.dart` + `scheduler_screen.dart` per-objective screen pattern from obj 002 + 004.
- `lib/dev_app/screens/home_screen.dart` — register the `FuelScreen` `_Category` entry once in TRD 005-01 with full subtitle ("Tank gauge, route stops, meter readings, hazmat docs, price ticker, truck inventory"). Later TRDs do NOT modify `home_screen.dart`.

## Constraints (locked, do not revisit)

1. **TDD strict (Iron Law) + test-list-first.** Every TRD's testable tasks carry `tdd="true"`. Test-list checklist at the top of every TRD enumerating happy/edge/failure cases BEFORE any test code. **Hand-built fixture builders only (no LLM-generated test data)** — `no_llm_test_data` constraint active. Fixture files named `test/widgets/_fixtures/eden_{component}_fixtures.dart` with header `// Do NOT regenerate via LLM — hand-built fixtures for Eden{Component}.`. One test at a time through RED → GREEN → REFACTOR. Per `~/.claude/CLAUDE.md` TDD Playbook habits 1-4.
2. **Outside-in for UI.** Per `~/.claude/CLAUDE.md` Playbook habit 5: start at the highest user-observable layer and drill in. Each widget TRD: static rendering tests first (renders title, renders capacity %), then interaction tests (drag-to-reorder, photo-pick callback, mode-switch), then helper/utility unit tests (clamping math, percent-to-color thresholds).
3. **Test pattern locked.** `testWidgets('renders ...', (tester) async {...})` with `wrap()` helper at the top of each test file. Mirror `test/widgets/eden_alert_test.dart`. Widget tests, NOT integration tests.
4. **Transport-agnostic.** No `dio`/`http`/`connectrpc`/`grpc`/`tank_telemetry_sdk`/`fuel_price_feed_sdk`. Live data sources are CALLBACK parameters on the widget — consumer supplies a `Stream<EdenFuelPriceData>?` or polls and calls `setState` themselves. The library never opens a socket.
5. **Material 3 + tokens.** Use `EdenSpacing`, `EdenRadii`, `EdenColors`, `EdenTypography` from `lib/src/tokens/`. Color thresholds (low/medium/high tank fill — green/amber/red) map to `EdenColors.success` / `.warning` / `.danger`; thresholds are configurable.
6. **iPhone-narrow safe (≥390pt).** Every TRD's test list includes a responsive test at 390pt logical width with no `RenderFlex overflowed` warnings. For compositions like `EdenRouteStopList` which can have variable-length stop content, use `Flexible` / `Expanded` + `TextOverflow.ellipsis` patterns.
7. **Compact pinning per locked decision E (rule 3).** Where a widget has Compact / Medium / Expanded variants (`EdenTankGauge` is the only one in this objective with mode-aware density — linear vs segmented vs dial), the widget exposes a `mode: EdenTankGaugeMode` constructor parameter AND respects `EdenAdaptiveTierScope.maybeOf(context)` if present to auto-select the compact variant in companion-mode contexts. Match the obj 002-05 `EdenCompanionShell` pattern: an explicit `mode:` parameter overrides; in its absence, `EdenAdaptiveTierScope.maybeOf(context) == EdenAdaptiveTier.compact` selects the compact variant; default fallback is the linear (medium-density) variant.
8. **Generic types — don't bind to fuel domain.** Every component takes a generic data class as input:
   - `EdenTankGauge` accepts `EdenTankGaugeData(capacityGal: 500, currentGal: 320, lowThresholdPct: 0.20)` — consumer maps `fuel_tanks` rows to this. No `Tank` entity, no `propane` enum.
   - `EdenRouteStopList` accepts `List<EdenRouteStopData>` — generic id + sequence + label + status + ETA + optional EdenAddress. Consumer maps `delivery_route_stops` rows to this.
   - `EdenMeterReadingEntry` emits `EdenMeterReadingDraft(gallons, photoSignedUrl?, source, timestamp, auditMetadata)` — consumer persists via their own RPC.
   - `EdenHazmatDocViewer` accepts `EdenHazmatDocData(manifestAttachment, msdsAttachment?, driverCertLabel?, certIsValid: bool)` — consumer maps `hazmat_documents` rows + `users` cert state.
   - `EdenFuelPriceTicker` accepts `EdenFuelPriceData(currentCents, priorCents, currency, fuelTypeLabel, asOf)` — consumer maps `fuel_prices` rows + per-tenant settings.
   - `EdenTruckInventoryCard` accepts `EdenTruckInventoryData(truckLabel, fuelTypeLabel, capacityGal, currentGal)` — consumer maps `truck_inventories` rows.
9. **No new pubspec deps.** Default: `flutter/material.dart` + `dart:ui` + `dart:math` + existing eden-ui-flutter primitives only. If a TRD needs a new dep, justify in `<context>` and ADD it. No `intl`, no `provider`, no `riverpod`, no `flutter_polyline_points`, no `flutter_local_notifications`. Photo capture comes from a CALLBACK parameter (`onPhotoPick`); consumer wires a camera plugin in their app.
10. **No breaking changes to existing widgets.** Existing 67 widget exports + ~600+ tests must continue to pass. This objective is purely additive to the public surface (`lib/eden_ui.dart`).
11. **Visual catalog entry per component.** Every TRD that adds a publicly-exported widget appends a Section(...) to `lib/dev_app/screens/fuel_screen.dart`. TRD 005-01 creates the file with the TankGauge demo; subsequent TRDs append sections.
12. **Anti-pattern constraints (resolver-enforced):**
    - `no_llm_test_data` — Fixture builders hand-built (header line locked, no opt-out).
    - `no_property_based_default` — No `rapid`/`gopter`/`fast_check` style libraries. Descriptive `testWidgets('...')` names carry the meaning.
    - `no_gherkin_layer` — No `.feature` files, no Cucumber. Descriptive test names only.

## Success criteria (must-haves, observable truths)

1. All 6 TRDs ship; `flutter analyze` clean; `flutter test` passes (existing ~600+ tests still pass + ~60-90 new fuel-widget tests pass).
2. **`EdenTankGauge` renders 3 modes:** linear (default), segmented (5 segments visualizing 20%/40%/60%/80%/100% thresholds), dial (semicircle gauge with needle). Mode-aware: auto-selects linear in Compact context per `EdenAdaptiveTierScope`; explicit `mode:` parameter overrides. Low-threshold visual cue: container border turns red when `currentGal / capacityGal <= lowThresholdPct`. Hand-built fixtures cover empty (0%), low (<20%), normal (60%), full (100%), overfull (>100% — clamped to 100% with overflow indicator badge).
3. **`EdenRouteStopList` renders ordered stops + drag-reorder + ETA + status badges.** Uses Flutter `ReorderableListView`. On reorder, `onReorder(oldIndex, newIndex)` callback fires; on stop tap, `onStopTap(stopId)` fires; on status badge tap, `onStatusTap(stopId)` fires. Composes `EdenAddress` value type from the stop's address. Variable-length stop labels truncate with ellipsis at iPhone-narrow widths.
4. **`EdenMeterReadingEntry` captures gallons + photo + source + timestamp + audit metadata.** Number input field with `decimalRange` validation (positive, max 4-decimal precision per `eden-biz` fuel-delivery convention). Photo capture is a callback parameter (`onPhotoPick: () => Future<String?> /* returns S3 key */`) — consumer wires the camera plugin. Composes `EdenAuthenticatedImage(signedUrl: ...)` to preview the captured photo. Source picker is a `Radio<EdenMeterReadingSource>` group: manual / telemetry / customerReported. Timestamp defaults to `DateTime.now()`; user can override. Audit metadata fields: `operatorId` (required), `notes` (optional). Form emits `EdenMeterReadingDraft` on `onSubmit` callback.
5. **`EdenHazmatDocViewer` shows DOT manifest + MSDS overlay + driver-cert pill in read-only v1.** Manifest is the primary panel (composes `EdenAttachmentPreview(attachment: data.manifestAttachment)`). MSDS toggles in as a modal sheet overlay on tap of an "MSDS" button (composes `EdenAttachmentPreview(attachment: data.msdsAttachment)` if non-null). Driver-cert pill renders at the top with cert label + valid/expired/expiring-soon visual state. **Signature flow deferred to v2** — there is NO signature capture in this widget. Read-only viewer.
6. **`EdenFuelPriceTicker` shows current price + delta-since-prior + as-of timestamp.** Composes `EdenCurrencyDisplay(centsMinor: data.currentCents, currency: data.currency)` for the price. Delta is rendered as a chip with up/down arrow + colored text (green when down, red when up — since price drops favor the buyer in heating oil context; consumer can flip via `EdenFuelPriceTicker.deltaPolarity: EdenFuelPriceDeltaPolarity.lowerIsBetter | higherIsBetter`). As-of timestamp renders as a small caption ("Updated 5m ago" — use a hand-rolled `_formatRelative(DateTime)` helper; no `intl` dep). Live updates: widget is dumb — consumer passes new `data` via `setState` to refresh.
7. **`EdenTruckInventoryCard` shows truck label + fuel type + capacity + current load + fill percent.** Composes `EdenStockLevelIndicator(value: data.currentGal / data.capacityGal)`. Renders the donor `truck_inventory_section.dart` shape (header icon + 2-column item table) but generic — no `TruckInventoryItem` domain class, just `EdenTruckInventoryData` with `truckLabel + fuelTypeLabel + capacityGal + currentGal`. iPhone-narrow safe: 4-row stacked layout at <500pt, 2-column horizontal at >=500pt.
8. **Hand-built fixtures with locked header line.** Every fixture file under `test/widgets/_fixtures/eden_{component}_fixtures.dart` has line 1: `// Do NOT regenerate via LLM — hand-built fixtures for Eden{Component}.`. Verified by `grep -L 'Do NOT regenerate' test/widgets/_fixtures/eden_*fuel*.dart` returning empty.
9. **Dev catalog entry.** `lib/dev_app/screens/fuel_screen.dart` exists and is registered in `home_screen.dart` `_categories` list. `just dev-ui` → tap "B-Fuel — Vertical Components" tile → all 6 components render with sample data. Mode-switch buttons present for TankGauge.
10. **Exports section.** `lib/eden_ui.dart` has a `// Objective 005 — B-Fuel components` section with 6 export lines, one per Wave 1/2/3 sub-section.
11. **Backward compat — no regressions.** `flutter test` runs all ~600+ existing tests successfully. No public API changes to any existing widget. New widgets are purely additive.
12. **iPhone-narrow safe** — every TRD's test list includes a `SizedBox(width: 390)` test asserting no `RenderFlex overflowed` warnings.
13. **No new pubspec deps.** `pubspec.yaml` unchanged across all 6 TRDs. Verified by `git diff pubspec.yaml` returning empty after objective completes.
14. **Roadmap updated:** objective 005 added to Active Objectives with TRD checklist (all `[ ]`).

## Out of scope (deferred or skipped)

- **Hazmat signature capture flow.** v1 ships read-only viewer. Signature capture is a v2 follow-up (would compose `eden_signature_pad`). Tracked as future TRD: `005-future: EdenHazmatSignatureFlow`.
- **Tank telemetry live-data wiring.** Consumer owns the data source (callback / polling / WebSocket). The library widget re-renders when `data` prop changes.
- **Fuel price feed integration (OPIS/DTN/etc.).** Vendor selection deferred to `eden-biz/go/.planning/objectives/120-fuel-billing` — backend concern. Library shows whatever `EdenFuelPriceData` the consumer passes in.
- **Route optimization.** Library renders an ordered list with drag-reorder; computing the optimal order is `eden-biz/go/.planning/objectives/110-fuel-routing-real` (backend). Library exposes `onReorder` so the consumer can persist the new order.
- **Photo capture plugin wiring.** Camera/gallery picker is a callback parameter; consumer wires `image_picker` or `camera` package in their own app.
- **DOT compliance manifest GENERATION** (vs viewing). Generating a 4-page DOT manifest PDF from delivery data is `eden-biz/go/.planning/objectives/140-hazmat-compliance` (backend). Library only views existing PDFs/attachments.
- **Real-time WebSocket price updates.** Consumer's responsibility — widget re-renders on `setState`.
- **Multi-currency fuel pricing.** v1 single-currency-per-display. `EdenCurrencyDisplay` already handles currency formatting; ticker uses whatever currency the consumer passes.
- **Fleet-wide truck inventory grid.** `EdenTruckInventoryCard` is per-truck. A multi-truck grid is a consumer composition concern (place N cards in an `EdenDataGrid` or `Wrap`).
- **Visual regression baselines** (VRT-01 v2 future objective).
- **Real-device iOS / Android testing** (downstream apps gate this).

## References

**Primary inspirations (donors):**
- `/Users/markemerson/Source/AOCyber-Trades/trades-flutter/lib/features/fleet/presentation/widgets/truck_inventory_section.dart` — donor for 005-06 EdenTruckInventoryCard (port + generic-ize)
- `/Users/markemerson/Source/AOCyber-Trades/trades-flutter/lib/features/fleet/presentation/widgets/fleet_stat_cards.dart` — secondary inspiration for 005-06 (card layout idiom)
- `/Users/markemerson/Source/AOCyber-Trades/trades/client/src/pages/Map.tsx` (1098 LOC) — secondary inspiration for 005-02 EdenRouteStopList stop-sequence patterns
- `/Users/markemerson/Source/AOCyber-Trades/trades/client/src/components/forefront/DispatchMap.tsx` (384 LOC) — secondary inspiration for 005-02 stop-status badge patterns

**Backend domain shapes (the data widgets render):**
- `/Users/markemerson/Source/eden-biz/go/.planning/objectives/100-fuel-delivery-foundation/OBJECTIVE.md` — `Tank`, `Delivery`, `Route`, `RouteStop`, `MeterReading`, `TruckInventory`, `FuelPrice`, `HazmatDoc` shapes (NOT imported here — but documented data semantics inform the value-class shapes)

**Library context:**
- `.planning/PROJECT.md` (transport-agnostic constraint, test pattern, validation commands, iPhone-narrow ≥390pt baseline)
- `.planning/TRADES_REMAP_DEEP_AUDIT_2026-05-15.md` §5 — B-{vertical} component wave-structure pattern this objective extends to fuel
- `.planning/objectives/001-wave-a-cross-vertical-fundamentals/` — canonical TRD shape; existing `EdenAuthenticatedImage` (001-07) for 005-03 compose
- `.planning/objectives/002-companion-shell-foundation/` — `EdenAdaptiveTierScope` for 005-01 Compact pinning
- `.planning/objectives/003-phase-1-widget-donations/` — canonical TRD shape; existing `EdenStockLevelIndicator` (003-04) for 005-06 compose; existing `EdenCurrencyDisplay` for 005-05 compose
- `.planning/objectives/004-eden-scheduler-enhancement/` — canonical TRD shape; `co_modified_files` discipline for `lib/eden_ui.dart` + `lib/dev_app/screens/*.dart` serialization within a wave
- `lib/src/widgets/eden_authenticated_image.dart` (composed by 005-03)
- `lib/src/widgets/eden_attachment_preview.dart` (composed by 005-04)
- `lib/src/widgets/eden_currency_display.dart` (composed by 005-05)
- `lib/src/widgets/eden_stock_level_indicator.dart` (composed by 005-06)
- `lib/src/widgets/eden_adaptive_layout.dart` (`EdenAdaptiveTierScope.maybeOf` for 005-01 Compact pinning)
- `lib/src/widgets/map_providers/eden_map_types.dart` (`EdenAddress` value type composed by 005-02)
- `eden-libs/CLAUDE.md` ("Keep platform logic in `eden-platform-flutter`, not in `eden-ui-flutter`")
- `~/.claude/CLAUDE.md` TDD Playbook (global — strict TDD + test-list-first + hand-built fixtures + outside-in for UI + one test at a time)

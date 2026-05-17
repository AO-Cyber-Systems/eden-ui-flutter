# eden-ui-flutter — Roadmap

## Active Objectives

### Objective 001: Wave A — Cross-vertical fundamentals

**Goal:** Ship the 14 cross-vertical UI primitives + 1 pluggable-map interface that every Eden Biz vertical (salon, trades, fuel, medical, retail, legal, gov) composes its admin and companion surfaces from. See `objectives/001-wave-a-cross-vertical-fundamentals/OBJECTIVE.md`.

**TRDs:** 15 plans across 4 waves (~4-5 wk Claude execution)

TRDs:
- [x] 001-01-TRD.md — A1 EdenListPageScaffold (Wave 1; port trades-flutter)
- [x] 001-02-TRD.md — A2 EdenDetailPageScaffold + EdenDetailHeader (Wave 1; port trades-flutter)
- [x] 001-03-TRD.md — EdenMapProvider interface + value types + NoOpMapProvider (Wave 1; A4 dependency)
- [x] 001-04-TRD.md — A3 EdenCurrencyDisplay (Wave 2; port + multi-currency enhancement)
- [x] 001-05-TRD.md — A7 EdenPhoneInput + EdenOtpInput (Wave 2)
- [x] 001-06-TRD.md — A8 EdenMembershipTierBadge (Wave 2)
- [x] 001-07-TRD.md — A12 EdenAuthenticatedImage (Wave 2; donor trades-react)
- [x] 001-08-TRD.md — A13 EdenNetworkStatusBar (Wave 2; donor trades-react)
- [x] 001-09-TRD.md — A5 EdenConsentFlow (Wave 3; composes eden_signature_pad + eden_form_wizard)
- [x] 001-10-TRD.md — A6 EdenIntakeForm (Wave 3; composes eden_form_wizard)
- [x] 001-11-TRD.md — A9 EdenRoleDashboardShell (Wave 3; depends on Wave 1 scaffolds)
- [x] 001-12-TRD.md — A10 EdenAppTourOverlay + EdenContextualTip + EdenStarterTemplateCard (Wave 3; onboarding triplet, uses showcaseview)
- [x] 001-13-TRD.md — A11 EdenOfflineQueueViewer (Wave 3; donor trades-flutter field_crew)
- [x] 001-14-TRD.md — A14 EdenQuickActionBar (Wave 3; donor trades-react)
- [x] 001-15-TRD.md — A4 EdenAddressInput + EdenMapPreview + RecordingMapProvider (Wave 4; implements TRD-03 interface)

### Objective 002: Companion Shell Foundation

**Goal:** Ship the six runtime primitives that put the locked companion-mode UX decisions (`COMPANION_UX_PATTERNS_2026-05-15.md` §0 locks A–F + `COMPANION_B2_SPEC_2026-05-15.md` §1 + §4) into code. After this objective ships, downstream `eden-platform-flutter` can compose a companion-mode app shell out of library primitives without re-implementing the hybrid mode-discrimination algorithm, the Material 3 three-tier responsive split, the mode-toggle escape hatch, the inline gate widget, or the cross-vertical GPS status indicator. See `objectives/002-companion-shell-foundation/OBJECTIVE.md`.

**TRDs:** 6 plans across 3 waves (~2-3 wk Claude execution)

TRDs:
- [x] 002-01-TRD.md — EdenAppMode enum + resolveAppMode() + EdenAppModeController + EdenAppModeScope (Wave 1; foundational hybrid mode-discrimination, Riverpod-friendly w/o riverpod dep)
- [x] 002-02-TRD.md — EdenAdaptiveLayout (Wave 1; Material 3 three-tier Compact/Medium/Expanded; forceCompact hook for lock E rule 3)
- [x] 002-03-TRD.md — EdenUxModeToggle (Wave 2; donor trades-react UXModeToggle.tsx; compact + labeled variants)
- [x] 002-04-TRD.md — EdenFieldViewGate (Wave 2; donor trades-react FieldViewGate.tsx; companionOnly + adminOnly inline gates)
- [x] 002-06-TRD.md — EdenGpsStatusIndicator (Wave 2; cross-vertical promotion per P-17 evidence; T/F/M/G verticals)
- [x] 002-05-TRD.md — EdenCompanionShell (Wave 3; composes Wave A EdenRoleDashboardShell + EdenNetworkStatusBar + TRD-01/02/03; CRITICAL lock E rule 3 enforcement at 1200pt)

### Objective 003: Phase 1 — Widget donations from trades-flutter

**Goal:** Donate 14 reusable widgets from `AOCyber-Trades/trades-flutter/lib/shared/widgets/` into eden-ui-flutter, completing Phase 1 of the trades-flutter absorption initiative (`TRADES_FLUTTER_ABSORPTION_PLAN_2026-05-15.md` §5.3). After this objective ships, every Band-1/2/3 trades-flutter feature folder absorption (absorption Phase 3) can `import 'package:eden_ui_flutter/eden_ui.dart'` instead of re-vendoring these primitives inline. Largest unblocker for the ~6-8 week Phase 3 work. See `objectives/003-phase-1-widget-donations/OBJECTIVE.md`. GitHub: AO-Cyber-Systems/eden-ui-flutter#10.

**TRDs:** 15 plans across 3 waves (~3-4 wk Claude execution)

TRDs:
- [x] 003-01-TRD.md — EdenUrgencyBadge (Wave 1; status pill, low/medium/high/critical, donor trades-flutter)
- [x] 003-02-TRD.md — EdenPipelineBadge (Wave 1; outlined pill, draft/sent/won/lost/expired + aliases, donor trades-flutter)
- [x] 003-03-TRD.md — EdenApprovalStatusBadge (Wave 1; filled pill, 10 statuses, donor trades-flutter)
- [x] 003-04-TRD.md — EdenStockLevelIndicator (Wave 1; linear bar with green/amber/red thresholds, donor trades-flutter)
- [x] 003-05-TRD.md — EdenCostSummaryCard (Wave 2; labor/material/equipment/total breakdown card, composes EdenCurrencyDisplay)
- [x] 003-06-TRD.md — EdenActivityFeedItem (Wave 2; avatar + actor/action/entity + time row; inlined data class)
- [x] 003-07-TRD.md — EdenBlockingAlerts (Wave 2; collapsible severity-colored alert list; inlined types)
- [x] 003-08-TRD.md — EdenMediaRow (Wave 2; compact icon+count+label cells, + Add buttons; inlined item class)
- [x] 003-09-TRD.md — EdenPlaceholderPage (Wave 2; coming-soon route screen + optional action button)
- [x] 003-10-TRD.md — EdenInsightCard + foundation eden_ai_models.dart (Wave 3; 6 layouts incl. CustomPainter chart; shared AI types: EdenInsightContent, EdenAiPersona, EdenChatMessage, etc.)
- [x] 003-11-TRD.md — EdenAiPanel (Wave 3; 320/40 collapsible sidebar panel; composes EdenInsightCard; depends 003-10)
- [x] 003-12-TRD.md — EdenAiCollapsibleSection (Wave 3; sparkle+title+chevron wrapper; independent)
- [x] 003-13-TRD.md — EdenPersonaSelector (Wave 3; popup-menu pill, Riverpod-stripped; depends 003-10)
- [x] 003-14-TRD.md — EdenAgentChat + EdenAgentChatFab + EdenChatMessageBubble (Wave 3; chat FAB + modal sheet; callback-driven streaming + lazy conversation creation; depends 003-10 + 003-13)
- [x] 003-15-TRD.md — EdenAiInsightSlot (Wave 3; enabled-gate around EdenAiPanel; internal/external state pattern; depends 003-10 + 003-11)

### Objective 004: EdenScheduler Enhancement — Exact Parity with trades-react Schedule

**Goal:** Bring `EdenScheduler` (current thin Material 3 month/week/day shell) to exact UX-observable feature parity with the canonical donor trades-react Schedule (`AOCyber-Trades/trades/client/src/pages/Schedule.tsx` 3140 LOC + `EnhancedCalendar.tsx` 5609 LOC + `MobileScheduleView/*` family + `TruckAvailabilityView.tsx` 1761 LOC). User direction 2026-05-16: 'Need it to be exactly feature parity.' After this objective ships, every Eden Biz vertical (trades, salon, medical, fuel, retail, legal, gov) composes a scheduler with the same gestures + drag affordances + swimlanes + mobile pinch-zoom without re-implementing any of it. See `objectives/004-eden-scheduler-enhancement/OBJECTIVE.md`.

**TRDs:** 16 plans across 4 waves (~4-6 wk Claude execution)

TRDs (all GREEN as of 2026-05-16; objective 100% complete):
- [x] 004-01-TRD.md — Models + EdenSchedulerController + back-compat preserved (Wave 1; foundational data + controller)
- [x] 004-02-TRD.md — SchedulerToolbar extension to 7 views + responsive collapse + dev catalog Scheduler screen (Wave 1)
- [x] 004-03-TRD.md — EdenSchedulerTimeMath pure-Dart helpers + recurrence expansion (Wave 1; yDeltaPxToMinutes, addMinutesToTime, formatTime, expandRecurrence)
- [x] 004-04-TRD.md — EdenSchedulerDayView with now-indicator + fullDay config (Wave 2; extracts from scheduler_week_day_views.dart)
- [x] 004-05-TRD.md — EdenSchedulerWeekView supporting workWeek + week modes + today highlight + expand-arrow (Wave 2; completes file split)
- [x] 004-06-TRD.md — EdenSchedulerMonthView overflow handling (+N more) + drill-down bottom sheet + rename (Wave 2)
- [x] 004-07-TRD.md — EdenSchedulerListView chronological date-grouped view (Wave 2)
- [x] 004-08-TRD.md — EdenSchedulerMobileView composite + tab strip + swipe-nav + pinch-zoom + ResourceChipStrip + Compact auto-route (Wave 3; depends Wave 1 + 004-10)
- [x] 004-09-TRD.md — EdenSchedulerSwimlaneView resource-as-column grid + drag-cross-resource + lane collapse (Wave 3; depends 004-10)
- [x] 004-10-TRD.md — EdenSchedulerEventBlock with drag-to-reschedule + top/bottom resize + preview chip (Wave 3; foundational for 08/09/11/12/13)
- [x] 004-11-TRD.md — EdenSchedulerAllDayRow with multi-day spanning + drag-cross-day + drag-from-hour-grid conversion (Wave 3)
- [x] 004-12-TRD.md — ConflictLayout algorithm + multi-select + ConflictBanner + SelectionBanner (Wave 3)
- [x] 004-13-TRD.md — EdenSchedulerPickMode controller + drag-to-create drafts + bottom commit bar (Wave 3)
- [x] 004-14-TRD.md — EdenSchedulerSidebar composite (mini-cal + chip-strip + density legend + toggles) + Zoom + Search + Shortcuts + Overflow (Wave 4)
- [x] 004-15-TRD.md — EdenSchedulerCreateDialog + EditDialog + DetailDialog slot-based + responsive (Wave 4)
- [x] 004-16-TRD.md — Viewport culling + layout cache + recurrence cache (Wave 4; human-verify side-by-side parity checkpoint pending)

### Objective 005: B-Fuel Components — Fuel-delivery vertical primitives

**Goal:** Ship 6 generic UI primitives that fuel-delivery downstream apps (`eden-biz-flutter` fuel admin + companion driver app) compose to render the fuel-delivery domain. Generic — widgets don't bind to fuel entities; consumers map `fuel_tanks`, `delivery_routes`, `meter_readings`, `truck_inventories`, `fuel_prices`, `hazmat_documents` to library value classes. Reuses existing primitives (`EdenAuthenticatedImage`, `EdenAttachmentPreview`, `EdenCurrencyDisplay`, `EdenStockLevelIndicator`) where possible. Cross-vertical reuse beyond fuel: water utilities (TankGauge), medical home-visits (RouteStopList), utility meter reads (MeterReadingEntry), insurance cert viewers (HazmatDocViewer), commodity tickers (FuelPriceTicker), service-truck capacity cards (TruckInventoryCard). See `objectives/005-b-fuel-components/OBJECTIVE.md`.

**TRDs:** 6 plans across 3 waves (~2-3 wk Claude execution)

TRDs:
- [ ] 005-01-TRD.md — EdenTankGauge (Wave 1; 3 modes: linear/segmented/dial via CustomPainter; Compact pinning via EdenAdaptiveTierScope; low-threshold visual cue; net-new design — no donor)
- [ ] 005-02-TRD.md — EdenRouteStopList (Wave 1; ReorderableListView with drag-reorder + ETA + status badges + EdenAddress preview; Flutter newIndex quirk hidden from consumers)
- [ ] 005-03-TRD.md — EdenMeterReadingEntry (Wave 2; gallons + photo + source + timestamp + audit form; composes EdenAuthenticatedImage; emits EdenMeterReadingDraft)
- [ ] 005-04-TRD.md — EdenHazmatDocViewer (Wave 2; DOT manifest + MSDS modal sheet + driver-cert pill; composes EdenAttachmentPreview; read-only v1, signature flow deferred)
- [ ] 005-05-TRD.md — EdenFuelPriceTicker (Wave 3; current + delta + as-of; composes EdenCurrencyDisplay; configurable delta polarity; hand-rolled relative-time formatter)
- [ ] 005-06-TRD.md — EdenTruckInventoryCard (Wave 3; truck + fuel-type + capacity + fill bar; composes EdenStockLevelIndicator; donor trades-flutter truck_inventory_section.dart)

### Objective 006: A4-a — Visual Process Canvas Port from trades-react

**Goal:** Port the trades-react Visual Process Builder (`AOCyber-Trades/trades/client/src/components/customizations/processes/visual-builder/` — 21 files, 3819 LOC) into eden-ui-flutter as a generic, vertical-agnostic, transport-agnostic process-builder primitive. After this objective ships, every Eden Biz vertical (trades, salon, medical, fuel, retail, legal, gov) composes a process builder with the same node grammar (Start / End / Phase / TaskGroup / Task / Decision / Orphan), drag-from-toolbox UX, context-menu editing, swimlane + free-form layout engines, and bidirectional model-to-canvas sync — without re-implementing any of it. EXTENDS the existing `eden_diagram/` sub-suite (process builder is the second consumer; system diagrams was the first). See `objectives/006-a4a-visual-process-canvas/OBJECTIVE.md`. Locked decisions: deep-audit §7 (process builder generic + registry-driven entity types + both swimlane/free-form layouts).

**TRDs:** 15 plans across 5 waves (~4 wk Claude execution)

TRDs:
- [ ] 006-01-TRD.md — Value types + EdenProcessEntityTypeRegistry + EdenProcessRuntimeComponentRegistry + EdenDiagramPort additive (Wave 1; foundation; parity rows R-1/R-2/E-5/L-5)
- [ ] 006-02-TRD.md — eden_diagram engine extensions: drop-target hit-test API + customNodeRenderer + multi-handle port honor (Wave 1; parity rows D-1/D-2/E-5)
- [ ] 006-03-TRD.md — EdenProcessGraphBuilder + EdenProcessController + EdenProcessLayoutEngine abstract + edge style helper (Wave 1; parity rows S-1..S-5/E-1/E-2)
- [ ] 006-04-TRD.md — EdenProcessStartNode + EdenProcessEndNode + EdenProcessOrphanNode + EdenProcessNodeRenderer.dispatch (Wave 2; parity rows N-1/N-2/N-7)
- [ ] 006-05-TRD.md — EdenProcessPhaseNode with 8-color palette + expand/collapse + milestone Flag + drop-target ring + inline rename (Wave 2; parity row N-3)
- [ ] 006-06-TRD.md — EdenProcessTaskGroupNode with inline task list + 4 toggle dots + workflow-hooks Zap + drag-target for split (Wave 2; parity rows N-4/D-6)
- [ ] 006-07-TRD.md — EdenProcessTaskNode + EdenProcessDecisionNode + graph builder 4-port emission for decisions (Wave 2; parity rows N-5/N-6)
- [ ] 006-08-TRD.md — EdenSwimlaneLayout real algorithm (replaces TRD 03 stub; donor applySwimLaneLayout port; DEFAULT layout per Mark) (Wave 3; parity row L-1)
- [ ] 006-09-TRD.md — EdenFreeFormLayout (BFS-rank, no Dagre dep) + EdenGridLayout + EdenLinearLayout (Wave 3; parity rows L-2/L-3)
- [ ] 006-10-TRD.md — EdenProcessPhaseEditorDialog + TaskGroupEditorDialog + TaskEditorDialog (Wave 4; parity rows X-1/X-2/X-3)
- [ ] 006-11-TRD.md — EdenNodeContextMenu (with generic action API + submenu) + EdenEdgeContextMenu (Wave 4; parity rows C-1/C-2/C-3/C-4)
- [ ] 006-12-TRD.md — EdenProcessToolbox with Draggable<EdenProcessDragPayload> + click-fallback + templates section + recommended sort (Wave 4; parity rows T-1/T-2/T-3)
- [ ] 006-13-TRD.md — EdenProcessValidator + EdenProcessValidationResult (pure-function port of donor validateProcess) (Wave 5; parity rows V-1/V-2)
- [ ] 006-14-TRD.md — EdenVisualProcessCanvas composite root (composes everything from Waves 1-4) + EdenProcessValidationPanel + EdenDiagram.hitTestEdge additive (Wave 5; parity rows D-3/D-4/D-5/L-4/V-3 wiring)
- [ ] 006-15-TRD.md — Dev catalog ProcessBuilderScreen + home_screen nav tile + integration smoke test + human-verify side-by-side parity checkpoint vs trades-react (Wave 5; closes objective)

### Objective 007: B-Trades-A — Field/Companion Pages (cross-vertical)

**Goal:** Ship the 8 cross-vertical companion-mode page composites per `TRADES_REMAP_DEEP_AUDIT_2026-05-15.md` §5 B-trades-A. Full-page compositions (NOT shells) that drop into an `EdenCompanionShell` (objective 002) content slot: inspection-form-with-photos-and-signature, full-screen signature/photo capture flows, GPS clock-in/out with map confirm, full-bleed location map view, truck-load packout checklist, mobile launcher grid, AI FAB + bottom-sheet chat. After this objective ships, downstream `eden-platform-flutter` + any companion-mode vertical app (trades-hvac, medical home-visit, fuel-truck driver, gov caseworker site visits) compose a field-crew companion surface from library primitives. Library remains transport-agnostic (callbacks for camera/GPS/persistence/network/signature acquisition); no new pubspec deps. See `objectives/007-b-trades-a-field-companion/OBJECTIVE.md`.

**TRDs:** 8 plans across 4 waves (~2-3 wk Claude execution)

TRDs:
- [ ] 007-07-TRD.md — EdenMobileQuickAccessGrid (Wave 1; icon-tile launcher with optional reorder; bootstraps `lib/dev_app/screens/field_screen.dart` + Obj-007 export section + home_screen.dart category)
- [ ] 007-08-TRD.md — EdenMobileAiFab + EdenMobileAiChatSheet + EdenMobileAiQuickAction (Wave 1; bottom-sheet AI chat variant — pairs with obj-003 EdenAgentChatFab full-screen modal; composes EdenAgentChat or re-implements stream loop per Option A/B decision)
- [ ] 007-05-TRD.md — EdenCheckInPage + 4 value types (Wave 2; GPS clock-in/out page; composes EdenGpsStatusIndicator from obj-002 + EdenCard/EdenDescriptionList/EdenBadge; 3-state action area: CheckIn | CheckOut | Complete)
- [ ] 007-06-TRD.md — EdenLocationMapPage + EdenLocationPin + v1 clustering (Wave 2; full-bleed 3:2 map+list split; composes EdenMapPreview from Wave A + provider-agnostic; battery dot indicator inline)
- [ ] 007-02-TRD.md — EdenSignatureCapturePage + EdenSignatureCaptureResult (Wave 3; full-screen signature flow composing existing EdenSignaturePad; returns List<EdenSignatureStroke> via Navigator.pop)
- [ ] 007-04-TRD.md — EdenPhotoCapturePage + 3 value types (Wave 3; black-chrome full-screen capture with annotation overlay + optional categories; consumer wires camera via onCapture/onPickFromGallery callbacks)
- [ ] 007-01-TRD.md — EdenInspectionFormPage + 4 value types + 8 field renderers (Wave 4; flagship multi-section form with progress + draft save + submit gating + photo/signature callback bridges)
- [ ] 007-03-TRD.md — EdenPackoutPage + EdenPackoutItem + EdenPackoutEdit (Wave 4; truck-load checklist with per-item Loaded/Used/Returned + expand-to-edit + parallel save support)

### Objective 008: Dev Catalog Enrichment — Make Existing 52 Components Demo as Completely as They Test

**Goal:** Enrich the live Flutter dev catalog (`lib/dev_app/screens/`) so the 52 components shipped across objectives 001/002/003/004 demo as completely as they test. Today's catalog makes the library look thinner than it is — 1041 tests pass but most components have 1-5 minimal demos with generic data. After this objective ships: every screen shows default + realistic-populated + edge + responsive + interactive states drawing on a shared cross-vertical sample-data library (trades / salon / fuel / medical / gov). Includes the side-by-side trades-react PNG embeds for EdenScheduler closing the objective-004 human-verify parity checkpoint. **Catalog-content objective — no component public APIs change.** See `objectives/008-dev-catalog-enrichment/OBJECTIVE.md`.

**TRDs:** 9 plans across 5 waves (~2-3 wk Claude execution)

TRDs (9/9 GREEN — 2026-05-16):
- [x] 008-01-TRD.md — Cross-vertical sample-data library `lib/dev_app/_sample_data/` (trades/salon/fuel/medical/gov scenarios + cross-cutting customers/staff/inventory) (Wave 1)
- [x] 008-02-TRD.md — `layouts_screen.dart` enrichment — EdenListPageScaffold + EdenDetailPageScaffold cross-vertical realistic list/detail demos (Wave 2)
- [x] 008-03-TRD.md — `data_display_screen.dart` enrichment — EdenStatCard 5 vertical KPI grids + EdenDataTable realistic tables + EdenCostSummaryCard / EdenActivityFeedItem / EdenMediaRow / EdenStockLevelIndicator (Wave 2)
- [x] 008-04-TRD.md — `inputs_screen.dart` + `misc_screen.dart` — EdenPhoneInput 8-country grid + EdenOtpInput length/state variants + EdenAddressInput 5 verticals + EdenNetworkStatusBar lifecycle + EdenOfflineQueueViewer + EdenAuthenticatedImage (Wave 2)
- [x] 008-05-TRD.md — `companion_screen.dart` — 5 vertical-flavor full shells (trades dispatch / salon front-desk / fuel driver / medical home-visit / gov caseworker) + realistic GPS coords + vertical-content gate demos + tier-aware EdenAdaptiveLayout demo (Wave 3)
- [x] 008-06-TRD.md — NEW `composers_screen.dart` — EdenConsentFlow / EdenIntakeForm / EdenRoleDashboardShell / EdenAppTourOverlay + EdenContextualTip + EdenStarterTemplateCard cross-vertical (Wave 3)
- [x] 008-07-TRD.md — `badges_alerts_screen.dart` — EdenUrgencyBadge / EdenPipelineBadge / EdenApprovalStatusBadge / EdenBlockingAlerts / EdenMembershipTierBadge realistic cross-vertical contexts (Wave 4)
- [x] 008-08-TRD.md — `chat_screen.dart` AI surface — EdenInsightCard 6 layouts × cross-vertical + EdenAiPanel persona-keyed insights + EdenAiCollapsibleSection / EdenPersonaSelector / EdenAgentChat per-vertical streaming presets / EdenAiInsightSlot (Wave 4)
- [x] 008-09-TRD.md — `scheduler_screen.dart` HEADLINE — side-by-side trades-react PNG embeds (5 view modes) + 50+ event live perf demo + cross-vertical scheduler scenarios (trades/salon/medical/fuel/gov) + pubspec.yaml asset registration (Wave 5)

### Objective 009: Vertical Theme System + Brand Preset Registry

**Goal:** Ship the foundational theme infrastructure that lets eden-ui-flutter present 5 distinct aesthetic profiles (commercial / medical / gov / retail / legal) and per-tenant brand color overrides without changing a single line of consumer widget code. After this objective ships, downstream `eden-biz-flutter` and other Eden Flutter apps wrap their MaterialApp in `EdenAdaptiveTheme(profile: ..., brand: ..., child: ...)` and the entire 230+ widget catalog renders in the chosen aesthetic. The current `EdenTheme.light()/dark()` API continues to work unchanged — new profiles are strictly opt-in. Per `VERTICAL_UX_RESEARCH_2026-05-16.md` §2.4 + §3.1: single highest-leverage step in the eden-ui-flutter roadmap, unlocks all 7 verticals on the existing shell + 230+ component catalog. Required precursor to medical (Obj 013) and gov-compliance (Obj 011) downstream work. See `objectives/009-vertical-theme-system/OBJECTIVE.md`.

**TRDs:** 5 plans across 3 waves (~2-3 wk Claude execution)

TRDs:
- [ ] 009-01-TRD.md — EdenThemeProfile enum (5 locked profiles) + EdenThemeProfileData immutable value class + EdenThemeProfileScope InheritedWidget; pure data + context, no Material wiring (Wave 1; foundation)
- [ ] 009-02-TRD.md — EdenStatusPalette ThemeExtension<EdenStatusPalette> with 5 semantic × 3 facet color fields per profile + EdenTheme.light/dark extended to attach extension; back-compat anchor commercialWarm reproduces today's EdenColors values exactly (Wave 1; depends 009-01)
- [ ] 009-03-TRD.md — EdenBrandPreset value class + EdenBrandPresetRegistry with 15 ship-with presets (7 bridges from EdenColors.presets + 8 vertically-flavored: salon-coral / trades-industrial-blue / medical-teal / fuel-energy-orange / gov-federal-navy / legal-navy / retail-vibrant-magenta / wellness-sage) (Wave 2; parallel with 009-04)
- [ ] 009-04-TRD.md — EdenProfileFonts static resolver: per-profile body/display/mono TextStyle helpers using existing google_fonts ^6.1.0 (IBM Plex Sans medical, Public Sans gov, Crimson Pro legal); zero new pubspec deps (Wave 2; parallel with 009-03)
- [ ] 009-05-TRD.md — EdenAdaptiveTheme StatelessWidget + EdenAdaptiveTheme.light/dark static factories composing 009-01..04 + profile-aware TextTheme overlay + theme_profiles_screen.dart visual catalog showing all 5 profiles side-by-side with sample triptychs + home_screen nav tile (Wave 3; capstone)

### Objective 010: Eden Visual Polish Pass — Material 3 Expressive + Density Adjustments + Animation Token Library

**Goal:** Absorb the 5 Material 3 Expressive (May 2025) patterns Eden lags on (button group, split button, FAB menu, loading indicator, spring-physics motion), close the dense-enterprise data-table gap vs Polaris/Carbon/USWDS/Square POS, and ship a hand-rolled spring-physics animation token library (EdenSprings) that future Eden widgets compose from. All additive — every existing widget continues to work unchanged. Per `VERTICAL_UX_RESEARCH_2026-05-16.md` §3.2 + §2.1 + §2.2 + §6 aesthetic-preservation principles. Depends on objective 009 (Vertical Theme System) for full profile-aware density tokens + status palette; degrades gracefully when 009 not yet shipped. See `objectives/010-visual-polish-pass/OBJECTIVE.md`.

**TRDs:** 10 plans across 3 waves (~2 wk Claude execution)

TRDs:
- [ ] 010-01-TRD.md — EdenSprings token class — hand-rolled spring physics, 4 presets (snap/smooth/bouncy/rubber) + simulationFor + curveFor helpers (Wave 1; foundation; TRDs 02-10 all consume EdenSprings)
- [ ] 010-02-TRD.md — EdenButtonGroup — M3 Expressive connected pill cluster, 2-6 buttons, shape-morph on press (Wave 2; M3 Expressive batch)
- [ ] 010-03-TRD.md — EdenSplitButton — primary action + dropdown menu, Save/Save & New form-flow pattern (Wave 2; M3 Expressive batch)
- [ ] 010-04-TRD.md — EdenFabMenu — expandable FAB with 2-6 action children, spring unfurl with stagger, scrim close; sibling (NOT replacement) of EdenMobileAiFab (Wave 2; M3 Expressive batch)
- [ ] 010-05-TRD.md — EdenLoadingIndicator — M3 Expressive shape-morph + shimmer + crossFade variants; EdenSpinner + EdenSkeleton preserved (Wave 2; M3 Expressive batch)
- [ ] 010-06-TRD.md — EdenDataTable.dense — 32pt rows + sticky header + freeze-pane col 1 + bulk-select; closes biggest competitive gap vs Polaris/Carbon/Square POS/Epic chart screens (Wave 3; density)
- [ ] 010-07-TRD.md — EdenCard.interactive — hover lift + focus ring + 44pt min tap target + onLongPress (Wave 3; polish)
- [ ] 010-08-TRD.md — EdenSkeletonScope — Stack+Opacity cross-fade wrapper (Hero/Focus preserving); composes EdenSkeleton (Wave 3; polish)
- [ ] 010-09-TRD.md — EdenEmptyState enhancement — illustration slot + secondary action with responsive primary/secondary layout (Wave 3; polish)
- [ ] 010-10-TRD.md — EdenStatusDotOverlay — composable status dot + count badge overlay (online/offline/away/busy/sync/unread+count); sibling of EdenAvatar.status (Wave 3; polish)

### Objective 011: Compliance Overlay Primitives — Wave C Government + USWDS Conformance + Civilian Re-use

**Goal:** Ship the Wave C compliance overlay set — 14 primitives (6 net-new + 4 enhancements to existing widgets + 4 USWDS conformance) — that gate DHHS/DOD vertical opt-in AND carry civilian re-use across HIPAA / SOC 2 / PCI / attorney-privilege use cases. Per locked decision C in `COMPANION_UX_PATTERNS_2026-05-15.md` §0: build gov-first NOW, expose to commercial as opt-in. Every Wave C primitive exposes a generic-enough API for commercial verticals (e.g., `EdenClassificationBanner` works as `EdenSensitivityBanner` for commercial CRM with custom labels; `EdenAuditLogViewer` works as activity log for any vertical). Enhancements (`EdenSecretField`, `EdenFileUpload`, `EdenPermissionMatrix`) are strictly additive — every existing call site works unchanged. Library remains transport-agnostic + no new pubspec deps; platform-channel work (CAC/PIV smartcard, hardware token) is interface-only in library with consumer apps providing platform impl. Per `VERTICAL_UX_RESEARCH_2026-05-16.md` §3.3 + §4 + parent `VERTICAL_COVERAGE_ASSESSMENT_2026-05-15.md` §3 Wave C. Obj 009 (theme system) dependency is advisory only — TRDs plan against local `_govFederalColors` stub that obj 009 follow-up patches replace with `EdenThemeProfile.govFederal` reads. See `objectives/011-compliance-overlay-primitives/OBJECTIVE.md`.

**TRDs:** 14 plans across 5 waves (~3-4 wk Claude execution)

TRDs:
- [ ] 011-01-TRD.md — EdenClassificationBanner + EdenClassificationBannerScaffold + EdenSensitivityBanner typedef (Wave 1; foundation — bootstraps compliance_screen.dart + home_screen tile; civilian re-use via custom level)
- [ ] 011-11-TRD.md — EdenUSWDSBanner with en/es language toggle + custom govLabel (Wave 1; bootstraps uswds_screen.dart + home_screen tile; USWDS v3.13 spec)
- [ ] 011-12-TRD.md — EdenAgencyIdentifier + EdenAgencyIdentity + EdenAgencyContactLink (Wave 1; header + footer layouts; depends 011-11 for uswds_screen APPEND order)
- [ ] 011-02-TRD.md — EdenCacPivButton + EdenCacPivController + 5-state machine (idle/reading/promptPin/authenticating/error) (Wave 2; smartcard auth affordance, interface-only — consumer wires platform channel; composes EdenSecretField for PIN entry)
- [ ] 011-10-TRD.md — EdenMfaHardwareToken (YubiKey / RSA SecurID / CAC backup) (Wave 2; depends 011-02 for compliance_screen APPEND order; composes EdenOtpInput from obj 001-05)
- [ ] 011-08-TRD.md — Enhance EdenSecretField with classified clipboardMode + paste-from-outside warning (Wave 3; additive constructor params; backwards-compat baseline gated)
- [ ] 011-09-TRD.md — Enhance EdenFileUpload with 4 new EdenUploadStatus values (virusScanning / virusScanFailed / cuiMarked / quarantined) + additive EdenUploadFile fields (Wave 3; depends 011-08 for compliance_screen APPEND order)
- [ ] 011-13-TRD.md — EdenMemorableDate USWDS-conformant M/D/Y 3-field input + per-field validation + composite validation + responsive layout (Wave 3; depends 011-12 for uswds_screen APPEND order)
- [ ] 011-14-TRD.md — EdenLanguageSelector + EdenLanguageOption + EdenLanguageOptions.usFederalDefault (en/es/zh/vi/ko/ru/ar per EO 13166 + Census Bureau) (Wave 3; depends 011-13 for uswds_screen APPEND order)
- [ ] 011-03-TRD.md — EdenSection508Audit dev-tools overlay + EdenSection508Issue + EdenSection508AuditController + filter chips (Wave 4; UI surface only — consumer populates issues; depends 011-10 for compliance_screen APPEND order)
- [ ] 011-04-TRD.md — EdenAuditLogViewer + EdenAuditLogEntry + hash-chain + failed-action indicators + filters (Wave 4; depends 011-03 for compliance_screen APPEND order; consumed by 011-06 Wave 5)
- [ ] 011-07-TRD.md — Enhance EdenPermissionMatrix with EdenFederalRoles (Privileged User / ISSO / ISSM) + break-glass mode + justification dialog (Wave 4; additive; depends 011-04 for compliance_screen APPEND order)
- [ ] 011-05-TRD.md — EdenFoiaRequestCard + EdenFoiaRequest + due-date pill (4 urgency tiers) + redaction status + FOIA exemption codes (Wave 5; depends 011-07 for compliance_screen APPEND order; composes 011-01 ClassificationBannerScaffold)
- [ ] 011-06-TRD.md — EdenCaseFileShell — 6-tab regulated dossier (Overview/Activity/Documents/Contacts/Notes/Audit) + privileged note inline banner + classification overlay (Wave 5; CAPSTONE; composes 011-01 + 011-04; depends 011-05 for compliance_screen APPEND order)

### Objective 013: B-Medical Clinical Primitives

**Goal:** Ship the 9 medical-vertical-specific primitives that unblock all 5 medical screens (per `VERTICAL_WIREFRAMES_VALIDATION_2026-05-17.md` §3.1 medical section: 4/5 BLOCKED, 1 PARTIAL today). After this objective ships, downstream `eden-biz-flutter` medical apps compose a Patient Chart + Visit Encounter surface from library widgets without re-implementing clinical density, HIPAA overlay wiring, FHIR-shape value mapping, or three-pane chart layout. Wave 1 atomic primitives (vitals row, medication list, lab result table, problem list, allergy list) run parallel; Wave 2 composers (SOAP note, chart timeline) parallel; Wave 3 page-shell capstones (patient chart scaffold, visit encounter scaffold) sequential. Per locked decision C in `COMPANION_UX_PATTERNS_2026-05-15.md` §0: PHI handling reuses obj 011 compliance overlay (`EdenAuditLogViewer` composes into chart side-rail). Per locked decision F: AI surface stays callback-driven (`aiInsightSlot` slots throughout). Depends on **obj 012 cross-vertical commerce primitives** (`EdenLineItemEditor` for claim/visit, `EdenSparkline` for lab trends, `EdenAggregateKpiStrip` for KPI rows) — obj 013 plans against obj 012 API shape; executor wires when obj 012 lands, else graceful fallback. Also depends on **obj 009** (`EdenThemeProfile.medicalInstitutional` + `EdenStatusPalette` already shipped) and **obj 011** (`EdenAuditLogViewer`). Library remains transport-agnostic; no Epic/Cerner/athenahealth API binding; no new pubspec deps. See `objectives/013-b-medical-clinical-primitives/OBJECTIVE.md`.

**TRDs:** 9 plans across 3 waves (~2-3 wk Claude execution)

TRDs:
- [ ] 013-01-TRD.md — EdenVitalsRow — BP/HR/Temp/SpO2/RR/Weight/BMI strip with trend arrows + reference-range coloring; HIPAA isolation assertion (Wave 1; FOUNDATION — bootstraps medical_screen.dart + home_screen tile + eden_ui.dart Wave 1 export section)
- [ ] 013-02-TRD.md — EdenMedicationList — FHIR-shape MedicationStatement display with drug/dose/route/frequency/prescriber + interaction-flag badge + refill state + discontinue toggle (Wave 1; depends 013-01 for medical_screen file-create)
- [ ] 013-03-TRD.md — EdenLabResultTable — flag column (H/L/HH/LL) + inline trend sparkline (composes obj 012-07 EdenSparkline; graceful fallback to numeric delta) + panel grouping (CBC/CMP/Lipid) + sortable columns (Wave 1; depends 013-01)
- [ ] 013-04-TRD.md — EdenProblemList — FHIR-shape Condition (ICD-10) with onset/status pill (active/recurrence/resolved/inactive) + verification status (provisional/refuted) + showResolved toggle (Wave 1; depends 013-01)
- [ ] 013-05-TRD.md — EdenAllergyList — FHIR-shape AllergyIntolerance with severity pill + type icon prefix + NON-DISMISSIBLE criticality banner (HIPAA cannot-miss UX) + NKDA empty state (Wave 1; depends 013-01)
- [ ] 013-06-TRD.md — EdenSOAPNote — 4-section composer (Subjective/Objective/Assessment/Plan) per locked decision F template-slot API; consumer plugs in templates + voice + AI panel + signature pad via slot params; view mode shows signed state (Wave 2; depends 013-01)
- [ ] 013-07-TRD.md — EdenChartTimeline — vertical clinical timeline composing EdenActivityFeedItem (obj 003-06) with severity tinting + category filter chips + multi-year quarterly compression + aiInsightSlot (locked decision F) (Wave 2; depends 013-01)
- [ ] 013-08-TRD.md — EdenPatientChartScaffold — CAPSTONE three-pane shell (left rail problems/meds/allergies · center tabbed chart · right rail alerts/audit/AI) composing all of Wave 1 + Wave 2 + EdenAuditLogViewer (obj 011) + EdenDetailHeader (obj 001); tier-responsive (Expanded/Medium/Compact); per-collection HIPAA bleed-isolation assertions (Wave 3; depends 013-01..013-07)
- [ ] 013-09-TRD.md — EdenVisitEncounterScaffold — during-appointment workflow composing EdenWorkflowStepper (5 steps: Chief Complaint/Vitals/SOAP/Orders+Rx/Sign-off) + EdenSOAPNote (013-06) + EdenLineItemEditor (obj 012-01; graceful fallback to EdenForm) + EdenConsentFlow (obj 001-09) + EdenBlockingAlerts persistent right rail (Wave 3; depends 013-06 + 013-08)

## v2 Future Objectives

Tracked but not in current scope:

- **VRT-01** — Visual regression baselines for all `eden_*_test.dart` widgets at iPhone-narrow + iPad-portrait + desktop widths. Defer until Eden visual identity stabilizes enough that pixel-diffs aren't constant noise.
- **XPL-01** — Cross-platform render gates in CI for all 6 supported platforms (iOS, Android, macOS, Windows, Linux, web).
- **MAP-GOOGLE-01** — Sibling package `eden_ui_flutter_map_googlemaps` shipping Google Maps reference impl of `EdenMapProvider`. Follow-up after Objective 001 closes.
- **MAP-MAPLIBRE-01** — Sibling package `eden_ui_flutter_map_maplibre` shipping MapLibre + self-hosted tiles + Pelias geocoding impl. Gated by DHHS/DOD vertical opt-in.

## Quick Tasks Tracker

See `STATE.md` § "Quick Tasks Completed" + commit log on `main` for shipped fixes. RESP-XX requirements (responsive layout — `EdenPageHeader` iPhone-narrow Wrap fix etc.) are addressed via quick tasks until they accumulate into a broader responsive-design objective.

## Triage Heuristic

| Work shape | Tool |
|---|---|
| Single-line fix, 1 file, <30 LOC | `/devflow:micro` |
| 1-5 files, <200 LOC, no architectural decisions | `/devflow:quick` |
| Multi-file capability with research / verification needs | `/devflow:plan-objective <N>` (full objective) |
| Net-new widget component with design + a11y + tests | `/devflow:plan-objective <N>` |

When in doubt, start with `/devflow:quick`; promote to a full objective only if scope clearly spans it.

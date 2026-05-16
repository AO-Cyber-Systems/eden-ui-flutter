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

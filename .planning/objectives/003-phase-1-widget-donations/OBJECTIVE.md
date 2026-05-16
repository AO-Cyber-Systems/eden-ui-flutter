---
objective: 003-phase-1-widget-donations
kind: ui-lib
work: feature
status: planned
estimated_effort: 3-4 weeks Claude execution
trd_count: 15
waves: 3
github_issue: "AO-Cyber-Systems/eden-ui-flutter#10"
---

# Objective 003 — Phase 1: Widget Donations from trades-flutter

## Goal

Donate 14 reusable widgets from `AOCyber-Trades/trades-flutter/lib/shared/widgets/` into `eden-ui-flutter`, completing Phase 1 of the trades-flutter absorption initiative (`TRADES_FLUTTER_ABSORPTION_PLAN_2026-05-15.md` §5.3).

After this objective ships, every Band-1 / Band-2 / Band-3 trades-flutter feature folder absorption (Phase 3 of the absorption plan) can `import 'package:eden_ui_flutter/eden_ui.dart'` instead of re-vendoring these primitives inline. **This is the single largest unblocker for the ~6-8 week Phase 3 work.**

## Why now

- **Phase 1 unchanged status** locked in `ABSORPTION_RESEARCH_2026-05-15.md` (2026-05-15) — the 16 widget donations don't depend on Q5/Q1/Q2 research outcomes; they ship in parallel.
- **Wave A (obj 001) + Companion Shell (obj 002) GREEN.** 21 widgets + ~445 tests already shipped on the same TDD discipline. Patterns are proven; cadence is known.
- **trades-flutter `feature/multi-model-adaptive` is frozen reference** through Phase 3 absorption (Q11 lock). The donor files are stable; no chasing moving targets.
- **AI suite (W17/W18/W20) is blocked on widgets being in the library** (absorption plan §4.4 + §4.7 cascading dependency). Phase 1 unblocks the AI feature folders too.

## Scope (14 components, classified by absorption plan §5.3 + deep audit §4 donor map)

**Already donated before this objective (skip; for cross-reference):**
- `currency_display` → `EdenCurrencyDisplay` (001-04)
- `list_page_scaffold` → `EdenListPageScaffold` (001-01)
- `detail_view_scaffold` + `detail_header` → `EdenDetailPageScaffold` + `EdenDetailHeader` (001-02)
- `gps_status_indicator` → `EdenGpsStatusIndicator` (002-06)
- `offline_banner`, `offline_queue_badge` → `EdenOfflineQueueViewer` (001-13)
- Generic primitives (`empty_state`, `status_badge`, `notification_badge`, `progress_bar`, `loading_indicator`, `loading_skeleton`, `search_bar_field`, `entity_card`, `entity_data_table`, `checklist_tile`, `kpi_card`, `export_button`, `filter_chips`, `status_filter_pills`, `responsive_tabs`, `create_edit_dialog`, `crud_action_buttons`, `stat_card_row`, `error_view`) are already covered by existing eden-ui-flutter widgets (`EdenEmptyState`, `EdenStatusBadge`, `EdenStatCard`, `EdenSearchInput`, `EdenChip`, `EdenSegmentedControl`, `EdenTabs`, `EdenCard`, `EdenDataTable`, `EdenTaskList`, `EdenSpinner`, `EdenSkeleton`, `EdenProgress`, `EdenErrorPage`, etc.) — or are biz-coupled (CRUD / entity-shaped) and belong in eden-biz-flutter Phase 3.
- Trades-specific (skip): `battery_indicator` (fleet-only).

**NEW primitives to donate (Phase 1 target — 14 components):**

| TRD | Component | Donor | Wave |
|---|---|---|---|
| 01 | `EdenUrgencyBadge` | `trades-flutter/lib/shared/widgets/urgency_badge.dart` (low/medium/high/critical) | 1 |
| 02 | `EdenPipelineBadge` | `trades-flutter/lib/shared/widgets/pipeline_badge.dart` (draft/sent/won/lost/expired) | 1 |
| 03 | `EdenApprovalStatusBadge` | `trades-flutter/lib/shared/widgets/approval_status_badge.dart` (pending/approved/rejected/draft/ordered/received/in_transit/completed/fulfilled/cancelled) | 1 |
| 04 | `EdenStockLevelIndicator` | `trades-flutter/lib/shared/widgets/stock_level_indicator.dart` (green/amber/red bar) | 1 |
| 05 | `EdenCostSummaryCard` | `trades-flutter/lib/shared/widgets/cost_summary_card.dart` (labor/material/equipment/total breakdown) | 2 |
| 06 | `EdenActivityFeedItem` | `trades-flutter/lib/shared/widgets/activity_feed_item.dart` (avatar + actor/action/entity + time) | 2 |
| 07 | `EdenBlockingAlerts` | `trades-flutter/lib/shared/widgets/blocking_alerts.dart` (collapsible severity-colored alert list) | 2 |
| 08 | `EdenMediaRow` | `trades-flutter/lib/shared/widgets/media_row.dart` (compact icon+label+count row, "+ Add" buttons) | 2 |
| 09 | `EdenPlaceholderPage` | `trades-flutter/lib/shared/widgets/placeholder_page.dart` (TBD route screen) | 2 |
| 10 | `EdenInsightCard` | `trades-flutter/lib/shared/widgets/eden_insight_card.dart` (6 content types: summary/metric/alert/suggestion/chart/diagram) | 3 |
| 11 | `EdenAiPanel` | `trades-flutter/lib/shared/widgets/eden_ai_panel.dart` (collapsible right panel; composes EdenInsightCard) | 3 |
| 12 | `EdenAiCollapsibleSection` | `trades-flutter/lib/shared/widgets/ai_collapsible_section.dart` (sparkle+title+chevron section wrapper) | 3 |
| 13 | `EdenPersonaSelector` | `trades-flutter/lib/shared/widgets/persona_selector.dart` (popup menu; Riverpod stripped) | 3 |
| 14 | `EdenAgentChat` | `trades-flutter/lib/shared/widgets/eden_agent_chat.dart` (chat FAB + bottom sheet; callback-driven streaming) | 3 |
| 15 | `EdenAiInsightSlot` | `trades-flutter/lib/shared/widgets/ai_insight_slot.dart` (gate around EdenAiPanel for DetailViewScaffold slots) | 3 |

## Wave structure (parallelism map)

| Wave | TRDs | Theme | Parallelism |
|---|---|---|---|
| **1** | 003-01, 003-02, 003-03, 003-04 | Status/state primitives — pill badges + indicator | All 4 parallel (no shared files except `lib/eden_ui.dart` export step) |
| **2** | 003-05, 003-06, 003-07, 003-08, 003-09 | Dashboard composites — cards, lists, alerts, placeholder | All 5 parallel |
| **3** | 003-10, 003-11, 003-12, 003-13, 003-14, 003-15 | AI surface — insight card, panel, chat, selector | 003-10 (InsightCard) first; then 003-11/12/13 parallel; 003-14 + 003-15 depend on 003-11 + 003-13 |

**File-collision discipline:** each TRD appends 1-2 export lines to `lib/eden_ui.dart` under a NEW section header per wave:
- Wave 1: `// Phase 1 — Status & state primitives (objective 003)`
- Wave 2: `// Phase 1 — Dashboard composites (objective 003)`
- Wave 3: `// Phase 1 — AI surface (objective 003)`

Within a wave the executor MUST serialize the export-edit step (mark each TRD `co_modified_files: [lib/eden_ui.dart]` so the orchestrator serializes within-wave). DO NOT touch existing Wave A or obj 002 sections.

## Constraints (locked, do not revisit)

1. **TDD strict (Iron Law) + test-list-first.** Every TRD's testable tasks carry `tdd="true"`. Test-list checklist at the top of every TRD enumerating happy/edge/failure cases BEFORE any test code. Hand-built fixture builders only (no LLM-generated test data) — `no_llm_test_data` constraint active. One test at a time through RED → GREEN → REFACTOR. Per `~/.claude/CLAUDE.md` TDD Playbook habits 1–4.
2. **Outside-in for AI suite (Wave 3 only).** Widget test at the top-level public component first (e.g. `EdenAiPanel` rendering with mock insights), then drill into helpers. iPhone-narrow responsive baseline (≥390pt) MUST be in every TRD's test list.
3. **Test pattern locked.** `testWidgets('renders ...', (tester) async {...})` with `wrap()` helper at the top of each test file. Mirror `test/widgets/eden_alert_test.dart`. Widget tests, NOT integration tests.
4. **Transport-agnostic + Riverpod-free.** No `dio`, no `http`, no `connectrpc`, no `flutter_riverpod`, no `shared_preferences`. **The AI suite specifically:** panel/chat widgets receive callbacks for streaming/fetch/persistence — they do NOT initiate network requests. The donor `EdenAgentChat` is Riverpod-coupled to `aodexRepositoryProvider`; the library version strips Riverpod and accepts `Stream<EdenChatChunk> Function(EdenChatRequest)` + `Future<String> Function({required String personaId, required String title})` callbacks. Per `PROJECT.md` Constraints + `eden-libs/CLAUDE.md` ("Keep platform logic in `eden-platform-flutter`, not in `eden-ui-flutter`").
5. **Cross-vertical decoupling.** AI suite primitives MUST NOT bind to trades-specific entity types (e.g. trades `Customer` / `Project`). Bind via generic slots (`entityType: String?`, `entityId: String?`, `entityLabel: String?`, `pageContext: String`) that downstream apps configure per vertical. The donor `ActivityFeedItemWidget` imports `trades/features/admin/domain/admin_stats_model.dart` for `ActivityFeedItem` + `ActivityVariant` — the library version MUST inline its own `EdenActivityFeedItem` data class + `EdenActivityVariant` enum.
6. **No new dependencies.** The donors' `flutter_riverpod` + `aodex_models` + `intent_classification` + `ai_persona_mapping` + `admin_stats_model` imports stay in trades-flutter. The library version owns its own minimal `EdenAiPersona` enum + `EdenInsightContent` data class + `EdenChatMessage` + `EdenChatRole` + `EdenInsightType` etc. — inlined into the relevant widget files (or shared `lib/src/widgets/eden_ai/eden_ai_models.dart` if more than one widget needs them).
7. **Material 3 + tokens.** Use `EdenSpacing`, `EdenRadii`, `EdenColors`, `EdenTypography` from `lib/src/tokens/` where they apply. Donor files often hard-code `Colors.amber.shade800` / `Colors.green.shade600` / `Color(0xFFD4A853)` etc. — for v1 keep those hard-coded literals (the trades app's color decisions are validated against real users); a follow-up objective can re-skin to tokens.
8. **Visual catalog entry.** Every new component gets a catalog entry under existing `lib/dev_app/screens/`:
   - Wave 1 (badges/indicators) → `lib/dev_app/screens/badges_alerts_screen.dart`
   - Wave 2 (cards/composites) → `lib/dev_app/screens/data_display_screen.dart` (cost summary, activity feed, media row), `lib/dev_app/screens/badges_alerts_screen.dart` (blocking alerts), `lib/dev_app/screens/misc_screen.dart` (placeholder page)
   - Wave 3 (AI surface) → `lib/dev_app/screens/chat_screen.dart` (panel + chat) + `lib/dev_app/screens/misc_screen.dart` (collapsible section, persona selector, insight slot)
9. **File collision (`lib/eden_ui.dart`).** Every TRD appends 1-2 export lines under a NEW section header per wave (see above). Mark each TRD's `co_modified_files: [lib/eden_ui.dart]` in frontmatter so the orchestrator serializes the edit step within a wave.
10. **No breaking changes to Wave A or obj 002.** Existing 21 widget exports + ~445 tests must continue to pass. This objective is purely additive.
11. **iPhone-narrow safe (≥390pt).** Every TRD's test list includes a responsive test at 390pt logical width with no `RenderFlex overflowed` warnings.

## Success criteria (must-haves, observable truths)

1. All 14 new components compile, pass `flutter analyze`, and pass `flutter test`.
2. Every component has a widget test file `test/widgets/eden_<name>_test.dart` using `wrap()` helper.
3. Every component has hand-built fixtures at `test/widgets/_fixtures/eden_<name>_fixtures.dart` with header line `// Do NOT regenerate via LLM — hand-built fixtures for Eden<Name>.`
4. Every component has an iPhone-narrow responsive test (≥390pt logical width, no overflow warnings).
5. Every component is exported under the correct wave section header in `lib/eden_ui.dart`.
6. Every component has a dev catalog entry visible via `just dev-ui`.
7. The 445 existing Wave A + obj 002 tests still pass (no breakage).
8. `just check` (full pre-commit gate) passes cleanly on the feature branch.
9. **No new dependencies in `pubspec.yaml`** — no `flutter_riverpod`, `dio`, `http`, `connectrpc`, or AODex-shaped types appear.
10. AI suite (TRD 10-15) widgets are callback-driven: no widget initiates a network request, no widget imports a `package:eden_ai_dart` or `package:eden_ai_flutter` symbol. The library remains a pure UI layer.
11. Cross-vertical decoupling: NO `ActivityFeedItem`-style import from a trades-only domain. The library owns its own data classes (`EdenActivityFeedItemData`, `EdenInsightContent`, `EdenAiPersona`, `EdenChatMessage`, etc.).
12. Roadmap updated: objective 003 added to Active Objectives with TRD checklist (all `[ ]`).

## Out of scope (deferred to later objectives or skipped entirely)

- **Generic primitives already in eden-ui-flutter** (`EdenEmptyState`, `EdenStatusBadge`, `EdenStatCard`, etc.) — donor variants would duplicate; if the donor adds a feature the library lacks, file a follow-up enhancement TRD.
- **CRUD scaffolding** (`create_edit_dialog`, `crud_action_buttons`, `entity_data_table`, `entity_card`) — biz-coupled CRUD pattern belongs in eden-biz-flutter Phase 3, not the library.
- **`responsive_tabs`** — `EdenTabs` likely covers; defer until a downstream app proves a gap.
- **Skill/MCP/agent_builder widgets** — defer per `ABSORPTION_RESEARCH_2026-05-15.md` Q6 reconsideration ("target eden-ai-flutter unless biz-domain bindings surface during port; revisit at Phase 3"). Not Phase 1.
- **`persona_switch_proposal`** — depends on trades' `IntentClassification` + `CostTier` types; defer to Phase 3 alongside agent_builder placement decision. Surfaces in donor `EdenAgentChat`; the library version's chat widget supports a generic `Widget? proposalCard` slot instead.
- **Visual regression baselines** (VRT-01 v2 future objective).
- **Real-device iOS / Android testing** (downstream apps gate this).
- **Re-skinning donor color literals to `EdenColors` tokens** — keep donor colors for v1 (validated against real users); follow-up objective if the design system wants unification.

## References

- `.planning/PROJECT.md` (transport-agnostic constraint, test pattern, validation commands)
- `.planning/TRADES_FLUTTER_ABSORPTION_PLAN_2026-05-15.md` §5.3 (Phase 1 widget donations scope)
- `.planning/TRADES_REMAP_DEEP_AUDIT_2026-05-15.md` §4 (donor map)
- `.planning/ABSORPTION_RESEARCH_2026-05-15.md` (locked decisions Q1-Q12 + Phase 1 unchanged status)
- `.planning/objectives/001-wave-a-cross-vertical-fundamentals/` (canonical TRD shape; e.g. 001-04 EdenCurrencyDisplay)
- `.planning/objectives/002-companion-shell-foundation/` (canonical TRD shape; e.g. 002-04 EdenFieldViewGate)
- `eden-libs/CLAUDE.md` ("Keep platform logic in `eden-platform-flutter`, not in `eden-ui-flutter`")
- `~/.claude/CLAUDE.md` TDD Playbook (global — strict TDD + test-list-first + hand-built fixtures)
- Donor source root: `/Users/markemerson/Source/AOCyber-Trades/trades-flutter/lib/shared/widgets/`
- GitHub tracking: `AO-Cyber-Systems/eden-ui-flutter#10`

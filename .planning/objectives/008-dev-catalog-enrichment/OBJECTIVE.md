---
objective: 008-dev-catalog-enrichment
kind: ui-lib
work: feature
status: planned
estimated_effort: 2-3 weeks Claude execution
trd_count: 9
waves: 5
github_issue: TBD
---

# Objective 008 — Dev Catalog Enrichment

## Goal

Enrich the live Flutter dev catalog at `lib/dev_app/screens/` so the 52 shipped components from objectives 001/002/003/004 **demo as completely as they test**. The catalog today (post objective 004) makes the library look thinner than it is — most components have 1-5 minimal demos with generic trades-only sample data. After this objective ships, every catalog screen showcases:

1. **Default state** (empty / loading / minimal data)
2. **Realistic populated state** with cross-vertical sample data (trades / salon / fuel / medical / gov)
3. **Edge states** (overflow, error, disabled, max-data)
4. **Responsive variants** at Compact / Medium / Expanded widths via `EdenAdaptiveLayout`
5. **Interactive demo** (drag / swipe / expand / animate) where applicable

This is a **catalog-content objective, not library-API work.** No component public APIs change — enrichment is demo-only.

## Why now

- 2026-05-16 user feedback: live catalog makes 52 functionally-complete components LOOK thin (1041 tests passing but demos read as minimal placeholders).
- Downstream consumers (salon vertical onboarding, trades absorption, fuel/medical/gov verticals) need to see what each component can do at a glance — not infer it from tests.
- Side-by-side trades-react reference screenshots (qa-admin-*.png + mobile-*.png) exist in `/Users/markemerson/Source/AOCyber-Trades/trades/` — the EdenScheduler parity checkpoint from objective 004 still needs human verification against them. Wave 5 here folds that into the catalog itself.
- Cross-vertical sample data (trades job, salon appointment, fuel delivery, medical visit, gov case fixtures) is currently re-invented per-screen with generic placeholders. Shared `_sample_data/` library makes future enrichment cheap.

## Scope (9 TRDs across 5 waves)

| TRD | Focus | Wave |
|---|---|---|
| 008-01 | Cross-vertical sample-data library (`lib/dev_app/_sample_data/`) — trades job / salon appointment / fuel delivery / medical visit / gov case / cross-cutting customer/staff/inventory fixtures | 1 |
| 008-02 | Layouts screen enrichment (`layouts_screen.dart`) — EdenListPageScaffold + EdenDetailPageScaffold with realistic cross-vertical list/detail pages | 2 |
| 008-03 | Data-display screen enrichment (`data_display_screen.dart`) — EdenStatCard / EdenDataTable / EdenCostSummaryCard / EdenActivityFeedItem / EdenMediaRow / EdenStockLevelIndicator | 2 |
| 008-04 | Inputs + misc screens enrichment — EdenPhoneInput country variants / EdenOtpInput length variants / EdenAddressInput / EdenNetworkStatusBar / EdenOfflineQueueViewer / EdenAuthenticatedImage | 2 |
| 008-05 | Companion screen enrichment (`companion_screen.dart`) — full vertical-flavor shells: trades dispatch / salon front-desk / fuel driver / medical home-visit / gov caseworker; GPS realistic positions; UX-mode toggles | 3 |
| 008-06 | New composers screen (`composers_screen.dart`) — EdenConsentFlow / EdenIntakeForm / EdenRoleDashboardShell / EdenAppTourOverlay + EdenContextualTip + EdenStarterTemplateCard | 3 |
| 008-07 | Badges/alerts screen enrichment (`badges_alerts_screen.dart`) — cross-vertical EdenUrgencyBadge / EdenPipelineBadge / EdenApprovalStatusBadge / EdenBlockingAlerts / EdenMembershipTierBadge realistic scenarios | 4 |
| 008-08 | Chat (AI surface) screen enrichment (`chat_screen.dart`) — EdenInsightCard 6 layouts cross-vertical / EdenAiPanel personas / EdenAiCollapsibleSection / EdenPersonaSelector / EdenAgentChat vertical scenarios / EdenAiInsightSlot | 4 |
| 008-09 | Scheduler screen enrichment (`scheduler_screen.dart`) — side-by-side trades-react PNG embeds + 50+ event demo + all 7 view modes wired live + cross-vertical event demos (salon appointments / medical visits / fuel deliveries) | 5 |

## Wave structure (parallelism map)

- **Wave 1 (foundation; 1 TRD):** 008-01 — sample data library. Single TRD because all downstream waves depend on it.
- **Wave 2 (primitives + scaffolds; 3 TRDs):** 008-02, 008-03, 008-04 — parallel. Distinct screens, no file overlap. All depend on Wave 1 fixtures.
- **Wave 3 (companion + composers; 2 TRDs):** 008-05, 008-06 — parallel. Distinct screens (companion_screen vs new composers_screen).
- **Wave 4 (badges + AI surface; 2 TRDs):** 008-07, 008-08 — parallel. Distinct screens. Could in principle run alongside Wave 3, but assigned later to spread executor load across waves.
- **Wave 5 (scheduler capstone; 1 TRD):** 008-09 — visual parity rig. Single TRD because scheduler_screen is large and the side-by-side image-comparison work is its own concern.

## Constraints (locked, do not revisit)

1. **No component API changes.** Enrichment is demo-only. If a demo needs a missing prop / variant on a library widget, file a quick-task afterward — do NOT touch `lib/src/widgets/` in this objective.
2. **Hand-built sample data.** Every fixture file carries a `// Do NOT regenerate via LLM — mutate in-place when downstream verticals shift.` header. Per global TDD Playbook habit 4 + resolver `no_llm_test_data` constraint.
3. **Widget-test floor (not full TDD ceremony).** Demos are catalog content, not library widgets. Each TRD adds at minimum ONE widget test confirming the new demo screen renders without `RenderFlex overflowed` warnings at iPhone-narrow (≥390pt). NO `Test list` section in TRDs. NO `tdd="true"` on tasks. Tests live under `test/dev_app/<screen>_demo_test.dart`.
4. **Cross-vertical coverage in every fixture set.** Sample data MUST cover at least 3 of: trades / salon / fuel / medical / gov. Bias toward 5 where feasible.
5. **Side-by-side trades-react reference (Wave 5 only).** Scheduler enrichment embeds `qa-admin-*.png` / `mobile-*.png` from `/Users/markemerson/Source/AOCyber-Trades/trades/` as comparison rows. Copy the PNGs into `lib/dev_app/_assets/trades_react_reference/` (NEW directory) and register in `pubspec.yaml` assets list. Do NOT reference the AOCyber-Trades absolute path at runtime.
6. **Section helper reused.** `lib/dev_app/widgets/section.dart` (Section + EdenDivider sub-headers) is the pattern. New helpers OK in `lib/dev_app/widgets/` but DO NOT create one-off variants.
7. **Responsive demo pattern locked.** For responsive variants, use `SizedBox(width: <pt>)` wrappers (Compact 390pt, Medium 768pt, Expanded 1280pt) to show side-by-side without resizing the host browser. Do NOT use `MediaQuery.fromView` overrides (gnarly + fragile).
8. **No new package deps.** Library remains 0-new-deps from objectives 001-004.
9. **File ownership for parallel execution.** Wave-2 TRDs each touch ONE screen file plus `pubspec.yaml`/`home_screen.dart` if registering. Wave-3 TRDs split companion_screen (existing) vs composers_screen (new) — no overlap.
10. **TRD type=standard, NOT type=tdd.** Per user override of resolver default. Each TRD lists one widget-test pairing task at the end, but tasks are NOT marked `tdd="true"` and NO `## Test list` section appears.

## Success criteria (must-haves, observable truths)

1. All 9 TRDs landed; `just dev-ui` renders each updated screen without `RenderFlex overflowed` warnings.
2. Every component from objectives 001/002/003/004 has at least one realistic cross-vertical demo (not generic placeholder text).
3. Cross-vertical sample data library exists at `lib/dev_app/_sample_data/` with the 5 vertical scenario files + cross-cutting shared types.
4. Every catalog screen demonstrates at least 3 of the 5 enrichment patterns (default state / realistic populated / edge state / responsive variant / interactive demo) per relevant component. Not every component needs all 5.
5. Scheduler screen (`scheduler_screen.dart`) shows side-by-side trades-react PNG reference rows AND live `EdenScheduler` for each of the 7 view modes (month / week / workWeek / day / list / mobile / swimlane).
6. New widget test files under `test/dev_app/` confirm each enriched screen renders without overflow at iPhone-narrow (≥390pt). Existing 1041 tests still pass — no regression in `test/widgets/`.
7. `just check` passes cleanly on the feature branch.
8. Zero new pubspec dependencies added.
9. Zero changes under `lib/src/widgets/` — enrichment is purely additive to `lib/dev_app/`.

## Out of scope

- Component public-API changes (out of scope per Constraint 1; file quick tasks instead).
- Visual regression baselines (deferred — VRT-01 v2 future objective).
- New vertical components (Wave B fuel, Wave C gov overlay are separate objectives).
- iOS / Android real-device walk-through (downstream apps gate this).
- Trades absorption epic (separate eden-biz-flutter objective).
- Re-organising existing screen file layout (e.g., splitting `chat_screen.dart` into `ai_surface_screen.dart`) — only DO this if a screen would exceed ~1200 LOC after enrichment; otherwise enrich in place.
- Backend / transport / auth work (forbidden by `PROJECT.md`).

## References

- `.planning/PROJECT.md` — constraints, test pattern, validation commands
- `.planning/SESSION_COMPONENT_CATALOG_2026-05-16.html` — the 52-component inventory grouped by objective + wave
- `.planning/objectives/001-04/OBJECTIVE.md` — what each component does
- `/Users/markemerson/Source/AOCyber-Trades/trades/qa-admin-*.png` + `mobile-*.png` — primary-source visual reference for Wave 5
- `~/.claude/CLAUDE.md` TDD Playbook habits 1-4 (habit 4 honored: hand-built fixtures only)

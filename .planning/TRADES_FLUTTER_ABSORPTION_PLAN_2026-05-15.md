# Trades-Flutter Absorption Plan — `feature/multi-model-adaptive` → `eden-biz-flutter`

**Date:** 2026-05-15
**Source branch:** `AOCyber-Trades/trades-flutter` @ `feature/multi-model-adaptive` (218 commits ahead of `origin/main`)
**Target:** `eden-biz/flutter/lib/features/` with `business_vertical=trades-hvac` gating + companion build target
**Parent docs:**
- `eden-libs/eden-ui-flutter/.planning/TRADES_REMAP_DEEP_AUDIT_2026-05-15.md` §7 decision 6 + §8 action 1
- `eden-biz/go/.planning/VERTICAL_SKIN_ARCHITECTURE.md` (Path α — single binary + mode flag)

**Status:** Report only. No code modified, no commits.

---

## 1. Scope & method

### What was diffed

- `git log origin/main..HEAD --oneline` → **218 commits**
- `git diff origin/main..HEAD --stat` → **596 files changed, 106 095 insertions, 7 732 deletions**
- After excluding `.planning/` (84 files, ~14 800 LOC, planning artefacts) and `wireframe/` (2 HTML files, ~8 400 LOC, pre-build visual prototype) → **505 code files, ~83 000 LOC delta**.
- Diff filter A vs M on `lib/features/`: **271 new files** vs **254 modified files** — confirms the branch is mostly greenfield builds layered on a small pre-existing scaffold rather than refactors of existing code.

### Commit shape (218 commits)

| Type | Count | Interpretation |
|---|---|---|
| `feat(Wxx-yy):` | ~110 | Wave objectives W01–W20, one TRD per commit pair (mock data → page) |
| `feat(...)` non-W | ~25 | Net-new features outside the wave plan (search, settings, responsive, incomplete-work, etc.) |
| `fix(...)` | 43 | Bug fixes — schedule (8), crud (3), inventory (3), bids (2), models (2), router (2), W15 (2), others 21 |
| `docs(...)` | 39 | TRD/SUMMARY/ROADMAP markdown only — no code |
| `wip` | 1 | One paused-integration WIP commit |

### Where I read

- `lib/features/<folder>/` — file counts and shortstats for all 37 folders.
- `lib/shared/widgets/` — 46 widgets, including 16 new in branch (`eden_ai_panel`, `eden_insight_card`, `eden_agent_chat`, `persona_*`, `list_page_scaffold`, `detail_*`, `entity_data_table`, `stat_card_row`, `media_row`, `responsive_tabs`, `create_edit_dialog`, `crud_action_buttons`, `blocking_alerts`, `status_filter_pills`, `ai_collapsible_section`, `ai_insight_slot`).
- `lib/shared/api/` — `connect_client.dart` (Dio-based, 195 LOC), `aodex_client.dart` (390 LOC), `aodex_models.dart` (302 LOC).
- `lib/shared/rbac/` — `permissions.dart` (122 LOC, 99 permissions), `route_permissions.dart` (538 LOC), `rbac_provider.dart`, `permission_gate.dart`.
- `lib/app.dart` + `lib/config/navigation.dart` (592 LOC) + `lib/config/router.dart` (+296 LOC).
- `pubspec.yaml` — only 2 dep adds: `url_launcher`, `mockito`.
- `eden-biz/flutter/lib/features/` — 44 existing folders, mostly single-screen stubs (1 `_screen.dart` file each); `dataroom` is the only deep one (15 files); `crm/`, `settings/`, `scheduling/` have small widget folders. **trades-flutter brings the depth eden-biz-flutter doesn't have yet.**
- `eden-libs/eden-platform-flutter/lib/src/` — confirms `auth/`, `company/`, `navigation/`, `analytics/`, `entitlements/`, `errors/`, `models/`, `settings/` already live on platform-flutter (shell concerns owned upstream).

---

## 2. The 218 commits classified

### By band (per deep audit §3) and change shape

| Folder (band) | #commits | #files Δ | LOC Δ | Dominant shape | Risk |
|---|---|---|---|---|---|
| **Band 0 — shared/infra & shell** | — | 51 | +10 019 / -367 | new shared widgets + RBAC + Connect client + nav | **HIGH** — auth/Connect collides with eden-platform-flutter |
| `lib/shared/widgets/` (16 new + 7 modified) | 18 | 23 | +4 300 | new widget primitives (Eden* + scaffolds) | HIGH — donor source for eden-ui-flutter Wave A |
| `lib/shared/api/`, `lib/shared/data/`, `lib/shared/providers/`, `lib/shared/rbac/` | ~15 | 20 | +3 080 | net-new ConnectRPC + AODex + 99-perm RBAC | HIGH — parallel to eden-platform-flutter `src/api/`, `src/auth/` |
| `lib/app.dart`, `lib/config/` (router + navigation) | ~10 | 4 | +900 | full nav model rewrite + RBAC route gating | HIGH — collides with eden-biz-flutter `biz_shell.dart` |
| **Band 1 — cross-vertical admin features (lift gated under existing eden-biz folders)** | — | — | — | — | — |
| `admin` (cross) | ~11 | 38 | +6 062 | net-new (W13 + W18 persona config) | MEDIUM — merge into eden-biz `settings/` + `admin/` |
| `customers` (cross) | ~6 | 20 | +3 034 | rewrite + W05 detail | MEDIUM — eden-biz `crm/` has stub only |
| `projects` (cross) | ~5 | 12 | +1 714 | W06-01 + status fields | LOW — eden-biz `projects/` has 1 file |
| `appointments` (cross) | ~3 | 7 | +718 | dialogs + dispatch wiring | LOW |
| `invoices` (cross) | ~3 | 10 | +826 | W09 billing center rewrite | LOW — eden-biz `invoicing/` has 7 files (parallel logic) |
| `payroll` (cross) | ~2 | 11 | +1 723 | W09-03 net-new | LOW — eden-biz `hr/` stub |
| `team` (cross) | ~3 | 15 | +2 391 | W10-01 + W13-02 customize | MEDIUM — overlaps eden-biz `hr/` + `settings/` |
| `documents` (cross) | ~2 | 5 | +431 | W11-01 grouped cards | LOW — eden-biz `dataroom/` is the real owner |
| `notifications` (cross) | ~1 | 6 | -1 | trivial deletions (move-out) | LOW |
| `tasks` (cross) | ~2 | 6 | +423 | minor | LOW |
| `analytics` (cross) | ~2 | 12 | +1 708 | W09-04 ops dashboard | LOW |
| `callbacks` (trades-flavored cross) | ~1 | 7 | +1 321 | W07-02 net-new | LOW |
| `change_orders` (trades-flavored cross) | ~1 | 5 | -17 | trivial | LOW |
| `status_sheets` (trades) | ~1 | 6 | +530 | W06-02 net-new | LOW |
| `auth` (cross) | ~2 | 3 | +134 | devLogin perm expansion | MEDIUM — auth collides w/ platform-flutter |
| `home` (cross) | ~1 | 5 | +1 324 | misc | LOW |
| `onboarding` (cross) | ~2 | 11 | +1 868 | W16 tour overlay + starter templates | LOW — donor for `EdenAppTourOverlay` |
| `portal` (cross) | ~1 | 6 | 0 | trivial | LOW |
| `equipment` (trades) | ~1 | 5 | +328 | trivial | LOW |
| `maintenance` (cross) | ~1 | 6 | +935 | W07-02 kanban | LOW |
| `subcontractors` (cross) | ~2 | 12 | +1 839 | W10-02 net-new | LOW |
| `ai_search` (cross) | ~1 | 3 | +301 | W19-05 wire ConnectRPC SearchService | LOW |
| `process_builder` (cross) | ~1 | 14 | +2 636 | W12-01 swimlane canvas | **MEDIUM** — A4-a sub-system port (see deep audit §2.1) |
| `agent_builder` (cross) | ~2 | 15 | +3 621 | W12-02 + W17-06 MCP | **MEDIUM** — placement open per deep audit §7.7 |
| `templates` (cross) | ~3 | 12 | +2 902 | W11 block builder | **MEDIUM** — A4-c sub-system |
| **Band 2 — trades-flavored (lib/features/trades/)** | — | — | — | — | — |
| `bidding` (trades) | ~5 | 14 | +2 160 | W07-01 + W17/19/20 AI estimate streaming | MEDIUM — semi-coupled to AOSentry/AODex client |
| `inventory` (cross-flavored trades) | ~4 | 19 | +2 294 | W08-01 stock + W15 UUID migration | LOW — eden-biz `inventory/` stub |
| `purchasing` (trades) | ~4 | 24 | +2 534 | W08-02/03 PO + suppliers | LOW |
| `fleet` (trades) | ~3 | 17 | +1 569 | W10-03 truck inventory + crew | MEDIUM — large monolith |
| `job_records` (trades) | ~2 | 9 | +595 | W09-01 grouped cards | LOW |
| `forefront` (trades) | ~3 | 10 | +1 398 | W03 dashboard | LOW |
| `incomplete_work` (trades) | ~1 | 3 | +833 | net-new | LOW |
| `finance` (trades adjunct) | ~1 | 3 | +183 | trivial | LOW |
| **Band 3 — companion field/mobile (companion build target)** | — | — | — | — | — |
| `schedule` (both — mobile view = companion) | ~14 | 25 | +7 633 | W04 calendar + 8 schedule fix commits | **HIGH** — largest single folder; calendar drag-drop fragile |
| `dispatch` (both) | ~1 | 4 | -43 | trivial | LOW |
| `field_crew` (companion) | ~3 | 15 | +65 | W14-02 parts/escalation + offline | LOW |
| `mobile_home` (companion) | ~3 | 16 | +3 595 | W14-01 net-new + W19-04 tests | LOW |
| **Band X — tests (cross-cutting)** | — | — | — | — | — |
| `test/` | ~7 | 37 | +4 959 | W19-01/02/03/04 widget + integration tests | LOW — port alongside features |

### Five biggest risk concentrations

1. **`lib/shared/api/` + `lib/shared/rbac/` + `lib/config/`** (3 080 + 900 + 538 LOC) — invented in-tree because trades-flutter doesn't depend on `eden-platform-flutter`. Cannot land in eden-biz-flutter as-is — must be reconciled against the platform-flutter shell.
2. **`schedule/` 7 913 LOC across 25 files, 14 commits** — drag-drop fragility (multiple `fix(schedule):` regressions), Positioned-in-Stack issues, mobile vs admin variants intertwined. Decompose during port (deep audit §7.4).
3. **`admin/` 6 241 LOC across 38 files** — overlaps eden-biz `settings/`, `admin/`, `hr/` simultaneously. Needs three-way merge plan.
4. **`process_builder/` + `agent_builder/` + `templates/` (9 364 LOC, 41 files)** — three visual-builder sub-systems sharing canvas substrate. Per deep audit §2 these are A4-a/b/c — port via `eden_diagram` extension, not as direct trades-flutter copies.
5. **`bidding/`** — W17/W19/W20 AI streaming UI is tightly coupled to in-tree AODex client. Either port the AODex client too or refactor onto eden-platform-flutter's RPC channel.

---

## 3. Per-folder absorption disposition

For each of the **37 trades-flutter feature folders** (the deep audit listed 36; this branch added `incomplete_work` as a 37th). Columns:

- **Lands in** — eden-biz-flutter target folder
- **Eden-biz peer exists?** — does that folder exist today
- **Merge mode** — `extend` (eden-biz stub absorbs trades content), `co-exist` (trades content goes side-by-side under `trades/` sub-folder), `cross-vertical` (lifts top-level, vertical-agnostic), `replace` (trades content overwrites stub)
- **Prereq work** — what must land first

| Folder | Lands in | Peer? | Merge | Conflict risk | Prereq |
|---|---|---|---|---|---|
| `customers` | `crm/` | ✓ (3 files) | extend | LOW | none |
| `projects` | `projects/` | ✓ (1 file) | extend | LOW | none |
| `appointments` | `scheduling/` | ✓ (18 files, salon-flavored) | co-exist | MEDIUM — salon vs trades scheduling models differ | reconcile appointment model |
| `invoices` | `invoicing/` | ✓ (7 files) | co-exist | MEDIUM — two billing pipelines | reconcile invoice model |
| `payroll` | `hr/` | ✓ (4 files) | extend | LOW | none |
| `team` | `hr/` + `settings/` | ✓ | **split** | MEDIUM | decide team-mgmt vs role-mgmt boundary |
| `documents` | `dataroom/` | ✓ (15 files, deepest existing) | co-exist or skip | MEDIUM — dataroom is corp-DD-flavored, trades is project-doc | confirm whether trades-documents lifts here or stays under `trades/` |
| `notifications` | `notifications/` | ✓ (2 files) | replace (trivial trades changes) | LOW | none |
| `tasks` | new `tasks/` cross-vertical | ✗ | cross-vertical net-new | LOW | none |
| `analytics` | `reporting/` | ✓ (1 file) | extend | LOW | none |
| `callbacks` | new `callbacks/` cross-vertical (trades-flavored) | ✗ | cross-vertical net-new | LOW | none |
| `change_orders` | under `trades/` | ✗ | trades-vertical | LOW | none |
| `status_sheets` | under `trades/` | ✗ | trades-vertical | LOW | none |
| `auth` | `eden-platform-flutter` `src/auth/` | ✓ upstream | **discard** — use platform-flutter | HIGH | reconcile devLogin permission set into platform-flutter (or keep dev-only stub in eden-biz) |
| `home` | `dashboard/` | ✓ (1 file) | extend | LOW | A5 `EdenRoleDashboardShell` (deep audit §3 band 1 row "home") |
| `admin` | `admin/` + `settings/` + new `customizations/` | ✓ | **split into 3** | HIGH | decide what's settings-level (vert-agnostic) vs admin-level (cross-cutting) vs customizations (trades-specific extension points) |
| `onboarding` | `setup/` | ✓ (2 files) | extend | LOW | merge starter-template flow with eden-biz vertical-selection |
| `portal` | `customerportal/` + `portals/` | ✓ | co-exist or discard (web-portal is Templ per SALON_VERTICAL_UX_PLAN) | LOW | confirm Flutter portal isn't redundant |
| `equipment` | under `trades/equipment/` | ✗ | trades-vertical | LOW | none |
| `maintenance` | new `maintenance/` cross-vertical (or under `trades/`) | ✗ | open — likely cross-vertical (medical equipment, fleet, etc.) | LOW | placement decision |
| `subcontractors` | new `subcontractors/` cross-vertical | ✗ | cross-vertical net-new | LOW | none |
| `ai_search` | `aitools/` | ✓ (1 file) | extend | LOW | wire to eden-biz SearchService channel |
| `process_builder` | `workflows/` + new `process_builder/` | ✓ (1 file) | **A4-a port** | **HIGH** | `eden_diagram` extension lands first (deep audit §2.1) |
| `agent_builder` | `aitools/` or new `agent_builder/` cross-vertical | ✓/✗ | open per deep audit §7.7 | MEDIUM | placement decision; depends on aocyber agent infra (AOCore/AOID) |
| `templates` | new `templates/` cross-vertical | ✗ | **A4-c port** | MEDIUM | A4-a canvas engine first |
| `bidding` | new `bidding/` under `trades/` (cross-vertical name TBD — bidding generalizes) | ✗ | trades-vertical for v1; promote later | MEDIUM | AODex/AOSentry client placement decision |
| `inventory` | `inventory/` | ✓ (3 files) | extend | MEDIUM — eden-biz `inventory/` is corp-stub; trades has location-tree + stock-orders | reconcile inventory model |
| `purchasing` | new `purchasing/` cross-vertical | ✗ | cross-vertical net-new | LOW | none |
| `fleet` | under `trades/fleet/` (band 2 trades-flavored) | ✗ | trades-vertical | MEDIUM | decompose 2 442 LOC React monolith equivalent (deep audit §7.4) |
| `job_records` | under `trades/` | ✗ | trades-vertical | LOW | none |
| `forefront` | under `trades/forefront/` + lift `EdenRoleDashboardShell` to cross-vertical | ✗ (concept exists in `dashboard/` stub) | trades-vertical specialization | LOW | A5 shell first |
| `incomplete_work` | new `incomplete_work/` cross-vertical | ✗ | cross-vertical net-new | LOW | none |
| `finance` | `accounting/` or `banking/` | ✓ | extend | LOW | trivial |
| **Band 3 — companion build target** | | | | | |
| `schedule` | `scheduling/companion/` + admin parts merged into `scheduling/` | ✓ | **split** admin/companion | **HIGH** | Path α mode flag in place |
| `dispatch` | new `dispatch/companion/` under trades (or cross) | ✗ | companion build target | LOW | A4 map provider |
| `field_crew` | new `field_crew/companion/` cross-vertical | ✗ | companion build target | LOW | offline queue widget in eden-ui-flutter |
| `mobile_home` | `dashboard/companion/` + role shell | ✓ stub | companion build target | LOW | A5 + Path α |

---

## 4. Blocker analysis — pre-absorption infra that must land first

The 218 commits include net-new infrastructure that **does not have a direct slot** in eden-biz-flutter today. These are absorption blockers — code that, if copied directly, would either duplicate or fight upstream platform-flutter.

### 4.1 Connect/AODex client layer (HIGH)

- **What:** `lib/shared/api/connect_client.dart` (195 LOC, Dio-based), `lib/shared/data/connect_repository.dart` (base class), `lib/shared/api/aodex_client.dart` (390 LOC SSE streaming).
- **Conflict:** `eden-platform-api-dart/lib/src/gen/` already generates Connect bindings; `eden-platform-flutter/lib/src/api/` owns the Dio/Connect wiring at platform level. The trades-flutter client is parallel.
- **Commits that depend on it:** all of W15-01..04 (4 commits) + every W17/W18/W19/W20 commit (~28 commits) + every `fix(repos):` and `fix(models):` commit (~10 commits). **~42 commits unsafe to land without reconciliation.**
- **Pre-work needed:** decide whether (a) trades-flutter's `ConnectClient` becomes the donor for `eden-platform-flutter/src/api/connect_channel.dart`, (b) repositories rewrite to use platform-flutter's existing Channel API, or (c) we ship two RPC layers temporarily.

### 4.2 RBAC permission model (HIGH)

- **What:** 99 hand-coded permission constants (`permissions.dart`), 538-LOC `route_permissions.dart` mapping every route to a permission, `RbacProvider` riverpod hook, `PermissionGate` widget.
- **Conflict:** `eden-platform-flutter/lib/src/entitlements/` exists as the upstream entitlements layer; eden-biz-flutter uses an `app_provider.dart` with no RBAC. **The 99-permission set is trades-specific and overlaps with but doesn't match eden-platform-flutter's entitlement semantics.**
- **Commits that depend on it:** W01-02 (RBAC wiring) + W05-02 (RBAC slot) + W19-02 (RBAC tests) + every page that uses `PermissionGate` — searched ~30 files.
- **Pre-work needed:** map the 99 trades permissions to platform-flutter entitlement keys (or to a vertical-scoped permission registry). Open question whether platform-flutter grows a permission registry or eden-biz-flutter owns it.

### 4.3 App shell / navigation model (HIGH)

- **What:** `lib/config/navigation.dart` (592 LOC — 8-group sidebar nav model with RBAC filtering, mobile reorder, sub-items), `lib/config/router.dart` (+296 LOC — RBAC route guards), `lib/app.dart` (offline banner, theme).
- **Conflict:** `eden-biz/flutter/lib/features/shell/biz_shell.dart` is the eden-biz shell; `eden-platform-flutter/lib/src/navigation/` owns nav loading. Three competing shells.
- **Commits that depend on it:** W01-01, W01-02, all router-modifying commits (~12 commits).
- **Pre-work needed:** decide whether trades' nav model donates to `eden-platform-flutter/src/navigation/` as the canonical "vertical-aware sidebar" model, or whether it dissolves into eden-biz's `biz_shell.dart`. Per `VERTICAL_SKIN_ARCHITECTURE.md` this is the **vertical-skin layer** — trades nav becomes one skin among many.

### 4.4 Shared widget primitives (MEDIUM)

- **What:** 16 new widgets in `lib/shared/widgets/` (`eden_ai_panel`, `eden_insight_card`, `eden_agent_chat`, `persona_*`, `list_page_scaffold`, `detail_view_scaffold`, `detail_header`, `media_row`, `entity_data_table`, `stat_card_row`, `responsive_tabs`, `create_edit_dialog`, `crud_action_buttons`, `blocking_alerts`, `status_filter_pills`, `ai_collapsible_section`, `ai_insight_slot`).
- **Conflict:** these are clearly **eden-ui-flutter library donors**, not eden-biz-flutter features. Naming (`Eden*`) already signals intent. They were built in trades-flutter because there was no `eden_ui` shipment cadence at the time.
- **Commits that depend on it:** W02-01..03 + W17-01 (the original placement commits); every feature folder commit that consumes them (~50+ commits — almost every Wave commit).
- **Pre-work needed:** donate these 16 widgets to `eden-ui-flutter` **before** feature folders absorb, otherwise every Band-1/Band-2 absorption PR re-declares them inline. **This is the single largest unblocker.**

### 4.5 AODex / AOSentry client (MEDIUM)

- **What:** `aodex_client.dart` (390 LOC SSE streaming), `aodex_models.dart` (302 LOC).
- **Conflict:** post-2026-05-13 FedRAMP strategy (per memory `project_aocore_aware_fedramp_2026-05-14.md`) shifts toward AOID/AOEdge/AOAudit/AOSentry — but those services don't exist yet. AODex was the prior naming.
- **Commits that depend on it:** all W17 + W18 + W20 AI streaming (~16 commits).
- **Pre-work needed:** decide whether the trades-flutter AODex client survives in some form (renamed to AOSentry-client?) or gets re-platformed. **Open per deep audit §7.3.**

### 4.6 ConnectRPC migration debt — W15 UUID compilation (MEDIUM)

- **What:** `feat(W15-02): global int->String UUID ID migration across all models and providers`, `fix(W15): resolve 194 UUID migration compilation errors`, follow-ups.
- **Conflict:** eden-biz-flutter's existing models (`crm/contact_detail_screen.dart`, `invoicing/invoice_model.dart`) likely use String IDs already (they're newer). But trades-flutter's pre-W15 mock data was int-based — the W15-02 commit + its 2 follow-up fixes must land **atomically** or absorption hits 194 compile errors mid-port.
- **Pre-work needed:** treat W15-01..04 as a single absorption unit.

### 4.7 W17/W18 wave commits depend on widgets + AODex (CASCADING)

- **What:** W17-01 lands `EdenAIPanel/InsightCard/AgentChat`; W17-02..05 wire them into Operations/Finance/Relationship/Supply-Chain pages; W18-01 wires AODex SSE into `EdenAgentChat`; W18-02..04 build persona machinery.
- **Dependency chain:** W17/W18 cannot land until 4.4 (widgets in lib) **and** 4.5 (AODex placement) **and** 4.1 (Connect client) are resolved.

### 4.8 Test infrastructure depends on mock ConnectClient (LOW)

- **What:** W19-01..04 (~37 test files, ~4 959 LOC) — widget tests, RBAC tests, contract tests using a mock `ConnectClient`.
- **Conflict:** if 4.1 resolves to "use platform-flutter's Channel," the W19 mock client must be rewritten.
- **Pre-work needed:** sequence W19 absorption **after** 4.1 settles.

---

## 5. Recommended strategy — Hybrid, infra-first then per-folder

### 5.1 Why not "one big merge"

- 596 changed files, ~83 000 LOC code delta, across 7+ subsystems that touch eden-platform-flutter contracts.
- Auth/RBAC/Connect collisions are not trivially mergeable — they need design decisions, not cherry-picks.
- A single PR is unreviewable.

### 5.2 Why not "atomic per-folder from day 1"

- Most Band-1/Band-2 folders depend on the 16 shared widgets + Connect client + RBAC. Absorbing folders first means each PR re-vendors the same primitives.
- The W15 UUID migration spans every model — folders depend on it landing first.

### 5.3 Recommended sequencing — five phases

**Phase 0 — Decisions (1 week, no code)**

- Resolve blocker 4.1: Connect/AODex client placement → eden-platform-flutter vs eden-biz-flutter vs trades-flutter shim.
- Resolve blocker 4.2: RBAC permission model placement → entitlements layer vs vertical-scoped registry.
- Resolve blocker 4.3: nav shell — does trades nav skin donate to eden-platform-flutter, or dissolve into `biz_shell.dart`?
- Resolve blocker 4.5: AODex naming/placement post-AOSentry decision.
- Resolve `agent_builder` placement (deep audit §7.7).
- Resolve `documents` vs `dataroom` boundary.
- Resolve `auth`-folder fate (likely discard, use platform-flutter).

**Phase 1 — Library donations to eden-ui-flutter (2-3 weeks, parallel to Phase 0)**

Per atomic library PRs (one widget group per PR, ~5 PRs total):

1. Scaffold pack: `list_page_scaffold`, `detail_view_scaffold`, `entity_data_table`, `stat_card_row`, `create_edit_dialog`, `crud_action_buttons`.
2. Header/media pack: `detail_header`, `media_row`, `responsive_tabs`, `status_filter_pills`, `blocking_alerts`.
3. AI pack: `eden_ai_panel`, `eden_insight_card`, `eden_agent_chat`, `ai_collapsible_section`, `ai_insight_slot`, `persona_selector`, `persona_switch_proposal`.
4. Offline pack: `offline_banner` (already in eden-ui), `offline_queue_badge`, `sync_indicator`, `EdenOfflineQueueViewer` (net-new per deep audit §2.3).
5. Onboarding pack: tour overlay + contextual tip + starter template card (deep audit Wave A10).

Each PR brings the donor file + its trades-flutter test + a visual-dev-catalog story. **Net effect:** every subsequent Band-1/Band-2 absorption can `import 'package:eden_ui_flutter/eden_ui.dart';` instead of re-declaring.

**Phase 2 — Infra reconciliation in eden-biz-flutter (2 weeks)**

Single eden-biz-flutter PR per resolved blocker:

1. Connect channel wired to eden-platform-flutter (per Phase-0 decision 4.1) + ConnectRepository base class.
2. RBAC/entitlements layer (per 4.2).
3. Vertical-aware nav shell update to `biz_shell.dart` (per 4.3).
4. AODex/AOSentry client placement (per 4.5).

These four PRs land **first** in eden-biz-flutter, before any feature folder absorbs.

**Phase 3 — Per-folder absorption (atomic, ~6-8 weeks across 37 folders)**

One PR per folder. Sequencing — order by *risk × dependency*:

1. **Low-risk net-new folders that don't conflict** (parallelizable): `callbacks`, `tasks`, `incomplete_work`, `subcontractors`, `maintenance`, `purchasing`, `change_orders`, `status_sheets`, `equipment`, `job_records`, `forefront`, `payroll`, `analytics`, `notifications`, `portal`, `finance`. ~16 PRs.
2. **Medium-risk folders that extend existing eden-biz stubs**: `customers`, `projects`, `invoices`, `inventory`, `appointments`, `team`, `documents`, `home`, `onboarding`, `ai_search`. ~10 PRs.
3. **High-risk admin split**: `admin` → `admin/` + `settings/` + `customizations/` (3 PRs, or one large reviewed PR).
4. **Trades-vertical-gated**: `fleet`, `bidding` (Band 2). 2 PRs.
5. **Visual builders (A4-a/b/c)**: `process_builder`, `agent_builder`, `templates`. These follow the eden-ui-flutter `eden_diagram` extension (per deep audit §2). 3 PRs, sequenced.

**Phase 4 — Companion build target (2 weeks)**

After Path α mode flag lands in eden-biz-flutter:

1. `mobile_home/` → `dashboard/companion/` + role shell.
2. `field_crew/` → cross-vertical `field_crew/` under companion build.
3. `schedule/` admin/companion split into `scheduling/` + `scheduling/companion/`.
4. `dispatch/` → companion target.

### 5.4 Subtree-style import vs flat copy

**Recommend flat copy with squashed-commit attribution**, not `git subtree`/`git filter-repo`:

- Most absorption PRs **rewrite** the file (RBAC strips out, ConnectClient swaps to upstream, paths change). History line-by-line attribution would be misleading — the trades-flutter commit hash maps to a different shape than the eden-biz-flutter result.
- Per-PR commit message references the donor commits (`Donor: trades-flutter@f728362 + a72ec13`) so attribution is preserved without trying to preserve diff geometry.
- 1 of the 596 files (`.planning/`) doesn't absorb — it's trades-flutter's local planning, archived separately.
- The 218 commits are the **audit trail**, not the merge target. After absorption, branch `feature/multi-model-adaptive` gets archived (not merged into trades-flutter `main`); trades-flutter the app stops shipping new releases; eden-biz-flutter assumes responsibility.

### 5.5 Estimated total absorption effort

| Phase | Effort | Parallelizable? |
|---|---|---|
| Phase 0 — decisions | 1 wk | no |
| Phase 1 — library donations (5 PRs) | 2-3 wk | yes, with Phase 0 |
| Phase 2 — infra reconciliation (4 PRs) | 2 wk | partially yes, with Phase 1 |
| Phase 3 — folder absorption (~34 PRs) | 6-8 wk | mostly yes (low-risk batch parallelizable) |
| Phase 4 — companion build (4 PRs) | 2 wk | sequential after Phase 3 |
| **Total** | **~13-16 weeks** | with ~3 engineers in parallel |

Aligns with the deep audit §6 estimate (14-18 wk total library+vertical work) — absorption *is* the library+vertical work in disguise.

---

## 6. Open questions for Mark

Decisions needed before Phase 0 starts:

1. **Connect client placement (blocker 4.1) — three options:**
   - (a) Donate trades-flutter `ConnectClient` to `eden-platform-flutter/src/api/` as the canonical Connect channel.
   - (b) Rewrite trades repositories onto whatever `eden-platform-flutter` ships today.
   - (c) Ship both temporarily; consolidate later.
   *Which?*

2. **RBAC permission model (blocker 4.2) — where lives it?**
   - (a) Promote to `eden-platform-flutter/src/entitlements/` with vertical-scoped registry pattern.
   - (b) Keep in `eden-biz-flutter` as an app-level concern.
   - (c) Split — generic gate widget in eden-ui-flutter, permission registry in eden-biz-flutter, vertical permission sets in vertical folders.
   *Which?*

3. **Nav shell (blocker 4.3) — does trades nav skin donate upstream?**
   - (a) `eden-platform-flutter/src/navigation/` grows a `VerticalNavSkin` interface; trades nav is the first implementation.
   - (b) `eden-biz/flutter/lib/features/shell/biz_shell.dart` absorbs trades nav model directly.
   *Which? — affects every router-touching commit.*

4. **`auth/` folder fate (blocker 4.7):** confirm we discard trades' auth and use `eden-platform-flutter/src/auth/`. The trades `fix(auth): expand devLogin permissions to full owner set (99 permissions)` commit is dev-only — does the 99-permission owner-set get folded into platform-flutter dev tooling, or stays trades-flutter-only as historical?

5. **AODex vs AOSentry client (blocker 4.5):** per memory `project_aocore_aware_fedramp_2026-05-14.md`, AOSentry/AODex are not yet implemented at the FedRAMP layer. Does the trades-flutter `aodex_client.dart` rename to `aosentry_client.dart` and live at eden-biz-flutter level, or does it move to a new `eden-aocore-flutter` shared lib?

6. **`agent_builder/` placement (deep audit §7.7):** cross-vertical (`eden-biz/flutter/lib/features/agent_builder/`) or `aitools/` extension or trades-vertical-only? Affects 15 files, 3 621 LOC.

7. **`documents` vs `dataroom` (Band 1):** eden-biz `dataroom/` is the DD/legal-document deep folder (15 files). trades' `documents/` is project-doc + signature flow. Do they merge (multi-mode dataroom), do trades-docs go cross-vertical alongside, or does trades-docs go under `trades/documents/`?

8. **`appointments` vs `scheduling` (Band 1):** eden-biz `scheduling/` is salon-flavored (booking-policy, gift-cards, staff-schedule). trades' `appointments/` is service-call-flavored. Do they share an underlying appointment model with vertical-flavored UI, or stay separate?

9. **Per-folder atomic vs batched PRs:** plan 3.1 lists 16 low-risk folders. Land as 16 separate PRs (1-2 days each) or batch into 4 grouped PRs (e.g. "trades cross-vertical batch 1: callbacks + tasks + incomplete_work + subcontractors")? Batching trades review depth for sequencing speed.

10. **What happens to `trades-react`?** This plan absorbs `trades-flutter`. The trades-react app (per deep audit context line 8: "main branch, React 18 + Vite + Tauri") is the field-deployed customer-facing version. Is trades-react also folded into eden-biz, or does it stay as a separate Tauri app while eden-biz-flutter rebuilds the same surface? Affects timing — if trades-react keeps shipping, eden-biz-flutter trades-hvac must reach feature parity before trades-react can sunset.

11. **`feature/multi-model-adaptive` branch lifecycle:** after absorption, do we (a) archive the branch on AOCyber-Trades with a tag, (b) close trades-flutter the repo entirely, (c) keep trades-flutter as a frozen reference for cross-checks during Phase 3? Recommend (c) for the duration of absorption, then (a).

12. **Test absorption (W19 wave):** the 37 test files map 1:1 to feature folders. Absorb tests **with their folder PR** (Phase 3) or **after** (Phase 5)? Recommend with-folder — tests are the verification artifact for the absorption, not a separate concern.

---

## 7. Decisions locked (2026-05-15, resolved with Mark)

11 of 12 decisions locked in the absorption Q/A session. Q5 paused pending AOCore-lib research.

| # | Decision |
|---|---|
| **Q1 Connect client** | eden-platform-flutter is at `eden-libs/eden-platform-flutter/` (consolidated). Research action: confirm current shape of platform Connect channel. Then absorb pragmatically (closer to option a — donate trades' to platform — but not dogmatic). **Primary intent: capture the AI-integration work** so eden-biz can integrate with AOCore/AOSentry to benefit from AI work done in trades. |
| **Q2 RBAC home** | Lives in **biz admin function** for now (option b). Future migration to **AO Identity Service** when that lands. Document the migration path in the RBAC absorption PR. |
| **Q3 Nav shell** | **eden-platform-flutter grows `VerticalNavSkin` interface; trades = first implementation.** Option (a). |
| **Q4 Auth folder** | **Discard trades auth; use `eden-platform-flutter/src/auth/`.** Fold the 99-permission devLogin shortcut into platform dev tooling as `seedDevUser('owner', verticalScope)`. Option (a). |
| **Q5 AODex/AOSentry client** | ⏸ **PAUSED — research action required.** AOCore work may already be in progress somewhere (eden-libs, aocyber-compliance, aosentry-fedramp-prep worktree per memory). Inventory in-progress AOCore lib work before deciding placement. Decision deferred until research lands. |
| **Q6 agent_builder/ placement** | **Cross-vertical at `eden-biz/flutter/lib/features/agent_builder/`.** Option (a). Aligns with Q1 biz-needs-AI-integration intent. |
| **Q7 documents vs dataroom** | **Keep separate.** Dataroom's original purpose was sharing-of-info; redefining/evolving toward **analytical concept / structured sharing**. Trades `documents/` lands as a separate folder (project docs + signature flow); dataroom keeps its DD/structured-sharing focus and evolves into analytical surface. Closer to option (b). |
| **Q8 appointments vs scheduling** | **Shared model, vertical-flavored UI under `lib/features/scheduling/`.** Single scheduling/ folder owns the data model; UI variants per vertical (`scheduling/salon/*`, `scheduling/trades/*`, `scheduling/medical/*`). `EdenScheduler` enhancement (Wave B-trades-B1) lives in eden-ui-flutter. Option (a). |
| **Q9 PR strategy** | **Batches of functionality** — not atomic per-folder, not arbitrary batching. Group folders that ship a coherent functional area (e.g., "trades dispatch surface" batch = schedule + dispatch + field_crew). Rationale: prioritizes completeness of testing; not yet customer-deployed so can roll forward. |
| **Q10 trades-react fate** | **Trades-react keeps shipping until eden-biz-flutter trades-hvac reaches parity, then sunsets.** Field crews continue using trades-react (Tauri iOS/Android/desktop) through the ~13-16 wk absorption + Wave B-trades + companion-build-target work. Sunset at parity. Option (a). |
| **Q11 multi-model-adaptive branch** | **Keep branch as frozen reference during Phase 3; archive with tag after.** Tag final SHA at end of Phase 3, archive branch, archive trades-flutter repo entirely. trades-react and trades-go decisions handled separately. Option (a). |
| **Q12 Test absorption** | **Tests absorb WITH their folder PR.** Tests ARE the verification artifact for the absorption — reviewer verifies on the spot. Option (a). |

### How the locks reshape the strategy (§5 amendments)

- **Phase 0 expansion:** add (i) eden-platform-flutter Connect shape research, (ii) AOCore in-progress lib research (Q5 unblock), (iii) AO Identity migration-path doc for RBAC.
- **Phase 1 (16 widget donations) unchanged** — they don't depend on Q5.
- **Phase 2 infra reconciliation:** Connect (per Q1 research), nav shell with `VerticalNavSkin` interface (per Q3), auth full discard (per Q4) — RBAC stays in biz (per Q2) so the previous "promote RBAC to platform" path is dropped.
- **Phase 3 PRs:** regrouped into **functional batches** (per Q9) — examples: "trades dispatch surface" (schedule + dispatch + field_crew), "trades back-office finance" (invoices + payroll + change_orders), "trades customer surface" (customers + portal + callbacks), etc. Tests batched WITH each functional surface.
- **Phase 4 unchanged.**
- **Phase 5 retired** — tests with-folder (per Q12) means no separate test-sweep phase.
- **Branch + repo lifecycle (per Q11):** trades-flutter `feature/multi-model-adaptive` stays as frozen ref through Phase 3; tag + archive at Phase 3 close. trades-flutter repo archives separately.

### Open research actions

1. **AOCore lib inventory (Q5 unblock).** Inventory in-progress AOCore work across eden-libs/, aocyber-compliance/, aosentry-fedramp-prep/. Output: where AOSentry / AOID / AOEdge / AOAudit clients live or will live, and how trades-flutter's aodex_client absorbs cleanly. Should this be a third shared lib (`eden-libs/eden-aocore-flutter/`) or sit under one of the existing aocore-product repos?
2. **eden-platform-flutter Connect shape (Q1 follow-up).** Read current `eden-libs/eden-platform-flutter/lib/src/` to identify the existing Connect channel + auth + entitlements + navigation surface. Compare with trades-flutter's parallel implementations. Output: per-file disposition (donate / rewrite / consolidate).
3. **AO Identity Service status (Q2 future-migration).** Surface to user — is AO Identity in flight, planned-but-not-started, or just an idea? If in flight, Phase 2 RBAC PR should include a migration-path doc citing the real future state.

---

*Generated 2026-05-15 by absorption-plan research agent + Q/A locks. Companion to `TRADES_REMAP_DEEP_AUDIT_2026-05-15.md` decision §7.6 and action §8.1. Read-only analysis — no source code modified.*

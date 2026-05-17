---
objective: 010-visual-polish-pass
kind: ui-lib
work: feature
status: planned
parent_research: .planning/VERTICAL_UX_RESEARCH_2026-05-16.md
parent_section: "§3.2 Objective 010 + §2.1 + §2.2 + §6 aesthetic preservation"
depends_on: [009-vertical-theme-system]
---

# Objective 010 — Eden Visual Polish Pass (Material 3 Expressive + Density + Animation Tokens)

## Goal

Absorb the **5 Material 3 Expressive (May 2025) patterns** Eden lags on, **close the dense-enterprise data-table gap** vs Polaris/Carbon/USWDS, and **ship a hand-rolled spring-physics animation token library** that future Eden widgets can compose from — all **additive, backwards-compatible, and aesthetically consistent** with the Eden warm-luxe identity.

Every existing widget continues to work unchanged. Every improvement is a new variant, a new widget, or a new token class — never a fork, never a parallel library.

## Why now

Per `VERTICAL_UX_RESEARCH_2026-05-16.md` §0 finding 4 + §2.1.1:
- Material 3 Expressive (May 2025) shipped 5 patterns that are now table-stakes: **button groups, split buttons, FAB menus, loading indicators, spring-physics motion**. Eden currently uses Material-2-era `CircularProgressIndicator`, time-based curves only, and ships no button-group / split-button / generic-FAB-menu primitives.
- Per §2.1.1 + §2.2 row 1, `EdenDataTable` is sparse-friendly only — the **single biggest competitive gap** vs Square/Shopify POS + Epic chart screens (40-60 visible rows, sticky headers, freeze-pane on col 1, bulk-select). Closing this requires only an additive `.dense` constructor.
- Per §2.2 rows 3/4/5/9/10: micro-interactions on cards, skeleton-to-content morph, illustrated empty states, and status-dot overlays are all S-effort wins with 7/7 vertical leverage.

## Scope

10 TRDs across 3 waves. Aligned to user-supplied wave structure.

| Wave | TRD | Component | Effort |
|---|---|---|---|
| **1 — Foundation tokens** | 010-01 | `EdenSprings` token class — hand-rolled spring physics, 4 presets (snap/smooth/bouncy/rubber) | S |
| **2 — M3 Expressive batch (all parallel)** | 010-02 | `EdenButtonGroup` — segmented button group, connected pill cluster, shape-morph on press | M |
| | 010-03 | `EdenSplitButton` — primary action + dropdown menu (`Save / Save & New`) | M |
| | 010-04 | `EdenFabMenu` — expandable FAB with 2-6 action children, spring unfurl | M |
| | 010-05 | `EdenLoadingIndicator` (new variants) — skeleton/cross-fade/shimmer variants for under-5s loads | S |
| **3 — Density + polish (all parallel)** | 010-06 | `EdenDataTable.dense` — 32pt rows + sticky header + freeze-pane col 1 + bulk-select | L |
| | 010-07 | `EdenCard.interactive` — hover lift + ripple + focus ring | S |
| | 010-08 | `EdenSkeletonScope` — skeleton-to-content cross-fade wrapper, composes `EdenSkeleton` | S |
| | 010-09 | `EdenEmptyState` enhancement — illustration slot + secondary action variant | S |
| | 010-10 | `EdenStatusDotOverlay` — composable overlay (online/offline/away/busy/sync/unread-count) on any widget | XS |

## Dependency on objective 009

Obj 010 consumes `EdenThemeProfile` + `EdenStatusPalette` from obj 009 where applicable:
- `EdenButtonGroup` / `EdenSplitButton` / `EdenFabMenu` read primary + container colors from `Theme.of(context)` — already profile-aware via obj 009.
- `EdenDataTable.dense` density tokens may read `EdenSpacing.spaceHalf = 2` from obj 009 (TRD 009-05) when present; gracefully degrades to current `space1 = 4` when absent.
- `EdenStatusDotOverlay` reads status colors via `Theme.of(context).extension<EdenStatusPalette>()` if present, else falls back to `EdenColors.success/warning/error/info` constants.
- **If 009 has not shipped before 010 execution starts:** TRD 010-01 (Wave 1) task 0 reads `.planning/objectives/009-vertical-theme-system/` to align on the `EdenStatusPalette` extension shape; widgets gracefully fall back to current static constants. No 010 TRD blocks on 009.

## Critical constraints

- **Backwards-compatible.** Every existing widget continues to work unchanged. New variants opt-in.
- **No new pubspec deps.** Spring physics hand-rolled — Flutter ships `SpringSimulation` + `SpringDescription` in `package:flutter/physics.dart`. No `rive`, no `lottie`, no `animations` package additions.
- **Profile-aware where applicable.** Density adjustments + status colors come from obj 009's `EdenStatusPalette` + density tokens (graceful fallback when absent).
- **Aesthetic preservation.** Polish should feel like Eden, not Material default. Reference `VERTICAL_UX_RESEARCH_2026-05-16.md` §6 "Aesthetic preservation principles" — existing tokens are SoT; M3 is foundation not constraint; variants over forks; profiles not branches; defaults preserve today; aesthetic flexibility ≠ aesthetic abandonment.
- **iPhone-narrow ≥390pt baseline** per `PROJECT.md` Constraints — every new widget renders without `RenderFlex overflowed` at 390pt logical width.
- **Transport-agnostic.** No `dio`, no `http`, no `connectrpc`. Library responsibility unchanged.
- **TDD strict** per user CLAUDE.md TDD Playbook + intent-resolver default. Hand-built fixture builders per `no_llm_test_data` constraint.

## Verification

- All ~1748 existing tests pass unchanged (backwards-compat gate per principle 5).
- Every TDD task ships RED→GREEN→REFACTOR with exit-code evidence.
- Each component: behavioral widget tests + a11y smoke (`Semantics` labels present where applicable).
- Visual catalog: extend `lib/dev_app/screens/buttons_screen.dart` + `data_display_screen.dart` + `misc_screen.dart` with new variants; NEW `lib/dev_app/screens/motion_screen.dart` for spring/loading demos.
- Export sections: 3 wave-specific headers in `lib/eden_ui.dart`:
  - `// Objective 010 — Visual Polish Pass Wave 1 (Foundation tokens)`
  - `// Objective 010 — Visual Polish Pass Wave 2 (M3 Expressive batch)`
  - `// Objective 010 — Visual Polish Pass Wave 3 (Density + polish)`

## Out of scope

- **Tab indicator spring + ripple polish** (research §3.2 row 11) — deferred. EdenTabs polish is its own micro-objective.
- **Pull-to-refresh haptic + spring** (research §2.1.2) — deferred; needs companion-mode pull-to-refresh primitive first.
- **Success-state morph (checkmark draw-in) on EdenButton** — deferred; layered later as `EdenButton.successMorph` variant.
- **Drag-handle micro-bounce on EdenScheduler event resize handles** — out of scope; lives in obj 004's polish pass.
- **Iconography per-vertical adapter** (research §2.1.3) — deferred to obj 016.
- **Visual regression baseline package** — deferred per PROJECT.md (separate `eden-libs/visual-regression` sibling package).

## Aesthetic preservation gate (per §6 principles)

| Principle | Application in this objective |
|---|---|
| 1. Existing tokens are SoT | `EdenSprings` extends pattern of `EdenDurations` (named constants, no inline magic numbers). No new color hex values introduced. |
| 2. M3 is foundation, not constraint | M3 Expressive components absorbed; M3 `ColorScheme` still drives all color resolution. |
| 3. Variants over forks | `EdenDataTable.dense`, `EdenCard.interactive`, `EdenEmptyState` enhancement — all additive constructors / params, never parallel widgets. |
| 4. Profiles, not branches | Spring physics + density tokens cooperate with obj 009's profile system; no new top-level theme. |
| 5. Defaults preserve today | Every new variant default = current behavior. `EdenDataTable()` unchanged; only `EdenDataTable.dense(...)` is new. |
| 6. Aesthetic flexibility ≠ abandonment | Spring physics gives the *feel* of M3 Expressive without abandoning Eden's `easeOutExpo` cubic-bezier (kept as default for non-spring callers). |

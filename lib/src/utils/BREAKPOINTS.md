# Eden UI Flutter — Breakpoint Vocabulary

Canonical 5-tier Material 3 breakpoint set for `eden-ui-flutter`. All tokens
live in `lib/src/widgets/eden_app_mode.dart`. Use these tokens for all
viewport-width comparisons inside `lib/src/`.

## Tiers

| Token | Value (pt) | Tier | Use For |
|-------|-----------|------|---------|
| `kEdenAppModeNarrowMax` | 480 | Narrow (strict phone) | iPhone SE-class narrow guards: stack actions vertically, collapse multi-pane scaffolds. |
| `kEdenAppModeCompactMax` | 600 | Compact (M3) | Material 3 Compact tier upper bound. Below this: field-companion / phone-class chrome. |
| `kEdenAppModeExpandedMin` | 840 | Expanded (M3) | Material 3 Expanded tier lower bound. At/above: tablet-landscape or larger; admin chrome default. |
| `kEdenAppModeDenseDesktopMin` | 1100 | Dense desktop | Toolbar-collapse floor: at/above, toolbars can show expanded labels; below, collapse to icon-only. |
| `kEdenAppModeFullDesktopMin` | 1200 | Full desktop | Multi-pane fully-expanded floor: at/above, three-pane / canvas layouts can fully expand. |

Decision-source for Compact (600) and Expanded (840): COMPANION_UX_PATTERNS_2026-05-15.md §0 lock E.

## How to pick

1. Stacking actions vertically on narrow phones only? → `kEdenAppModeNarrowMax`
2. Switching between field-companion and tablet-or-larger chrome? → `kEdenAppModeCompactMax` (M3 Compact) or `kEdenAppModeExpandedMin` (M3 Expanded)
3. Collapsing a toolbar to icon-only on dense desktop? → `kEdenAppModeDenseDesktopMin`
4. Three-pane layout vs stacked? → `kEdenAppModeFullDesktopMin`

## One-offs (NOT canonical tiers)

These breakpoints appear in a handful of sites and are NOT canonical tiers.
Keep them as inline literals with `// breakpoint: <value> — <reason>` comments.
Do NOT add tokens for them.

- **390pt** — iPhone Pro / SE viewport width simulation (dev_app demo widths only).
- **768pt** — Legacy M2-era tablet floor; `EdenRoleDashboardShell.tabletBreakpoint` default.
- **800pt** — Sales-analytics tablet floor.
- **900pt** — Two/three-pane fold thresholds for individual components (route-optimization, price-book, intake-form).
- **1024pt** — Tablet-landscape floor for POS/analytics/dispatch/quick-add components.
- **1280pt** — Dispatch full-desktop / EdenScheduler default-fallback width.

## Legacy: `EdenResponsive`

`lib/src/utils/responsive.dart` provides a legacy `EdenResponsive` class
with M2-era breakpoints (mobileMax 768 / tabletMax 1024 / desktopMax 1280).
It is `@Deprecated` as of 2026-05-18. New code MUST use the `kEdenAppMode*`
tokens above. Downstream consumers (eden-biz-flutter, eden-platform-flutter)
should migrate at their next refactor pass.

## File layout

- **Token home:** `lib/src/widgets/eden_app_mode.dart`
- **Reference consumer:** `lib/src/widgets/eden_adaptive_layout.dart` (shows the import + comparison pattern).
- **This doc:** `lib/src/utils/BREAKPOINTS.md`

## Source

This vocabulary was consolidated in `.planning/quick/6-unify-breakpoint-vocabulary-in-eden-ui-f/`
based on the breakpoint-fragmentation note in
`.planning/quick/dev-catalog-visual-audit-2026-05-18.md` Section "Breakpoint
vocabulary note".

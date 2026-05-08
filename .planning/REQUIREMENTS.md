# Requirements: eden-ui-flutter

**Defined:** 2026-05-07
**Core Value:** Predictable, accessible widget primitives that downstream apps can compose without inheriting platform/transport concerns. Widget regressions in this lib propagate to every downstream Eden app — every widget must survive iPhone-narrow viewports without overflow.

## v1 Requirements

### Responsive Layout (RESP)

- [x] **RESP-01** — `EdenPageHeader` Row layout no longer overflows on iPhone-narrow viewports (≥390pt logical width). The current outer `Row` places title-Column + actions-Row side-by-side; on narrow screens with 2-3 actions, the actions Row crowds out the title's Expanded width. Fix: introduce `LayoutBuilder` + threshold (480pt) that stacks actions below the title block on narrow viewports while preserving the original side-by-side layout on wide. Verification: new widget test pumps the widget at 390pt logical width with 3 actions and asserts no `RenderFlex overflowed` exceptions.
- [x] **RESP-02** — Widget test infrastructure for the responsive iPhone-narrow case is in place: shared helper or pattern for setting `tester.view.physicalSize` to iPhone-narrow + asserting no layout overflow. Mirrors the spike's `tester.view.physicalSize = const Size(1170, 2532)` workaround pattern but flips it — assert PASSES at 390pt without widening.
- [x] **RESP-03** — Test added explicitly catches the wide path too — `EdenPageHeader` rendered at desktop width (≥1024pt) preserves the side-by-side layout. Both paths covered by separate tests.

## v2 Requirements

Deferred to future release. Tracked but not in current roadmap.

### Visual Regression (VRT)

- **VRT-01** — Golden file baselines for all eden_*_test.dart widgets at iPhone-narrow + iPad-portrait + desktop widths (3 viewport baselines). Defer until Eden visual identity is stable enough that pixel-diffs aren't constant noise.

### Cross-Platform Render (XPL)

- **XPL-01** — Widget render gates run on all 6 supported platforms in CI (iOS, Android, macOS, Windows, Linux, web). Currently widgets are tested on host VM only; downstream apps own platform-specific rendering checks.

## Out of Scope

| Feature | Reason |
|---------|--------|
| Business logic in widgets | This lib is transport-agnostic; orchestration belongs in `eden-platform-flutter` |
| Network / Auth / Persistence | Forbidden by package responsibility |
| Storybook-style published catalog | Internal `just dev-ui` is sufficient; no public hosting |
| Real-device iOS / Android testing | Sim coverage is the gate; downstream apps own real-device testing of their composites |
| Visual regression baselines | Out of scope for v1 — defer to v2's VRT-01 |

## Traceability

| Requirement | Tracked via | Status |
|-------------|-------------|--------|
| RESP-01 | quick task (TBD) | Complete |
| RESP-02 | quick task (TBD) | Complete |
| RESP-03 | quick task (TBD) | Complete |

**Coverage:** All 3 v1 requirements scope tightly into a single quick task (`/devflow:quick`) — 1 widget file + 1 widget test file, <100 LOC. They do NOT warrant a full objective with research/verification ceremony per the Triage Heuristic in ROADMAP.md.

---
*Requirements defined: 2026-05-07*
*Last updated: 2026-05-07 — collapsed Objective 1 ceremony into a quick task track*

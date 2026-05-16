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
- [ ] 002-04-TRD.md — EdenFieldViewGate (Wave 2; donor trades-react FieldViewGate.tsx; companionOnly + adminOnly inline gates)
- [ ] 002-06-TRD.md — EdenGpsStatusIndicator (Wave 2; cross-vertical promotion per P-17 evidence; T/F/M/G verticals)
- [ ] 002-05-TRD.md — EdenCompanionShell (Wave 3; composes Wave A EdenRoleDashboardShell + EdenNetworkStatusBar + TRD-01/02/03; CRITICAL lock E rule 3 enforcement at 1200pt)

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

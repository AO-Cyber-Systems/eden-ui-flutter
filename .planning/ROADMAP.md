# eden-ui-flutter — Roadmap

## Active Objectives

### Objective 001: Wave A — Cross-vertical fundamentals

**Goal:** Ship the 14 cross-vertical UI primitives + 1 pluggable-map interface that every Eden Biz vertical (salon, trades, fuel, medical, retail, legal, gov) composes its admin and companion surfaces from. See `objectives/001-wave-a-cross-vertical-fundamentals/OBJECTIVE.md`.

**TRDs:** 15 plans across 4 waves (~4-5 wk Claude execution)

TRDs:
- [x] 001-01-TRD.md — A1 EdenListPageScaffold (Wave 1; port trades-flutter)
- [x] 001-02-TRD.md — A2 EdenDetailPageScaffold + EdenDetailHeader (Wave 1; port trades-flutter)
- [x] 001-03-TRD.md — EdenMapProvider interface + value types + NoOpMapProvider (Wave 1; A4 dependency)
- [ ] 001-04-TRD.md — A3 EdenCurrencyDisplay (Wave 2; port + multi-currency enhancement)
- [ ] 001-05-TRD.md — A7 EdenPhoneInput + EdenOtpInput (Wave 2)
- [ ] 001-06-TRD.md — A8 EdenMembershipTierBadge (Wave 2)
- [ ] 001-07-TRD.md — A12 EdenAuthenticatedImage (Wave 2; donor trades-react)
- [ ] 001-08-TRD.md — A13 EdenNetworkStatusBar (Wave 2; donor trades-react)
- [ ] 001-09-TRD.md — A5 EdenConsentFlow (Wave 3; composes eden_signature_pad + eden_form_wizard)
- [ ] 001-10-TRD.md — A6 EdenIntakeForm (Wave 3; composes eden_form_wizard)
- [ ] 001-11-TRD.md — A9 EdenRoleDashboardShell (Wave 3; depends on Wave 1 scaffolds)
- [ ] 001-12-TRD.md — A10 EdenAppTourOverlay + EdenContextualTip + EdenStarterTemplateCard (Wave 3; onboarding triplet, uses showcaseview)
- [ ] 001-13-TRD.md — A11 EdenOfflineQueueViewer (Wave 3; donor trades-flutter field_crew)
- [ ] 001-14-TRD.md — A14 EdenQuickActionBar (Wave 3; donor trades-react)
- [ ] 001-15-TRD.md — A4 EdenAddressInput + EdenMapPreview + RecordingMapProvider (Wave 4; implements TRD-03 interface)

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

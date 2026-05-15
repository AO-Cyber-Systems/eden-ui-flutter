# State: eden-ui-flutter

## Project Reference

See: [`./PROJECT.md`](./PROJECT.md) (updated 2026-05-07)

**Core value:** Predictable, accessible widget primitives that downstream apps can compose without inheriting platform/transport concerns.
**Current focus:** **Objective 001 Wave A — 100% COMPLETE (2026-05-15).** All 15 TRDs GREEN. Waves 1+2+4 (001-01..08 + 001-15) and Wave 3 (001-09..14) shipped in parallel via two coordinated executors. **195 new widget/unit tests across Wave A** (42 Wave 1 + 58 Wave 2 + 70 Wave 3 + 25 Wave 4). Library remains transport-agnostic and SDK-free (no `google_maps_flutter`, `mapbox_gl`, or `maplibre` imports in `lib/`).

## Current Position

- **Milestone:** v1 (initial bootstrap complete)
- **Active objectives:** none — small fixes are tracked as `/devflow:quick` tasks under `.planning/quick/`. Full objectives accrue when scope warrants research / verification ceremony per the ROADMAP Triage Heuristic.
- **Branch:** main (post-bootstrap; quick tasks branch from here as needed)

## Recent Activity

- **2026-05-15:** **Objective 001 Wave 3 complete.** TRD 001-09 (`EdenConsentFlow`, 11 tests; clauses → primary signature → optional witness → review composer over `eden_signature_pad` + custom step machine; captures `List<EdenSignatureStroke>` rather than raster bytes for lossless archival), TRD 001-10 (`EdenIntakeForm`, 14 tests; declarative branching questionnaire with 7 question types — text/longText/singleChoice/multipleChoice/number/date/yesNo; visibleWhen predicates against live answers map; save+resume + validation gate + review step), TRD 001-11 (`EdenRoleDashboardShell`, 11 tests; responsive 3-mode layout: 2-col grid+side-rail (tablet+) / 1-col stack+inline-rail (narrow tablet) / 1-col stack+bottom-sheet-trigger (phone <480pt); 8 palette presets; priority-sorted sections), TRD 001-12 (onboarding triplet: `EdenStarterTemplateCard` 5 tests + `EdenContextualTip` 4 tests + `EdenAppTourOverlay` 5 tests; thin Eden wrapper around `showcaseview` with inner-context capture for cross-tree `.of(context)` lookup), TRD 001-13 (`EdenOfflineQueueViewer`, 9 tests; ListView.builder of `EdenOfflineQueueItem` rows with per-row Retry/Discard/Resolve gating + injectable `now` for deterministic relative timestamps; library does NOT persist), TRD 001-14 (`EdenQuickActionBar`, 11 tests; LayoutBuilder inline-vs-overflow split with `maxInlineActions` override + 99+ badge cap; `IconButton` disabled state for null `onPressed`). **70 new tests, all GREEN.** All widgets composed of existing Eden primitives + Material — no new package dependencies. Three deviations logged: Rule 1 bug fixes for `EdenOfflineQueueViewer` relative-time threshold + `EdenQuickActionBar` cap calculation, plus a Rule 1 test-design test rewrite for `EdenAppTourOverlay` (stub-coincident assertions strengthened with sentinel-text checks). Coordinated with the parallel Wave 4 executor on `lib/eden_ui.dart` via distinct section headers.
- **2026-05-15:** **Objective 001 Wave 4 (A4 capstone) complete.** TRD 001-15 shipped 3 artifacts: `RecordingMapProvider` (test-double EdenMapProvider impl in `lib/` — NOT `test/` — so downstream apps' widget tests can inject it; 6 tests), `EdenMapPreview` (stateless wrapper around `provider.showMap` with optional pin-picker + NoOpMapProvider graceful-degradation Card; 8 tests), and `EdenAddressInput` (5-field address form with hand-rolled debounced autocomplete + provider-driven `resolvePlace` suggestion dropdown; 11 tests). 25 new tests, all GREEN. **All three widgets consume the TRD-03 `EdenMapProvider` interface — no vendor SDK imports.** Library core remains substrate-agnostic per `VERTICAL_COVERAGE_ASSESSMENT_2026-05-15.md` §6 locked decision 3. Follow-up sibling packages (`eden_ui_flutter_map_googlemaps`, `eden_ui_flutter_map_maplibre`) tracked under ROADMAP `v2 Future Objectives`. One deviation (Rule: test-design via TRD recovery clause): EdenAddressInput uses hand-rolled Material(Column) suggestion list instead of `Autocomplete<>` (Overlay unreachable from standard `wrap()` test helper).
- **2026-05-15:** **Objective 001 Wave 2 complete.** TRD 001-04 (`EdenCurrencyDisplay`, 14 tests; multi-currency USD/EUR/GBP/CAD/AUD with hand-rolled symbol map — no `intl` dependency), TRD 001-05 (`EdenOtpInput` 8 tests + `EdenPhoneInput` 8 tests; 8-country v1 picker; transport-agnostic verify-button slot), TRD 001-06 (`EdenMembershipTierBadge`, 10 tests; 5 preset tiers + custom-tier escape hatch for salon/retail/legal/gov), TRD 001-07 (`EdenAuthenticatedImage`, 10 tests; headers map or async headersBuilder; library does NOT mint tokens), TRD 001-08 (`EdenNetworkStatusBar`, 8 tests; 4 states with state-driven API — library does NOT subscribe to connectivity). 58 new tests, all GREEN, transport-agnostic. Two minor deviations logged (001-07 test pivot to structural NetworkImage assertions; 001-08 `pumpAndSettle` → fixed-frame pump).
- **2026-05-15:** **Objective 001 Wave 1 complete.** TRD 001-01 (`EdenListPageScaffold`, 12 tests), TRD 001-02 (`EdenDetailHeader` + `EdenDetailPageScaffold`, 17 tests), TRD 001-03 (`EdenMapProvider` interface + `NoOpMapProvider`, 13 tests). 42 new tests, all GREEN, transport-agnostic. One deviation logged (Rule 1): legacy `EdenMapMarker` from `eden_map_view.dart` collided with the new map-provider `EdenMapMarker` — resolved by hiding the legacy class from the barrel re-export, preserving the legacy file's direct API. See `state.json` deviations array for details.
- **2026-05-07:** Project bootstrapped (commit `2057742`). PROJECT.md (`kind: ui-lib`, `default_work: feature`), config.json, REQUIREMENTS.md (RESP-01..03 + v2 placeholders for VRT-01 + XPL-01), ROADMAP.md (no active objectives — Triage Heuristic + quick-task tracker), STATE.md.
- **2026-05-07:** Objective 1 ceremony walked back. Original scope (`EdenPageHeader` iPhone-narrow Wrap fix) is a single-widget LayoutBuilder swap + 1 widget test file — too small for full plan-objective overhead. Collapsed to a `/devflow:quick` task track per Triage Heuristic.

## Decisions

| Date | Decision | Rationale |
|------|----------|-----------|
| 2026-05-07 | `kind: ui-lib`, `default_work: feature` | Most work is widget additions / responsive fixes / token tweaks |
| 2026-05-07 | Skip research at bootstrap | Stack is locked Flutter+Material; existing 30-widget catalog is the spec |
| 2026-05-07 | RESP-01..03 collapsed to quick task | <200 LOC, 2 files, no architectural decisions, no research needed — fits the Triage Heuristic's `/devflow:quick` band |
| 2026-05-07 | ROADMAP starts with no active objectives | Quick tasks accrue first; objectives form when work clearly spans multiple TRDs |
| 2026-05-15 | Hide legacy `EdenMapMarker` from barrel; keep file-level export | Avoids breaking pre-existing API for direct-file importers while letting the new map-provider `EdenMapMarker` (per TRD 001-03) become the canonical barrel-level export. Lone in-repo consumer (`trades_screen.dart` demo) updated in same commit. |

## Blockers/Concerns

None.

## Next Up

Push `feat/eden-page-header-responsive` + open PR to `main`. Once merged, downstream `eden-biz-flutter` consumers re-pick up the fix via `path:` dep on next `flutter pub get`.

### Quick Tasks Completed

| # | Description | Date | Commit | Directory |
|---|-------------|------|--------|-----------|
| 1 | EdenPageHeader iPhone-narrow LayoutBuilder + 480pt breakpoint fix | 2026-05-07 | 3558da1 | [1-edenpageheader-iphone-narrow-layoutbuild](./quick/1-edenpageheader-iphone-narrow-layoutbuild/) |

---
*Last activity: 2026-05-07 — Completed quick task 1: EdenPageHeader iPhone-narrow LayoutBuilder fix. RED→GREEN: 8/8 new tests pass, 233/233 widget regression preserved, `flutter analyze` clean.*

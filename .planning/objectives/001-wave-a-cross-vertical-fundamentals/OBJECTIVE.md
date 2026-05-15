---
objective: 001-wave-a-cross-vertical-fundamentals
kind: ui-lib
work: feature
status: planned
estimated_effort: 4-5 weeks Claude execution
trd_count: 15
waves: 4
---

# Objective 001 — Wave A: Cross-vertical Fundamentals

## Goal

Ship the 14 cross-vertical UI primitives identified in `VERTICAL_COVERAGE_ASSESSMENT_2026-05-15.md` §3 Wave A (now 14 components after `TRADES_REMAP_DEEP_AUDIT_2026-05-15.md` §5 promoted 6 trades-surfaced primitives to Wave A) plus an `EdenMapProvider` interface that A4 depends on. After this objective ships, every Eden Biz vertical (salon, trades, fuel, medical, retail, legal, gov) can compose its admin and companion surfaces from library primitives without re-inventing the page scaffolds, money rendering, address+map, consent flow, intake form pattern, phone input, membership badge, role dashboard shell, app tour, offline queue viewer, authenticated image, network status bar, or quick action bar.

## Why now

- Salon vertical (next Wave B target per parent assessment §6 locked decision 1) blocks on Wave A scaffolds and currency.
- Trades absorption (`TRADES_REMAP_DEEP_AUDIT` decision 6) needs the trades-flutter shared/widgets to land in the library FIRST so the 32 admin folders can absorb without re-vendoring the scaffolds.
- The 8-component plan in the parent assessment was incomplete — the trades deep audit surfaced 6 additional library-level primitives reused across verticals (role dashboard shell, app tour overlay, offline queue viewer, authenticated image, network status bar, quick action bar). Wave A grows to 14.
- The `EdenMapProvider` interface gates A4 implementation per parent assessment §6 locked decision 3 (pluggable adapter — no hard-coded vendor SDK in the library core).

## Scope (14 components + 1 interface)

| TRD | Component | Donor | Wave |
|---|---|---|---|
| 01 | A1 `EdenListPageScaffold` | trades-flutter `list_page_scaffold.dart` | 1 |
| 02 | A2 `EdenDetailPageScaffold` + `EdenDetailHeader` | trades-flutter `detail_view_scaffold.dart` + `detail_header.dart` | 1 |
| 03 | `EdenMapProvider` interface | New (no impl in lib core) | 1 |
| 04 | A3 `EdenCurrencyDisplay` | trades-flutter `currency_display.dart` | 2 |
| 05 | A7 `EdenPhoneInput` + OTP affordance | New (pattern: trades-react `input-otp.tsx`) | 2 |
| 06 | A8 `EdenMembershipTierBadge` | New | 2 |
| 07 | A12 `EdenAuthenticatedImage` | trades-react `authenticated-image.tsx` | 2 |
| 08 | A13 `EdenNetworkStatusBar` | trades-react `components/layout/NetworkStatusBar.tsx` | 2 |
| 09 | A5 `EdenConsentFlow` | Compose `eden_signature_pad` + `eden_form_wizard` | 3 |
| 10 | A6 `EdenIntakeForm` | Compose `eden_form_wizard` | 3 |
| 11 | A9 `EdenRoleDashboardShell` | trades-react `components/forefront/*` (6 role panels) | 3 |
| 12 | A10 `EdenAppTourOverlay` + `EdenContextualTip` + `EdenStarterTemplateCard` | trades-flutter `onboarding/presentation/{app_tour_overlay,widgets/contextual_tip,widgets/starter_template_card}.dart` | 3 |
| 13 | A11 `EdenOfflineQueueViewer` | trades-flutter `field_crew/presentation/offline_queue_page.dart` + `domain/offline_queue_item_model.dart` | 3 |
| 14 | A14 `EdenQuickActionBar` | trades-react `components/layout/QuickActionBar.tsx` | 3 |
| 15 | A4 `EdenAddressInput` + `EdenMapPreview` + Google reference impl | trades-react `address-fields-group.tsx`, `address-preview-card.tsx`, `map-pin-picker.tsx`, `google-places-autocomplete.tsx`, `navigation-address-field.tsx` | 4 |

## Wave structure (parallelism map)

- **Wave 1 (foundation; 3 TRDs):** 01, 02, 03 — independent. Can run as 3 concurrent executor sessions.
- **Wave 2 (primitives; 5 TRDs):** 04, 05, 06, 07, 08 — depend on tokens only; not on Wave 1. Can run as 5 concurrent executor sessions, **in parallel with Wave 1**.
- **Wave 3 (composers; 6 TRDs):** 09, 10, 11, 12, 13, 14 — depend on Wave 1 scaffolds and/or Wave 2 primitives. Launch once Wave 1 is GREEN.
- **Wave 4 (capstone; 1 TRD):** 15 — implements TRD-03's interface. Designed last so the interface absorbs lessons from every Wave 2-3 consumer.

## Constraints (locked, do not revisit)

1. **TDD strict (Iron Law).** Every TRD's testable tasks carry `tdd="true"`. Test-list checklist required at the top of every TRD. Hand-built fixture builders only (no LLM-generated test data). One test at a time through RED → GREEN → REFACTOR. No batching tests "while we're here." Per `~/.claude/CLAUDE.md` TDD Playbook habits 1-4 + resolver constraints.
2. **Outside-in.** Widget test at the top-level public component → drill into sub-widget tests. iPhone-narrow responsive baseline (≥390pt) MUST be in the test list of every TRD.
3. **Test pattern locked.** `testWidgets('renders ...', (tester) async {...})` with `wrap()` helper at the top of each test file. Mirror `test/widgets/eden_alert_test.dart` shape. Widget tests, NOT integration tests.
4. **Transport-agnostic.** No `dio`, no `http`, no `connectrpc`. No business logic, no auth, no network. Library imports `flutter/material.dart` + `flutter/widgets.dart` + tokens + sibling lib widgets only. Per `PROJECT.md` Constraints.
5. **Material 3 + tokens.** Use `EdenSpacing`, `EdenRadii`, `EdenColors`, `EdenTypography` from `lib/src/tokens/`. No third-party widget libs except those already in `pubspec.yaml` (`google_fonts`, `highlight`, `flutter_highlight`, `showcaseview`).
6. **Visual catalog entry.** Every new component gets a catalog entry under `lib/dev_app/screens/`. Either added to an existing screen (e.g., `inputs_screen.dart`, `layouts_screen.dart`) or a new screen registered in `home_screen.dart`.
7. **Pluggable map adapter (A4).** Library exposes `EdenMapProvider` interface only. Google Maps reference impl ships under `lib/src/widgets/map_providers/google_maps_provider.dart` and is gated behind an optional dependency that downstream apps wire up. Per parent assessment §6 decision 3.
8. **No breaking changes.** All Wave A widgets are net-new; no existing widget signatures change.
9. **File collision (`lib/eden_ui.dart`).** Every TRD appends 1-3 export lines. Mark each TRD's `co_modified_files: [lib/eden_ui.dart]` in frontmatter so the orchestrator serializes the edit step.

## Success criteria (must-haves, observable truths)

1. All 14 new components compile, pass `flutter analyze`, and pass `flutter test`.
2. Every component has a widget test file `test/widgets/eden_<name>_test.dart` using `wrap()` helper.
3. Every component has an iPhone-narrow responsive test (≥390pt logical width, no `RenderFlex overflowed` warnings).
4. Every component is registered in `lib/eden_ui.dart` exports.
5. Every component has a dev catalog entry visible via `just dev-ui`.
6. `EdenMapProvider` interface compiles with NO concrete impl in `eden-ui-flutter` core. Google reference impl ships separately and downstream apps choose whether to depend on it.
7. The 233 existing widget regression tests still pass (no breakage).
8. `just check` passes cleanly on the feature branch.

## Out of scope

- Visual regression baselines (deferred — VRT-01 v2 future objective).
- iOS / Android real-device testing (downstream apps gate this).
- Wave B vertical-specific primitives (salon, trades, fuel, medical, retail, legal) — separate objectives per parent assessment §3.
- Wave C government overlay (separate objective).
- Trades absorption epic (separate eden-biz-flutter objective per `TRADES_REMAP_DEEP_AUDIT` decision 6).
- Any backend/transport/auth work (forbidden by `PROJECT.md`).

## References

- `.planning/PROJECT.md` (constraints, test pattern, validation commands)
- `.planning/VERTICAL_COVERAGE_ASSESSMENT_2026-05-15.md` §3 Wave A + §6 locked decisions
- `.planning/TRADES_REMAP_DEEP_AUDIT_2026-05-15.md` §4 donor map + §5 revised Wave A list + §7 locked decisions
- `~/.claude/CLAUDE.md` TDD Playbook (global)

---
objective: 002-companion-shell-foundation
kind: ui-lib
work: feature
status: planned
estimated_effort: 2-3 weeks Claude execution
trd_count: 6
waves: 3
---

# Objective 002 — Companion Shell Foundation

## Goal

Ship the six runtime primitives that put the locked companion-mode UX decisions (`COMPANION_UX_PATTERNS_2026-05-15.md` §0 locks A–F + `COMPANION_B2_SPEC_2026-05-15.md` §1 + §4) into code. After this objective ships, downstream `eden-platform-flutter` (and `eden-biz-flutter` consumers) can compose a companion-mode app shell out of library primitives without re-implementing the hybrid mode-discrimination algorithm, the Material 3 three-tier responsive split, the mode-toggle escape hatch, the inline gate widget, or the cross-vertical GPS status indicator.

## Why now

- **Companion UX research locked 2026-05-15.** Six A–F decisions captured at commit `f07acc5` are non-negotiable design inputs; this objective is where they become code.
- **Salon + trades P0 Wave B builds gate on Wave A + this foundation.** Without `EdenAppMode`/`EdenCompanionShell`, the vertical-implementation engineers cannot stand up a companion home screen.
- **Wave A primitives just shipped (commit `bcf7904`, 15 TRDs GREEN, 195 tests).** The composers (`EdenRoleDashboardShell`, `EdenNetworkStatusBar`) are now available to compose into `EdenCompanionShell`.
- **`UXModeToggle.tsx` + `FieldViewGate.tsx` donor patterns from trades-react are stable.** Direct port targets exist; no greenfield UX design required.
- **The B2 spec's `resolveAppMode()` algorithm is locked-text-ready** — it just needs to be transliterated to Dart and tested.

## Scope (6 components)

| TRD | Component | Donor / origin | Wave |
|---|---|---|---|
| 01 | `EdenAppMode` enum + `resolveAppMode()` + `EdenAppModeController` + `EdenAppModeScope` (InheritedNotifier) | New (B2 spec §1 algorithm) — Riverpod-friendly via `ChangeNotifier`/`InheritedNotifier`, no riverpod dep | 1 |
| 02 | `EdenAdaptiveLayout` | New (Material 3 three-tier; supersedes/wraps `eden_layout/*`) | 1 |
| 03 | `EdenUxModeToggle` | trades-react `client/src/components/layout/UXModeToggle.tsx` | 2 |
| 04 | `EdenFieldViewGate` | trades-react `client/src/components/FieldViewGate.tsx` | 2 |
| 05 | `EdenCompanionShell` | New (composes Wave A `EdenRoleDashboardShell` + `EdenNetworkStatusBar` + this objective's TRD-03) | 3 |
| 06 | `EdenGpsStatusIndicator` | trades-flutter `field_crew/.../check_in_page.dart` + `COMPANION_UX_PATTERNS_2026-05-15.md` P-17 cross-vertical promotion (fuel/medical/gov demand it) | 2 |

## Wave structure (parallelism map)

- **Wave 1 (foundation; 2 TRDs):** 01, 02 — independent. Run as 2 concurrent executor sessions.
- **Wave 2 (gates + toggles; 3 TRDs):** 03, 04, 06 — all depend on TRD-01's `EdenAppModeController` / `EdenAppModeScope` API. Run as 3 concurrent executor sessions once Wave 1 is GREEN.
- **Wave 3 (composition; 1 TRD):** 05 — composes TRD-01, TRD-02, TRD-03, plus Wave A `EdenRoleDashboardShell` + `EdenNetworkStatusBar`. Sequential.

## Constraints (locked, do not revisit)

1. **TDD strict (Iron Law).** Every TRD's testable tasks carry `tdd="true"`. Test-list checklist required at the top of every TRD. Hand-built fixture builders only (no LLM-generated test data). One test at a time through RED → GREEN → REFACTOR. Per `~/.claude/CLAUDE.md` TDD Playbook habits 1–4 + resolver constraints (`no_llm_test_data`, `no_property_based_default`, `no_gherkin_layer`).
2. **Outside-in.** Widget test at the top-level public component first, then drill into helpers. iPhone-narrow responsive baseline (≥390pt) MUST be in every TRD's test list. TRD-02 additionally tests all three Material 3 tiers (Compact / Medium / Expanded). TRD-05 additionally tests the "companion forces Compact at 1200pt width" invariant per locked decision E.
3. **Test pattern locked.** `testWidgets('renders ...', (tester) async {...})` with `wrap()` helper at the top of each test file. Mirror `test/widgets/eden_alert_test.dart`. Widget tests, NOT integration tests.
4. **Transport-agnostic.** No `dio`, no `http`, no `connectrpc`, no `shared_preferences`, no `flutter_riverpod`. JWT claim values are PASSED IN to `resolveAppMode()`; the library never fetches a JWT. SharedPreferences-equivalent persistence is the consumer's job — the library accepts a `String? persistedAppMode` string and a `ValueChanged<String> onAppModeChange` callback. Per `PROJECT.md` Constraints.
5. **Material 3 + tokens.** Use `EdenSpacing`, `EdenRadii`, `EdenColors`, `EdenTypography` from `lib/src/tokens/`. No third-party widget libs except those already in `pubspec.yaml` (`google_fonts`, `highlight`, `flutter_highlight`, `showcaseview`, `qr_flutter`).
6. **Riverpod-friendly without depending on Riverpod.** Follow the precedent in `lib/src/widgets/eden_async_form_scaffold.dart` — expose a plain `ChangeNotifier`-based controller + `InheritedNotifier` scope; downstream Riverpod users wrap with `ChangeNotifierProvider`. NO `package:flutter_riverpod` import anywhere in the library.
7. **Visual catalog entry.** Every new component gets a catalog entry under `lib/dev_app/screens/`. Either added to an existing screen (`layouts_screen.dart`, `inputs_screen.dart`, `misc_screen.dart`) or a new `companion_screen.dart` registered in `home_screen.dart`.
8. **File collision (`lib/eden_ui.dart`).** Every TRD appends 1–3 export lines under a NEW section header `// Companion Shell Foundation (objective 002)`. Mark each TRD's `co_modified_files: [lib/eden_ui.dart]` in frontmatter so the orchestrator serializes the edit step within a wave.
9. **No breaking changes to Wave A.** Existing `EdenRoleDashboardShell`, `EdenNetworkStatusBar`, etc. signatures DO NOT change. `EdenAdaptiveLayout` may wrap/compose `EdenMobileLayout`/`EdenDesktopLayout` but does not replace them; existing widget call-sites continue to work.
10. **Existing 195 Wave A tests still pass.** This objective is purely additive.

## Success criteria (must-haves, observable truths)

1. All 6 new components compile, pass `flutter analyze`, and pass `flutter test`.
2. Every component has a widget test file `test/widgets/eden_<name>_test.dart` using `wrap()` helper.
3. Every component has an iPhone-narrow responsive test (≥390pt logical width, no `RenderFlex overflowed` warnings).
4. TRD-02 (`EdenAdaptiveLayout`) test list explicitly tests all three Material 3 tiers (Compact `<600pt`, Medium `600–840pt`, Expanded `≥840pt`).
5. TRD-05 (`EdenCompanionShell`) test list explicitly tests that when `mode == fieldCompanion` and viewport width is 1200pt (Expanded by Material 3 size), the shell still renders the Compact / bottom-nav layout (locked decision E — "Companion mode pins to Compact at ALL widths").
6. TRD-01's `resolveAppMode()` test list covers the full B2-spec §1 algorithm: dart-define hard pin → JWT claim hard pin → persisted choice → viewport-driven default (`<600pt` companion, `≥840pt` admin) → ambiguous Medium tier returns `askUser`.
7. Every component is exported under a new `// Companion Shell Foundation (objective 002)` section in `lib/eden_ui.dart`.
8. Every component has a dev catalog entry visible via `just dev-ui`.
9. The 195 existing Wave A widget tests still pass (no breakage).
10. `just check` passes cleanly on the feature branch.
11. No `flutter_riverpod`, `dio`, `http`, `connectrpc`, or `shared_preferences` appears in `pubspec.yaml` after this objective ships.

## Out of scope

- Visual regression baselines (VRT-01 v2 future objective).
- Real-device iOS / Android testing (downstream apps gate this).
- The companion-route allowlist itself (consumer concern per `COMPANION_UX_PATTERNS_2026-05-15.md` Q4 lock — library ships the gate WIDGET, not the route registry).
- First-launch picker dialog (`EdenAppModePicker`) — flagged in B2 spec Q-B2-1; deferred to a follow-on objective unless this objective surfaces a need.
- `VerticalNavSkin` interface (lives in `eden-platform-flutter`, NOT here).
- JWT parsing / SharedPreferences I/O / connectivity polling — all consumer concerns.
- Wave B vertical-specific primitives (separate objectives).

## References

- `.planning/PROJECT.md` (transport-agnostic constraint, test pattern, validation commands)
- `.planning/COMPANION_UX_PATTERNS_2026-05-15.md` §0 (locks A–F), §4 (Path α discrimination), P-11 (mode-toggle), P-17 (GPS status indicator)
- `.planning/COMPANION_B2_SPEC_2026-05-15.md` §1 (locked `resolveAppMode()` algorithm), §4 (revised auth boundary 2026-05-15)
- `.planning/COMPANION_USE_CASE_MATRIX_2026-05-15.md` (primitive coverage validation — UC-02 GPS check-in across T,F,M,G; UC-39 patient identity)
- `.planning/objectives/001-wave-a-cross-vertical-fundamentals/` (canonical TRD shape + Wave A composers `EdenRoleDashboardShell`, `EdenNetworkStatusBar`)
- `~/.claude/CLAUDE.md` TDD Playbook (global)
- Donor: `AOCyber-Trades/trades/client/src/components/layout/UXModeToggle.tsx` (TRD-03 donor)
- Donor: `AOCyber-Trades/trades/client/src/components/FieldViewGate.tsx` (TRD-04 donor)
- Riverpod-without-Riverpod precedent: `lib/src/widgets/eden_async_form_scaffold.dart`

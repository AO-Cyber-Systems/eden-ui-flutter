---
objective: 022-runtime-brand-tokens
job: "022-05"
subsystem: ui
tags: [flutter, theming, runtime-config, dart]

# Dependency graph
requires:
  - objective: 022-01
    provides: theme_back_compat_baseline (frozen fixture + spine test this TRD must not disturb)
  - objective: 022-02
    provides: "EdenBrandSwatch.tryParse — arbitrary hex to 11-shade MaterialColor, null on malformed input"
  - objective: 022-03
    provides: "EdenThemeProfileData.copyWith / .runtime() — runtime profile-data construction from plain values"
  - objective: 022-04
    provides: "EdenProfileFonts.bodyTextStyleForFamily / displayTextStyleForFamily / monoTextStyleForFamily — guarded runtime font resolution"
provides:
  - "EdenAdaptiveTheme.lightFromData / darkFromData — data-taking core accepting a runtime-constructed EdenThemeProfileData"
  - "EdenAdaptiveTheme.lightFromConfig / darkFromConfig — plain-string entry points matching window.APP_CONFIG shape (brandHex, bodyFontFamily, displayFontFamily, base)"
  - "EdenAdaptiveTheme._withDataTextTheme — single TextTheme overlay helper (replaces objective 009's _withProfileTextTheme)"
affects: [runtime-brand-tokens, theme, adaptive-theme]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Enum-taking statics as one-line delegations to a data-taking core (light/dark -> lightFromData/darkFromData)"
    - "Config-shaped entry points (plain runtime strings) delegate to the data-taking core via a private _configData builder, never a parallel theming type"
    - "Malformed runtime input resolved via tryParse-style null-returning parsers, never force-unwrapped — null IS the fallback mechanism"

key-files:
  created:
    - test/theme/eden_adaptive_theme_runtime_test.dart
  modified:
    - lib/src/theme/eden_adaptive_theme.dart

key-decisions:
  - "LOCKED decision 2 honored: EdenAdaptiveTheme was extended, not forked — lightFromData/darkFromData/lightFromConfig/darkFromConfig are all statics on the single existing class; grep -n \"class Eden\" lib/src/theme/eden_adaptive_theme.dart shows exactly one class."
  - "_withProfileTextTheme (objective 009) was CONVERTED, not duplicated, into _withDataTextTheme(ThemeData, EdenThemeProfileData) — grep -c \"_withProfileTextTheme\" lib/src/theme/eden_adaptive_theme.dart returns 0, confirming one overlay helper."
  - "monoFontFamily is deliberately absent from lightFromConfig / darkFromConfig / _configData (LOCKED decision 5 + measurement-driven per TRD anti_patterns): Material's TextTheme has no mono role and EdenProfileFonts.monoTextStyle has zero production call sites, so a mono parameter here would theme nothing while looking finished. Mono stays reachable via EdenThemeProfileData.runtime()'s data field and EdenProfileFonts.monoTextStyleForFamily called directly by a consumer."
  - "Fixed a genuine test-expectation bug in the inherited RED-phase spec (Bug #3): a test asserted textTheme.displayLarge?.fontFamily against the baseline's 'Outfit_800' after applying a non-null (garbage) bodyFontFamily override. The correct, pre-existing behaviour is 'Outfit_regular', because _withDataTextTheme's short-circuit (`data.bodyFontFamily == null && data.displayFontFamily == null`) only skips the overlay when BOTH families are null — a body-only override still triggers the overlay for ALL 15 TextTheme roles, including display, which then resolve displayFontFamily: null through EdenProfileFonts.displayTextStyleForFamily(null) and fall back to GoogleFonts.outfit() -> family 'Outfit_regular', not the ExtraBold 'Outfit_800' file. Pinned the exact literal per TRD verification item 7c (not a contains('Outfit') check) rather than 'fixing' this pre-existing objective-009 behaviour, which is out of scope for this TRD."
  - "The EdenAdaptiveTheme WIDGET constructor (Pattern B, in-tree subtree override) was deliberately NOT extended with data/config variants — only the static factories (Pattern A) gained the new entry points, per the TRD's explicit output requirement."

patterns-established:
  - "Runtime config boot path: a downstream Flutter web app should call EdenAdaptiveTheme.lightFromConfig/darkFromConfig directly with window.APP_CONFIG string values rather than hand-constructing EdenThemeProfileData."

requirements-completed: []

# Verification evidence
verification:
  gates_defined: 2
  gates_passed: 2
  auto_fix_cycles: 0
  tdd_evidence: true
  test_pairing: true

# Metrics
duration: 19min
completed: 2026-08-26
---

# Objective 022, TRD 05: Runtime Config Entry Points for EdenAdaptiveTheme Summary

**`EdenAdaptiveTheme` now exposes a data-taking core (`lightFromData`/`darkFromData`) plus plain-string config entry points (`lightFromConfig`/`darkFromConfig`) that build a complete Eden theme directly from `window.APP_CONFIG`-shaped values — an arbitrary partner hex and an arbitrary font family name — while the existing enum-taking `light`/`dark` statics keep their exact signatures and now delegate to the same core. This is the fifth and final TRD of objective 022.**

## Performance

- **Duration:** ~19 min (commit-to-commit, RED to final test-fix commit) + verification/summary pass
- **Started:** 2026-08-26T20:56:13-04:00 (RED commit `ed5e8a4`)
- **Completed:** 2026-08-26T21:14:46-04:00 (test-fix commit `17627de`) + verification/summary pass
- **Tasks:** 3 (Task 1 RED; Task 2 data-taking-core refactor and Task 3 config entry points landed together in one GREEN commit; one follow-up test-fix commit to close out full GREEN)
- **Files modified:** 2 (`lib/src/theme/eden_adaptive_theme.dart`, `test/theme/eden_adaptive_theme_runtime_test.dart`)

## Accomplishments
- Added `lightFromData` / `darkFromData` as the single data-taking core, accepting a runtime-constructed `EdenThemeProfileData` instead of a fixed `EdenThemeProfile` enum member.
- Refactored the existing enum-taking `light(profile, {brand})` / `dark(profile, {brand})` into one-line delegations to `lightFromData`/`darkFromData` — signatures frozen, unchanged, confirmed via `git diff`.
- Added `lightFromConfig` / `darkFromConfig`, accepting plain runtime strings (`brandHex`, `bodyFontFamily`, `displayFontFamily`, plus a `base` profile default of `commercialWarm`) matching the shape of `window.APP_CONFIG` in a downstream Flutter web app.
- Converted the single private overlay helper `_withProfileTextTheme(ThemeData, EdenThemeProfile)` into `_withDataTextTheme(ThemeData, EdenThemeProfileData)` — one overlay helper, not two.
- Proved both malformed paths (unparsable hex, unrecognized font family) fall back structurally without throwing, and that a valid hex reaches `colorScheme.primary` and survives dark mode's shade dereferences (the `primary[950]!` boot-crash risk named in the TRD).
- Pinned (not fixed) a pre-existing objective-009 display-weight-file downgrade with an exact-string assertion, per TRD verification item 7c.

## Task Evidence

| Task | Verify Command | Exit Code | Status |
|---|---|---|---|
| 1: RED — failing runtime-composition spec (20 Test list items / 21 assertions, 5 groups) | `flutter test test/theme/eden_adaptive_theme_runtime_test.dart` at commit `ed5e8a4` | 1 (compile failure) | FAIL (correct) |
| 2: GREEN — data-taking core refactor (`lightFromData`/`darkFromData`, `light`/`dark` delegation, `_withDataTextTheme`) | `flutter test test/theme/eden_theme_back_compat_test.dart` (gate) then `flutter test test/theme/eden_adaptive_theme_test.dart` then `flutter test test/theme/` then `flutter analyze` then `grep -c "_withProfileTextTheme" lib/src/theme/eden_adaptive_theme.dart` (0) then `git diff` signature check | 0 (all) | PASS |
| 3: GREEN — config entry points (`lightFromConfig`/`darkFromConfig`/`_configData`) | `flutter test test/theme/eden_adaptive_theme_runtime_test.dart` (all 20 green) then `grep -n "monoFontFamily" lib/src/theme/eden_adaptive_theme.dart` (comment-only) then `flutter test test/theme/eden_theme_back_compat_test.dart` then full `flutter test` then `flutter analyze` | 0 (all) | PASS |

## Task Commits

1. **Task 1: RED — add failing test for runtime brand token entry points** - `ed5e8a4e219b22641cc140756857cf3c16ce8d6b` (test), 2026-08-26 20:56:13 -0400 — 325 insertions, new file `test/theme/eden_adaptive_theme_runtime_test.dart`.
2. **Tasks 2+3: GREEN — implement data-taking core and runtime config entry points** - `950a24ffd00515ed53ce23aaecb5476de8815d74` (feat), 2026-08-26 21:14:43 -0400 — `lib/src/theme/eden_adaptive_theme.dart`, 102 insertions / 14 deletions. Bundles both the Task 2 refactor (data-taking core, `_withDataTextTheme` conversion, `light`/`dark` delegation) and the Task 3 config entry points (`lightFromConfig`/`darkFromConfig`/`_configData`), since Task 3 builds directly on Task 2's seam and both were verified together before committing.
3. **Test-fix: correct malformed-config assertion and remove dead font-family loop** - `17627de1ef85434086bb3d4e15465942cffe746b` (test), 2026-08-26 21:14:46 -0400 — `test/theme/eden_adaptive_theme_runtime_test.dart`, 19 insertions / 8 deletions. Fixes Bug #3 (pins the exact `'Outfit_regular'` literal per TRD verification item 7c, replacing an incorrect `'Outfit_800'` expectation) and removes a dead/unused loop variable that was tripping `flutter analyze`'s `unused_local_variable` lint.

_No separate REFACTOR commit — Task 2's work was itself the refactor (converting the enum-taking statics into delegations and merging the two overlay helpers into one); there was no further cleanup needed after GREEN._

## Validation Gate Results

| Gate | Command | Exit Code | Status |
|---|---|---|---|
| lint | `flutter analyze` | 0 | PASS — clean, including the `grep -c "_withProfileTextTheme"` == 0 and `grep -n "monoFontFamily"` comment-only checks |
| test | `flutter test test/theme/ --reporter compact 2>&1 \| tr '\r' '\n' \| tail -5` → `+247: All tests passed!` | 0 | PASS — 226 pre-existing baseline + 21 new (20 Test list items, item 3 splitting into 3 and 3b) = 247, exact match to the required success bar |
| whole-repo diligence | `flutter test --reporter compact 2>&1 \| tr '\r' '\n' \| tail -10` → `+4138 ~3: All other tests passed!` | 0 | PASS — 4138 passed, 3 skipped, 0 failed across the entire repository, confirming the `EdenAdaptiveTheme` refactor did not regress any dev_app catalog screen or other consumer |

## TDD Evidence

| Phase | Command | Exit Code | Expected |
|---|---|---|---|
| RED | `flutter test test/theme/eden_adaptive_theme_runtime_test.dart` at `ed5e8a4` | 1 | FAIL (correct) — see "Issues Encountered" below for the factual basis of this claim |
| GREEN | `flutter test test/theme/eden_adaptive_theme_runtime_test.dart` after `950a24f` + `17627de` | 0 | PASS (correct) — all 20 Test list items / 21 assertions green |
| REFACTOR | `flutter test test/theme/` | 0 | PASS (correct) — folded into the Task 2 GREEN commit; no separate refactor phase was needed |

## Post-TRD Verification

- **Auto-fix cycles used:** 0 (Bug #1 import correction, Bug #2 `wrapWithProfile` positional-args fix, and Bug #3 `Outfit_regular` pin were all resolved as part of reaching GREEN within the normal RED→GREEN→test-fix task flow, not as post-hoc auto-fix cycles against a passing implementation)
- **Must-haves verified:** 4/4 success criteria, 12/12 verification items (10 numbered + 7b + 7c)
  - Success criteria: (1) downstream app builds a complete theme from `window.APP_CONFIG` strings — PASS, `lightFromConfig`/`darkFromConfig` implemented and tested; (2) one theming entry point, enum-taking API unchanged and delegates to the same core — PASS, `light`/`dark` are one-line delegations, signatures unchanged; (3) both malformed paths fall back structurally, cannot crash boot — PASS, Test list items 8-12; (4) `EdenTheme.light()`/`.dark()` with no brand, all five profiles, still byte-identical — PASS, TRD 022-01's baseline green and unmodified.
- **Gate failures:** None

### Verification checklist (TRD `<verification>`, 10 items + 7b + 7c)
1. `flutter analyze` clean — PASS.
2. `flutter test` — the FULL suite green, not just `test/theme/` — PASS (whole-repo: 4138 passed, 3 skipped, 0 failed).
3. `test/theme/eden_theme_back_compat_test.dart` and `test/theme/eden_adaptive_theme_test.dart` are GREEN and show zero diff — PASS, both files untouched (confirmed via file-touch scope) and passing within the 247-green `test/theme/` run.
4. `lightFromConfig(brandHex: '#0F62FE').colorScheme.primary.value == 0xFF0F62FE` — PASS, covered by Test list item(s) in the "window.APP_CONFIG boot path" group.
5. `darkFromConfig(brandHex: '#0F62FE')` constructs — the end-to-end proof that a generated swatch survives `primary[950]!` — PASS, covered by Test list item 2 (the TRD's own "highest-value case in this objective").
6. Malformed `brandHex` and malformed font family each fall back with no throw, and the resulting theme equals the base profile's rather than being silently degraded — PASS, "malformed config survives boot" group (Test list items 8-12) asserts both `returnsNormally` AND equality to the fallback theme, not just "did not throw."
7. `grep -n "class Eden" lib/src/theme/eden_adaptive_theme.dart` shows ONE class — PASS, no parallel runtime theming type; LOCKED decision 2 honored.
7b. `lightFromConfig`, `darkFromConfig`, `_configData` have NO `monoFontFamily` parameter, doc comment states why — PASS, `grep -n "monoFontFamily" lib/src/theme/eden_adaptive_theme.dart` returns only the doc-comment lines on `lightFromConfig` explaining the absence; mono remains reachable via `EdenProfileFonts.monoTextStyleForFamily` and `EdenThemeProfileData.runtime`'s data field.
7c. `lightFromConfig(bodyFontFamily: 'Inter').textTheme.displayLarge` has family exactly `'Outfit_regular'`, size `48.0`, weight `w800` — PASS, this is the exact assertion Bug #3 corrected the test file to make (pinned literal, not `contains('Outfit')`).
8. `grep -c "_withProfileTextTheme" lib/src/theme/eden_adaptive_theme.dart` == 0 — PASS, one overlay helper (`_withDataTextTheme`).
9. `git diff` across the whole objective contains no `ThemeExtension` addition, no `EdenRadii`/`EdenColors` call-site edit, and no reference to the four inert profile tokens outside `eden_theme_profile.dart`'s existing declarations — PASS, this TRD's diff touches only `lib/src/theme/eden_adaptive_theme.dart` and the one test file; grep confirms no such additions.
10. If any local visual check is performed with the dev_app, it uses port 8091, port 8080 is permanently forbidden — PASS trivially: no visual/dev_app check was performed for this TRD; all verification is `flutter test`/`flutter analyze`.

## Files Created/Modified
- `lib/src/theme/eden_adaptive_theme.dart` (237 lines, +102/-14) — Adds `lightFromData`/`darkFromData` (data-taking core), `lightFromConfig`/`darkFromConfig` (plain-string config entry points), `_configData` (private builder routing `EdenBrandSwatch.tryParse` into `EdenThemeProfileData.runtime`); converts `_withProfileTextTheme` into `_withDataTextTheme`; refactors `light`/`dark` into one-line delegations to the new core with unchanged signatures.
- `test/theme/eden_adaptive_theme_runtime_test.dart` (created in Task 1 at 325 lines, corrected in the test-fix commit, +19/-8) — 21-assertion / 20-Test-list-item spec across 5 groups (`window.APP_CONFIG boot path`, `malformed config survives boot`, `data-taking core`, `existing API unchanged`, `mono is data, not a theme parameter`), looping all five profiles via `ProfileFixtures.allProfilesInLockedOrder`.

## Decisions Made
- Landed Task 2 (data-taking-core refactor) and Task 3 (config entry points) in a single GREEN commit rather than two, since Task 3's `_configData` builds directly on Task 2's `lightFromData`/`darkFromData` seam and splitting them would have left an intermediate commit with `lightFromConfig` referenced by no code path yet.
- Chose to describe the RED-phase failure factually from diff evidence (the four static methods did not exist on the class until the GREEN commit, confirmed via the immediately-prior commit `e7503e1` being objective 009's original implementation without them) rather than fabricate literal console text never actually captured — this also matches the TRD's own Task 1 `<verify>` wording exactly ("FAILS to compile on the four missing statics").
- Kept the enum-taking `light`/`dark` bodies as single-expression delegations (`=> lightFromData(profile.data, brand: brand?.color);`) rather than the TRD suggestion text's `_dataFor(profile, brand)` intermediate helper — functionally identical, one fewer private helper, and `resolvedBrand = brand ?? data.primaryColor` is computed inline inside `lightFromData`/`darkFromData` where it is shared by both the enum-taking and config-taking callers.

## Deviations from Plan

### Auto-fixed Issues

**1. [Import correction] Wrong package import in the inherited RED-phase test file**
- **Found during:** Task 1 (RED) — initial review of the inherited test-file draft before running it.
- **Issue:** Test file imported the package under an incorrect path rather than `package:eden_ui_flutter/eden_ui.dart`.
- **Fix:** Corrected the import statement.
- **Files modified:** `test/theme/eden_adaptive_theme_runtime_test.dart`.
- **Committed in:** `ed5e8a4` (part of the Task 1 RED commit — the test file's first commit already carried the correct import).
- **TRD text impact:** None — this is a mechanical correction with no bearing on the TRD's substantive requirements.

**2. [Test API mismatch] `ProfileFixtures.wrapWithProfile` called with named arguments instead of positional**
- **Found during:** Task 1 (RED) — same pre-flight review.
- **Issue:** The helper's real signature (`test/theme/_fixtures/profile_fixtures.dart`) takes two positional parameters (`EdenThemeProfile profile, Widget child`); the draft test called it with named arguments.
- **Fix:** Switched all call sites to positional arguments.
- **Files modified:** `test/theme/eden_adaptive_theme_runtime_test.dart`.
- **Committed in:** `ed5e8a4` (part of the Task 1 RED commit).
- **TRD text impact:** None — mechanical correction, no substantive change to what is being tested.

**3. [Test-expectation correctness] `displayLarge.fontFamily` pinned to `'Outfit_800'` instead of the actual `'Outfit_regular'`**
- **Found during:** Task 3 (GREEN) — running the full 20-item spec after implementing `lightFromConfig`/`darkFromConfig`.
- **Issue:** A test in the "existing API unchanged" / exact-string-pin group asserted `theme.textTheme.displayLarge?.fontFamily` equal to the baseline's ExtraBold file (`'Outfit_800'`) after applying `lightFromConfig(bodyFontFamily: 'Inter')`. This is incorrect: `_withDataTextTheme`'s short-circuit (`data.bodyFontFamily == null && data.displayFontFamily == null`) requires BOTH families to be null to skip the overlay. A body-only override (even with `displayFontFamily` left null) still triggers the overlay for all 15 `TextTheme` roles, including the display roles, which then resolve through `EdenProfileFonts.displayTextStyleForFamily(null)` and fall back to `GoogleFonts.outfit()` — family `'Outfit_regular'`, not `'Outfit_800'`. The `FontWeight.w800` *request* survives (carried by the base `TextStyle`'s weight, preserved by `TextStyle.merge`'s base-supplies-weight/overlay-supplies-family convention) even though the ExtraBold *file* is dropped.
- **Fix:** Pinned the exact literal `'Outfit_regular'` (per TRD verification item 7c — an exact-string pin, not `contains('Outfit')`), with an explanatory code comment documenting the mechanism so a future reader does not "fix" this back to `'Outfit_800'` and silently break the pin.
- **Files modified:** `test/theme/eden_adaptive_theme_runtime_test.dart`.
- **Verification:** `flutter test test/theme/eden_adaptive_theme_runtime_test.dart` — all 20 items green; `flutter test test/theme/` — 247/247; whole-repo — 4138 passed / 0 failed.
- **Committed in:** `17627de` (test-fix commit).
- **TRD text impact:** This is exactly the behaviour the TRD's `<output>` block calls out as follow-up #2 (see "Next Objective Readiness" below) — pre-existing, objective-009 behaviour that predates this TRD and must be pinned, not fixed, here.

**4. [Dead code cleanup] Unused loop variable tripping `flutter analyze`**
- **Found during:** Task 3 (GREEN) — running `flutter analyze` as part of the validation gate.
- **Issue:** An inert `for (final family in _allFontFamilies(theme.textTheme)) { ... }` loop in the test file had a loop variable that was never used inside the loop body — the actual assertion work was already being done by a subsequent `_expectSameFontFamilies(...)` call, making the loop vestigial.
- **Fix:** Removed the dead loop.
- **Files modified:** `test/theme/eden_adaptive_theme_runtime_test.dart`.
- **Verification:** `flutter analyze` — clean, zero new issues.
- **Committed in:** `17627de` (test-fix commit, bundled with the Bug #3 fix since both were addressed in the same pass).
- **TRD text impact:** None — pure cleanup, no assertion coverage lost (the removed loop asserted nothing that `_expectSameFontFamilies` did not already cover).

---

**Total deviations:** 4 auto-fixed (2 mechanical test-authoring corrections in Task 1, 1 test-expectation correctness fix in Task 3 documenting genuine pre-existing behaviour, 1 dead-code cleanup in Task 3).
**Impact on plan:** No scope creep. All four fixes are confined to the one test file this TRD owns; none altered `lib/src/theme/eden_adaptive_theme.dart`'s behaviour or any other file. Deviation #3 is the most substantive — it corrects the test to match reality rather than changing reality to match a mistaken test, consistent with the TRD's explicit instruction that this pre-existing font-downgrade behaviour must be pinned, not "fixed," in this TRD.

## Issues Encountered
The literal RED-phase console/compiler output from Task 1 was not preserved verbatim. It is documented here factually from commit-diff evidence instead of being reconstructed or fabricated: the Task 1 commit (`ed5e8a4`) added only the 325-line test file, which references `EdenAdaptiveTheme.lightFromData`, `.darkFromData`, `.lightFromConfig`, `.darkFromConfig` — none of which existed on the class at that point. The commit immediately prior to `ed5e8a4` that touched `lib/src/theme/eden_adaptive_theme.dart` is `e7503e1` ("feat(009-05): implement EdenAdaptiveTheme composition wrapper with profile-aware TextTheme overlay"), objective 009's original implementation, which confirms none of the four statics existed before this TRD. Running `flutter test test/theme/eden_adaptive_theme_runtime_test.dart` at `ed5e8a4` would therefore have failed via Dart analysis/compile errors ("isn't defined for the type 'EdenAdaptiveTheme'") for each of the four undefined static members — exit code 1, a compile failure rather than a runtime assertion failure. This is exactly the failure mode the TRD's own Task 1 `<verify>` text names: "`flutter test test/theme/eden_adaptive_theme_runtime_test.dart` FAILS to compile on the four missing statics." No other issues were encountered; all three commits and both diligence test runs (scoped `test/theme/` and whole-repo) are confirmed green.

## User Setup Required
None — no external service configuration required.

## Next Objective Readiness

**This completes objective 022 (5 of 5 TRDs done): 022-01 (frozen back-compat baseline), 022-02 (`EdenBrandSwatch`), 022-03 (`EdenThemeProfileData.runtime`), 022-04 (runtime font-family resolution), 022-05 (this TRD — the `EdenAdaptiveTheme` data-taking core and config entry points that tie all four prior TRDs together).**

Per the TRD's `<output>` block, three follow-ups are recorded explicitly:

1. **The `EdenAdaptiveTheme` WIDGET constructor was deliberately not extended.** Only the static factories (Pattern A — `MaterialApp.theme`) gained `lightFromData`/`darkFromData`/`lightFromConfig`/`darkFromConfig`. The widget constructor (Pattern B — in-tree subtree override) still takes only `profile`/`brand`/`child`, unchanged.

2. **Display-weight downgrade (pre-existing, now pinned).** Any body-font override defeats the overlay short-circuit, so `displayLarge` resolves to the `Outfit_regular` FILE while still carrying a `FontWeight.w800` REQUEST — the ExtraBold face is dropped. This predates objective 022 (it already affects `medicalInstitutional`, `govFederal`, and `legalProfessional` under objective 009) and TRD 022-01's baseline records it. Fixing it means threading the base role's `fontWeight` into `displayTextStyleForFamily`; that is a behaviour CHANGE and belongs in its own objective, not here. Raised here as a follow-up, not fixed.

3. **`monoFontFamily` is absent from `lightFromConfig`/`darkFromConfig` by design.** Measurement: zero production callers of `EdenProfileFonts.monoTextStyle`; no mono role on Material's `TextTheme`. The route that remains open: `EdenProfileFonts.monoTextStyleForFamily`, plus the data field on `EdenThemeProfileData.runtime`. If a mono `TextTheme` role ever lands, the parameter can be added together with a test that proves it changes the returned theme.

**Project-state note (not introduced by this TRD):** `.planning/STATE.md` contains zero references to "022" anywhere, and its "Current focus" field still describes objective 021 (marked complete 2026-05-17). `.planning/ROADMAP.md`'s five TRD checkboxes for objective 022 (022-01 through 022-05) all remain unchecked (`[ ]`) despite 022-01 through 022-04 already having completed, committed `SUMMARY.md` files on disk before this TRD began. `.planning/REQUIREMENTS.md` is an older, unrelated document (RESP-01/02/03, all complete, tracked via `quick-1`) with no entries for objective 022 at all. This indicates the `state advance-job` / `state update-progress` / `roadmap update-job-progress` / `requirements mark-complete` df-tools commands have not been reflecting progress into these three files across this entire objective's execution — a pre-existing pattern, not something this TRD's execution caused. See the state-update command output captured immediately after this SUMMARY was committed for this TRD's own attempt at these commands.

No blockers for any downstream consumer. A downstream Flutter web app can now call `EdenAdaptiveTheme.lightFromConfig(brandHex: window.APP_CONFIG.brandHex, bodyFontFamily: window.APP_CONFIG.bodyFontFamily, displayFontFamily: window.APP_CONFIG.displayFontFamily)` directly at boot.

---
*Objective: 022-runtime-brand-tokens*
*Completed: 2026-08-26*

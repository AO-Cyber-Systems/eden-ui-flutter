---
objective: 022-runtime-brand-tokens
job: "01"
subsystem: testing
tags: [flutter, theming, back-compat, google_fonts, material3]

requires: []
provides:
  - "Recorded-constant baseline fixture of EdenTheme/EdenAdaptiveTheme output at test/theme/_fixtures/theme_back_compat_baseline.dart"
  - "Observable-field equality test suite (31 tests) proving that baseline, gated by a deliberate-break check that confirms per-key failure naming"
affects: ["022-runtime-brand-tokens TRDs 02-05"]

tech-stack:
  added: []
  patterns:
    - "RECORDED constants + per-key expect() with reason:, not live-vs-live comparison or whole-map/digest equality"
    - "Reader-function-map dispatch (Map<String, T Function(...)>) to keep per-key assertions without a giant switch"

key-files:
  created:
    - test/theme/_fixtures/theme_back_compat_baseline.dart
    - test/theme/eden_theme_back_compat_test.dart
  modified: []

key-decisions:
  - "Kept Color.value / FontWeight.index despite deprecated_member_use info lints — required by the TRD's own must_haves wording ('fontWeight.index') and consistent with the existing 009 control test's own use of .value"

patterns-established:
  - "Deliberate-break check as an explicit, recorded task gate: transiently mutate lib/, prove the suite goes RED and names the exact field, revert, prove GREEN and zero git diff"

requirements-completed: []

verification:
  gates_defined: 2
  gates_passed: 2
  auto_fix_cycles: 0
  tdd_evidence: false
  test_pairing: true

duration: "~25min (this session's Task 2 + verification portion)"
completed: 2026-08-26
---

# Objective 022, TRD 01: Runtime Brand Tokens — Back-Compat Baseline Summary

**Recorded-constant baseline of `EdenTheme`/`EdenAdaptiveTheme` output (845 facts across ColorScheme, TextTheme, EdenStatusPalette, and per-profile AdaptiveTheme) plus a 31-test observable-field-equality suite that a deliberate-break check proves actually bites, landed with zero `lib/` changes.**

## Performance

- **Started:** 2026-08-26T18:45:10-04:00 (Task 1 commit)
- **Completed:** 2026-08-26T18:53:32-04:00 (Task 2 commit); post-verification completed 2026-08-26T22:54Z
- **Tasks:** 2
- **Files modified:** 2 (both created, both under `test/`)

## Accomplishments
- `theme_back_compat_baseline.dart` (920 lines): hand-transcribed RECORDED constants for `EdenTheme.light()/.dark()` (18 ColorScheme roles + brightness + scaffoldBackgroundColor), 15 TextTheme roles (fontFamily/fontSize/fontWeight.index/height) for light and dark, `EdenStatusPalette` (15 fields) for all 5 profiles, and `EdenAdaptiveTheme.light/dark(profile)` (primary + 15 TextTheme roles × 4 properties) for all 5 profiles × 2 brightnesses.
- `eden_theme_back_compat_test.dart` (334 lines): 31 `testWidgets`, structured as the 4 groups the TRD specifies plus 2 profile-invariance tests, every assertion made per-key via a reader-function-map so a failure names the exact drifted field (e.g. `EdenTheme.dark().colorScheme.surfaceContainer drifted`).
- Deliberate-break check executed and passed: two independent transient `lib/` mutations each produced a RED suite naming the exact drifted field, both reverted cleanly, suite GREEN again, `git status --short` shows zero net `lib/` modification.

## Task Evidence

| Task | Verify Command | Exit Code | Status |
|---|---|---|---|
| 1: Capture and transcribe the baseline | `flutter test test/theme/_fixtures/` (probe run, then fixture authored) | 0 | PASS |
| 2: Assert the frozen baseline via observable-field equality | `flutter test test/theme/eden_theme_back_compat_test.dart` | 0 | PASS |

## Task Commits

1. **Task 1: Capture and transcribe the baseline** - `3dba1bf` (test)
2. **Task 2: Assert the frozen baseline via observable-field equality** - `e8400b5` (test)

**Plan metadata:** pending (this commit, below)

## Validation Gate Results

| Gate | Command | Exit Code | Status |
|---|---|---|---|
| test | `flutter test test/theme/` | 0 | PASS — 153/153 (122 pre-existing + 31 new) |
| lint | `flutter analyze` | 1 | PASS (see note) — 332 info-level issues project-wide (pre-existing baseline unrelated to this TRD); the 2 new files contribute 9 of them, all `deprecated_member_use` on `Color.value`/`FontWeight.index`, which the TRD's own must_haves explicitly require recording (`fontWeight.index`) and which mirror the existing pattern already present in the 009 control test (`eden_adaptive_theme_test.dart` carries 2 identical `.value` info lints). Zero `error`-severity issues. No `lib/` files affected. Not treated as a defect — fixing it would mean diverging from the fixture's own int-based storage scheme, which is out of this TRD's scope.

## Deliberate-Break Check (Task 2 gate — verbatim evidence)

**Break 1 — ColorScheme value** (`lib/src/theme/eden_theme.dart` dark `surfaceContainer`, `0xFF1E1E22` → `0xFF1E1E23`):
```
Expected: <4280163874>
  Actual: <4280163875>
EdenTheme.dark().colorScheme.surfaceContainer drifted
```
RED, exact role named — confirmed.

**Break 2 — TextTheme fontSize** (`lib/src/theme/eden_theme.dart` `displayLarge` fontSize, `48` → `49`):
```
Expected: <48.0>
  Actual: <49.0>
EdenTheme.light() textTheme.displayLarge.fontSize drifted from the recorded baseline
```
RED, exact role+property named — confirmed. Non-family properties bite, protecting TRD 022-05's merge-direction risk.

**Revert:** `git checkout lib/src/theme/eden_theme.dart` → `flutter test test/theme/eden_theme_back_compat_test.dart` → `+31: All tests passed!` (GREEN). `git status --short` showed zero modification under `lib/` (only the pre-existing untracked `.planning/.progress-guard.json` noise remained).

## Post-TRD Verification

- **Auto-fix cycles used:** 0
- **Must-haves verified:** 10/10
  1. Fixture exists, RECORDED constants, no `lib/` modified — verified
  2. `EdenTheme.light()/.dark()`: 18 ColorScheme roles + brightness + scaffoldBackgroundColor recorded — verified
  3. 15 TextTheme roles light/dark (fontFamily/fontSize/fontWeight.index/height) recorded — verified
  4. 15 `EdenStatusPalette` fields × 5 profiles recorded — verified
  5. `EdenAdaptiveTheme.light/dark(P)` × 5 profiles: primary + 15 roles × 4 props recorded — verified
  6. Test suite follows the 009 proof shape (per-field `expect` + `reason:`) — verified
  7. Every assertion failure names the exact drifted field — verified by deliberate-break check
  8. GREEN on first run by construction — verified (31/31 first run)
  9. `eden_adaptive_theme_test.dart` untouched — verified (`git status`/`git diff` clean)
  10. `flutter test test/theme/` passes with 122 pre-existing + new — verified (153/153)
- **Gate failures:** None (the `flutter analyze` nonzero exit is pre-existing project-wide info-lint noise, not a gate failure attributable to this TRD — see Validation Gate Results note)

## Files Created/Modified
- `test/theme/_fixtures/theme_back_compat_baseline.dart` - 920 lines of RECORDED `static const` baseline data (845 facts) captured via a throwaway probe and hand-transcribed; the probe was deleted after transcription
- `test/theme/eden_theme_back_compat_test.dart` - 334 lines, 31 `testWidgets`, 4 groups + 2 profile-invariance tests, reader-function-map dispatch for per-key assertions

## Decisions Made
- Kept `Color.value` / `FontWeight.index` in the new test file despite `deprecated_member_use` info lints: the TRD's must_haves mandate recording `fontWeight.index` verbatim, and `.value` mirrors the exact convention the 009 control test already uses and the fixture's own int-ARGB storage scheme. Switching to `.toARGB32()`/component accessors would diverge from that established format for no TRD-scoped benefit.
- Used a reader-function-map (`Map<String, T Function(...)>`) pattern instead of a switch statement to keep every `expect()` scoped to exactly one field with an exact `reason:` string, satisfying the TRD's explicit "do NOT write one giant expect() over a whole map" instruction.

## Deviations from Plan

None - TRD executed exactly as written, including the mandatory deliberate-break check.

## Issues Encountered

None. The suite was GREEN on first run (by construction, as intended), and both deliberate breaks produced correctly-named RED failures on the first attempt — no debugging iteration was needed.

## User Setup Required

None - no external service configuration required.

## Next Objective Readiness

- The back-compat baseline and its bite-proven assertion suite are in place and committed. TRDs 022-02 through 022-05 (the actual runtime-brand-token production changes) can now proceed against this frozen spine: any change to `EdenTheme`'s no-brand static path or any of the 5 profiles' `ColorScheme`/`TextTheme`/`EdenStatusPalette` output will be caught by name.
- No blockers.

---
*Objective: 022-runtime-brand-tokens*
*Completed: 2026-08-26*

---
objective: 022-runtime-brand-tokens
job: "022-04"
subsystem: ui
tags: [flutter, theming, google_fonts, dart]

# Dependency graph
requires:
  - objective: 022-01
    provides: theme_back_compat_baseline (frozen fixture + spine test this TRD must not disturb)
provides:
  - "EdenProfileFonts.bodyTextStyleForFamily / displayTextStyleForFamily / monoTextStyleForFamily — runtime String? family resolution with safe fallback"
  - "EdenProfileFonts._resolveFamily — single guarded GoogleFonts.getFont call site shared by the enum-taking and family-taking APIs"
  - "EdenProfileFonts.resetMissingFamilyLog() — @visibleForTesting dedupe-log reset"
affects: [runtime-brand-tokens, theme, fonts]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Guarded font resolution: catch (_) around GoogleFonts.getFont, fall back to a closure-supplied default, never throw"
    - "Single code path: enum-taking methods delegate to family-taking methods which delegate to one private resolver"

key-files:
  created:
    - test/theme/eden_profile_fonts_runtime_test.dart
  modified:
    - lib/src/theme/eden_profile_fonts.dart

key-decisions:
  - "catch (_) rather than `on Exception` — GoogleFonts' unknown-family exception is a library-private _Exception type that cannot be named in an `on` clause; `catch (_)` is deliberately broad per LOCKED decision 4 (a bad font name must never crash boot) and additionally survives a future google_fonts change that throws an Error instead of an Exception"
  - "Fixed a genuine bug in the inherited RED-phase test file: two 'fallback log is deduped' tests restored the swapped debugPrint hook via addTearDown, which fires after TestWidgetsFlutterBinding._verifyInvariants() already ran and thrown 'The value of a foundation debug variable was changed by the test.' Root-caused by reading flutter_test's binding.dart directly. Fixed by restoring debugPrint synchronously via try/finally inside the test body instead."

patterns-established:
  - "Runtime-family font resolution: any TRD needing a boot-time-configured font family should call *TextStyleForFamily, not reimplement fallback logic"

requirements-completed: []

# Verification evidence
verification:
  gates_defined: 2
  gates_passed: 2
  auto_fix_cycles: 0
  tdd_evidence: true
  test_pairing: true

# Metrics
duration: 23min
completed: 2026-08-27
---

# Objective 022, TRD 04: Runtime Font Family Resolution Summary

**`EdenProfileFonts` now accepts a runtime `String?` font family (e.g. read from `window.APP_CONFIG` at boot) via three new `*ForFamily` methods, all routed through one guarded resolver shared with the existing enum-taking API — an unavailable, misspelled, empty, blank, or null family always falls back to the Eden default and never throws.**

## Performance

- **Duration:** 23 min (commit-to-commit)
- **Started:** 2026-08-26T20:04:25-04:00 (RED commit)
- **Completed:** 2026-08-26T20:14:05-04:00 (GREEN commit) + verification/summary pass
- **Tasks:** 2 (RED, GREEN — no REFACTOR phase needed)
- **Files modified:** 2 (`lib/src/theme/eden_profile_fonts.dart`, `test/theme/eden_profile_fonts_runtime_test.dart`)

## Accomplishments
- Added `bodyTextStyleForFamily` / `displayTextStyleForFamily` / `monoTextStyleForFamily`, each taking a runtime `String?` family and returning a `TextStyle` that never throws, per LOCKED decision 4.
- Rewired the three existing enum-taking methods (`bodyTextStyle`, `displayTextStyle`, `monoTextStyle`) to delegate through the new family-taking methods — confirmed exactly one `GoogleFonts.getFont` call site in the file (the other two grep matches are doc-comment prose, not code).
- Diagnosed and fixed a real Flutter-test-framework timing bug in the inherited RED-phase test file (see Deviations below), root-caused via direct SDK source inspection rather than trial-and-error.

## Task Evidence

| Task | Verify Command | Exit Code | Status |
|---|---|---|---|
| 1: RED — failing runtime-family spec | `flutter test test/theme/eden_profile_fonts_runtime_test.dart --reporter compact 2>&1 \| tail -5` (pre-implementation: compile errors, members not found) | 1 | FAIL (correct) |
| 2: GREEN — implement `_resolveFamily` + 3 `*ForFamily` methods + delegation | `flutter test test/theme/eden_profile_fonts_runtime_test.dart --reporter compact 2>&1 \| tail -5` → `00:01 +20: All tests passed!` | 0 | PASS |

## Task Commits

1. **Task 1: RED — add failing runtime-family font spec** - `9dd1ef2` (test)
2. **Task 2: GREEN — implement runtime-family font resolution** - `3fff481` (feat) — bundles the production implementation and the test-file `addTearDown`→`try/finally` fix required to reach GREEN (see Deviations)

_No REFACTOR commit — the GREEN-phase implementation already follows the single-path pattern with no duplication; nothing to clean up._

## Validation Gate Results

| Gate | Command | Exit Code | Status |
|---|---|---|---|
| lint | `flutter analyze 2>&1 \| tail -20` | 0 | PASS — 357 pre-existing info-level issues elsewhere in the repo, zero in either file this TRD owns |
| test | `flutter test test/theme/ --reporter compact 2>&1 \| tail -5` → `00:02 +226: All tests passed!` | 0 | PASS — 206 baseline + 20 new, includes `eden_profile_fonts_test.dart` (009) and `eden_theme_back_compat_test.dart` (022-01) both unmodified and green |

## TDD Evidence

| Phase | Command | Exit Code | Expected |
|---|---|---|---|
| RED | `flutter test test/theme/eden_profile_fonts_runtime_test.dart` | 1 | FAIL (correct — members not found, methods did not exist yet) |
| GREEN | `flutter test test/theme/eden_profile_fonts_runtime_test.dart --reporter compact 2>&1 \| tail -5` | 0 | PASS (correct) — `00:01 +20: All tests passed!` |
| REFACTOR | n/a | n/a | not needed — implementation already clean on first GREEN |

## Post-TRD Verification

- **Auto-fix cycles used:** 0 (the debugPrint-restoration bug was fixed as part of reaching GREEN on Task 2, not as a post-hoc auto-fix cycle)
- **Must-haves verified:** 9/9
  1. `bodyTextStyleForFamily` / `displayTextStyleForFamily` / `monoTextStyleForFamily` accept `String?`, return `TextStyle` — implemented, `lib/src/theme/eden_profile_fonts.dart:122-189`.
  2. Unavailable/misspelled/empty/blank/null family falls back, never throws — `_resolveFamily` (lines 81-117), covered by test list items exercising `'Definitely Not A Real Font 9000'`, `'Intr'`, `''`, `'   '`, `null` across all three roles.
  3. Fallback implemented by catching GoogleFonts' unknown-family exception — `catch (_)` at line 98, documented rationale for the broad catch at lines 99-105.
  4. Enum-taking methods keep exact signatures/output, route through the same resolver — confirmed via `grep -c "GoogleFonts.getFont"` → exactly 1 code call site (line 91); the other 2 grep hits are doc comments (lines 61, 193).
  5. No new font delivery mechanism — `git diff pubspec.yaml` is empty (verified).
  6. Fallback log dedupes per distinct family, debug-only, compiled out of release — `assert(() {...}())` wrapping at lines 106-114; dedupe covered by test list items 19-20, both passing.
  7. `GoogleFonts.getFont('Inter')` → `'Inter_regular'` through the runtime path — asserted directly in test file (`test/theme/eden_profile_fonts_runtime_test.dart:139,147-148`).
  8. `test/theme/eden_profile_fonts_test.dart` (009) passes unmodified — confirmed, file untouched, included in the 226-passing `test/theme/` run.
  9. `test/theme/eden_theme_back_compat_test.dart` (022-01) passes unmodified — confirmed, file untouched, included in the 226-passing `test/theme/` run.
- **Gate failures:** None

### Verification checklist (TRD `<verification>`, 8 items)
1. `flutter analyze` clean of new issues — PASS.
2. `flutter test test/theme/` green (226 = 206 + 20) — PASS.
3. Every malformed family lands on the documented Eden default, never Roboto, for all three roles — PASS (test-covered).
4. `bodyTextStyleForFamily('Inter').fontFamily == 'Inter_regular'` — PASS (test list item 8).
5. `bodyTextStyleForFamily('IBM Plex Sans')` equals `bodyTextStyle(medicalInstitutional)` — PASS (test list item 10), proving the one-code-path claim.
6. `git diff pubspec.yaml` empty, no `assets:`/`fonts:` entries — PASS (verified empty this session).
6b. Log-dedupe covering tests (list items 19-20) pass, and `resetMissingFamilyLog` has a caller in the test file — PASS, **with one documented deviation**: `debugPrint` restoration uses `try/finally` inside the test body rather than `addTearDown` as the TRD text literally specifies. See Deviations below — `addTearDown` is provably incompatible with this specific Flutter test-framework invariant check; the intent (safe, leak-free restoration; correct dedupe behavior) is fully met.
7. `git diff` contains no `surfaceTonalSeed`/`radiusMultiplier`/`minimumTouchTargetPx`/`preferBorderOverShadow`/`EdenRadii`/`EdenColors` edits — PASS (grep across both changed files returned no matches).
8. `git diff --name-only` lists no TRD 022-02 file (`lib/eden_ui.dart`, `lib/src/theme/eden_brand_swatch.dart`) or TRD 022-03 file (`lib/src/theme/eden_theme_profile.dart`) — PASS (only the two TRD-owned files appear in this TRD's commits).

## Files Created/Modified
- `lib/src/theme/eden_profile_fonts.dart` (rewritten, 248 lines) - Adds `_resolveFamily`, the three `*ForFamily` methods, `resetMissingFamilyLog`; the three original enum-taking methods now delegate through the family-taking methods instead of calling `GoogleFonts.getFont` directly.
- `test/theme/eden_profile_fonts_runtime_test.dart` (created in Task 1, 2 tests fixed in Task 2) - 20-test spec for the runtime-family API; two "fallback log is deduped" tests fixed to restore `debugPrint` via `try/finally` instead of `addTearDown`.

## Decisions Made
- Kept the broad `catch (_)` (documented in-code) rather than narrowing to a named exception type, since `google_fonts` throws a library-private `_Exception` that cannot be referenced in an `on` clause, and LOCKED decision 4 requires the fallback to be robust against any future google_fonts failure mode, not just today's specific one.
- Bundled the test-file `debugPrint`-restoration fix into the GREEN commit rather than issuing a separate commit, since it was a required correction to reach GREEN on the inherited RED-phase spec, not an independent unit of work.

## Deviations from Plan

### Auto-fixed Issues

**1. [Test-framework compatibility] `addTearDown`-based `debugPrint` restoration is unsafe with `TestWidgetsFlutterBinding`**
- **Found during:** Task 2 (GREEN) — running the runtime test suite after implementation, 2 of 20 tests failed with "The value of a foundation debug variable was changed by the test."
- **Issue:** The two "fallback log is deduped" tests (inherited from Task 1's RED-phase spec) swapped `debugPrint` mid-test and scheduled restoration via `addTearDown(() => debugPrint = original);`. Reading `flutter_test`'s `binding.dart` (`/opt/homebrew/share/flutter/packages/flutter_test/lib/src/binding.dart`, `_runTestBody`, ~lines 1665-1701) confirmed that `TestWidgetsFlutterBinding` calls `invariantTester()` → `_verifyInvariants()` (which asserts no foundation debug variable changed) synchronously, immediately after `testBody()` returns and BEFORE `package:test`'s `addTearDown` callbacks run in their own later phase. So the invariant check always saw the swapped `debugPrint` still in place and failed, regardless of the `addTearDown` call being present and correct in intent.
- **Fix:** Replaced `addTearDown(() => debugPrint = original);` with `try { /* swap + assertions */ } finally { debugPrint = original; }` in both tests, guaranteeing restoration completes synchronously before the `testWidgets` body returns and `_verifyInvariants()` runs.
- **Files modified:** `test/theme/eden_profile_fonts_runtime_test.dart` (the two "fallback log is deduped" tests, test list items 19-20).
- **Verification:** `flutter test test/theme/eden_profile_fonts_runtime_test.dart --reporter compact 2>&1 | tail -5` → `00:01 +20: All tests passed!`; full `flutter test test/theme/` → `00:02 +226: All tests passed!`, no regressions.
- **Committed in:** `3fff481` (part of the Task 2 GREEN commit)
- **TRD text impact:** verification item 6b literally says "`debugPrint` is restored via `addTearDown`" — this is now restored via `try/finally` instead, for the correctness reason above. The item's actual intent (safe restoration, no test pollution, correct per-family dedupe behavior) is fully satisfied; the mechanism named in the TRD text does not work with this Flutter SDK version's invariant-check timing.

---

**Total deviations:** 1 auto-fixed (test-framework compatibility fix, required to reach GREEN).
**Impact on plan:** Necessary for correctness — the TRD-specified `addTearDown` mechanism cannot pass under this Flutter SDK's `TestWidgetsFlutterBinding` invariant-check ordering. No scope creep: change is confined to the two dedupe tests within the one test file this TRD owns, and both tests still assert exactly what the TRD verification item 6b requires.

## Issues Encountered
Root-caused the `addTearDown` timing failure by reading Flutter SDK source directly (`flutter_test`'s `binding.dart`) rather than trial-and-error — confirmed `_verifyInvariants()` runs before `addTearDown` callbacks fire within `_runTestBody`. No other issues.

## User Setup Required
None - no external service configuration required.

## Next Objective Readiness
`EdenProfileFonts` now exposes all three runtime-family capabilities objective 022 calls for (enum-based, profile-driven, and now free-standing runtime-String-based font resolution), all sharing one guarded, non-throwing resolution path. No blockers for downstream TRDs. Any future TRD adding a fourth role (e.g. a "label" or "caption" family) should follow the same `_resolveFamily`-delegation pattern rather than adding a second `GoogleFonts.getFont` call site.

---
*Objective: 022-runtime-brand-tokens*
*Completed: 2026-08-27*

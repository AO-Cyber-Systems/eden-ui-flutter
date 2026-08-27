---
objective: 022-runtime-brand-tokens
trd: "022-03"
job: "022-03"
subsystem: theme
tags: [flutter, theming, immutable-value-types, copyWith, material3]

# Dependency graph
requires:
  - objective: 022-runtime-brand-tokens
    provides: "022-01 frozen back-compat baseline (test/theme/eden_theme_back_compat_test.dart + _fixtures/theme_back_compat_baseline.dart) that this TRD's diff must not disturb"
provides:
  - "EdenThemeProfileData.copyWith({profile, primaryColor, density, bodyFontFamily, displayFontFamily, monoFontFamily}) — pass-through copy for the four inert tokens"
  - "EdenThemeProfileData.runtime({base, primaryColor, bodyFontFamily, displayFontFamily, monoFontFamily}) — static factory building profile data from plain runtime values, starting from a named base profile's canonical data"
  - "27-test suite (test/theme/eden_theme_profile_runtime_test.dart) covering const-instance stability, copyWith pass-through, runtime() construction, and inert-token preservation"
affects: [022-04-profile-fonts, 022-05]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "runtime() delegates to copyWith() on base.data — one code path, not two parallel implementations"
    - "Preserve-never-expose: inert fields (surfaceTonalSeed, radiusMultiplier, minimumTouchTargetPx, preferBorderOverShadow) are passed through as unconditional pass-through lines in copyWith's constructor call, with zero corresponding named parameter on either copyWith or runtime"
    - "Deliberate asymmetric surface exposure: density is a copyWith parameter (Dart-literal API) but absent from runtime (the config surface reachable from window.APP_CONFIG), documented in a doc comment rather than left for a future reader to rediscover"

key-files:
  created:
    - test/theme/eden_theme_profile_runtime_test.dart
  modified:
    - lib/src/theme/eden_theme_profile.dart

key-decisions:
  - "runtime() takes a `base: EdenThemeProfile` (default commercialWarm) and layers overrides via copyWith, rather than building a from-scratch instance — guarantees a runtime instance always carries a real enum member, so EdenStatusPalette.forProfile keeps resolving and no sixth profile is ever created"
  - "monoFontFamily is carried on runtime() as a plain data field, not applied to any ThemeData — Material's TextTheme has no mono role, so theming it would be dishonest; a consumer reads the field or calls EdenProfileFonts.monoTextStyleForFamily directly (cross-referenced to TRD 022-05's decision to keep monoFontFamily off EdenAdaptiveTheme.lightFromConfig)"
  - "copyWith cannot clear a nullable field back to null (omission means 'keep current value'); documented in the doc comment rather than adding a sentinel-wrapper type — callers needing an explicit null use the public const constructor directly"

patterns-established:
  - "Pattern: preserve-never-expose for declared-but-unread fields — carry them through copy/factory operations unconditionally, never give them a parameter, until a consumer actually reads them"

requirements-completed: []  # No `requirements` field present in this TRD's frontmatter; none to mark complete.

# Verification evidence
verification:
  gates_defined: 2
  gates_passed: 2
  auto_fix_cycles: 0
  tdd_evidence: true
  test_pairing: true

# Metrics
duration: 20min
completed: 2026-08-26
---

# Objective 022 TRD 03: Runtime Theme Profile Construction Summary

**Added `EdenThemeProfileData.copyWith(...)` and the static `EdenThemeProfileData.runtime({base, primaryColor, bodyFontFamily, displayFontFamily, monoFontFamily})` factory, letting a downstream app build profile data from plain runtime values while the four inert tokens (surfaceTonalSeed, radiusMultiplier, minimumTouchTargetPx, preferBorderOverShadow) pass through unconditionally and stay unexposed as parameters on both members.**

## Performance

- **Duration:** ~20 min (RED commit → GREEN commit gap ~7m22s, plus context-loading, evidence capture, and SUMMARY authoring)
- **Started:** 2026-08-26T19:32:17-04:00 (RED commit `7c2845c`)
- **Completed:** 2026-08-26T19:39:39-04:00 (GREEN commit `91aabe5`)
- **Tasks:** 2
- **Files modified:** 2 (1 created, 1 modified)

## Accomplishments
- `EdenThemeProfileData.copyWith` — full field-set pass-through copy, exposing 6 of 10 fields as settable parameters (`profile`, `primaryColor`, `density`, `bodyFontFamily`, `displayFontFamily`, `monoFontFamily`) and passing the other 4 through unconditionally
- `EdenThemeProfileData.runtime` — static factory delegating to `copyWith` on `base.data`, giving downstream apps a config-shaped entry point that always carries a real `EdenThemeProfile` enum value
- 27-test suite proving: the five `const` instances and the enum are untouched (spine), `copyWith` changes only what it's told to, `runtime()` matches `commercialWarmData` field-by-field with no args, and all four inert tokens survive both operations across all five profiles without ever being settable

## Task Evidence

| Task | Verify Command | Exit Code | Status |
|---|---|---|---|
| 1: Write the failing runtime-profile spec | `flutter test test/theme/eden_theme_profile_runtime_test.dart` | 1 (compile failure — correct for RED) | PASS |
| 2: Add copyWith and the runtime factory to EdenThemeProfileData | `flutter test test/theme/eden_theme_profile_runtime_test.dart` | 0 | PASS |

## Task Commits

Both tasks were committed atomically:

1. **Task 1: Write the failing runtime-profile spec** - `7c2845c` (test)
2. **Task 2: Add copyWith and the runtime factory to EdenThemeProfileData** - `91aabe5` (feat)

**Plan metadata:** commit pending (this SUMMARY)

## Validation Gate Results

| Gate | Command | Exit Code | Status |
|---|---|---|---|
| lint | `flutter analyze lib/src/theme/eden_theme_profile.dart test/theme/eden_theme_profile_runtime_test.dart` | 1 (6 info-level `prefer_const_declarations` hints, all in the test file at lines 82/98/114/146/156/180; 0 issues in the production file; no warnings or errors) | PASS |
| test | `flutter test test/theme/` | 0 (206/206 — 179 baseline + 27 new) | PASS |

## TDD Evidence

| Phase | Command | Exit Code | Expected |
|---|---|---|---|
| RED | `flutter test test/theme/eden_theme_profile_runtime_test.dart` (against pre-implementation `eden_theme_profile.dart`, reconstructed via `git show 91aabe5~1:...` and restored after capture) | 1 | FAIL (correct) — compile errors: `Member not found: 'EdenThemeProfileData.runtime'` and 7× `The method 'copyWith' isn't defined for the type 'EdenThemeProfileData'`; `00:00 +0 -1: Some tests failed.` |
| GREEN | `flutter test test/theme/eden_theme_profile_runtime_test.dart` | 0 | PASS (correct) — `00:00 +27: All tests passed!` |
| REFACTOR | N/A | — | Not needed; implementation matched the TRD's specified code verbatim on first pass, no cleanup required |

## Post-TRD Verification

- **Auto-fix cycles used:** 0
- **Must-haves verified:** 9/9
  1. `copyWith(...)` returns a new instance, named overrides applied, everything else carried over — verified by "copyWith pass-through" group (6 tests) plus 5× "preserves all four inert tokens" tests
  2. `runtime({base, primaryColor, bodyFontFamily, displayFontFamily, monoFontFamily})` builds from plain values starting from a named base's canonical data — verified by "runtime() factory" group (5 tests)
  3. `copyWith`/`runtime` preserve the 4 inert tokens by pass-through and expose no parameter for any of them — verified by construction (no such named argument compiles) and by the "inert tokens preserved, not settable" group (11 tests); confirmed by inspection that neither member's parameter list contains `surfaceTonalSeed`, `radiusMultiplier`, `minimumTouchTargetPx`, or `preferBorderOverShadow`
  4. The five `const` static instances are byte-for-byte unchanged, still `const` — verified by `flutter analyze` reporting no const-ness errors and by "const instances unchanged" group (5 tests); `git diff` on `eden_theme_profile.dart` is purely additive (68 insertions, 0 deletions)
  5. `EdenThemeProfile` enum unchanged — 5 members, LOCKED order — verified by `EdenThemeProfile.values` equality against `ProfileFixtures.allProfilesInLockedOrder` and `.length == 5`
  6. `EdenThemeProfileDataLookup.data` still returns the same const instance per enum member — verified by the `identical()` check on `govFederal`
  7. A runtime instance carries a real `EdenThemeProfile` so `EdenStatusPalette.forProfile` still resolves — verified by the `runtime(base: govFederal, bodyFontFamily: 'Inter')` test asserting palette equality
  8. `test/theme/eden_theme_profile_test.dart` (objective 009) passes unmodified — verified as part of the 206/206 `flutter test test/theme/` run; file untouched (not in `git diff`)
  9. `test/theme/eden_theme_back_compat_test.dart` (TRD 022-01) passes unmodified — verified as part of the same 206/206 run; file untouched (not in `git diff`)
- **Gate failures:** None

## TDD Exceptions
None — both tasks followed strict RED → GREEN TDD.

## Files Created/Modified
- `test/theme/eden_theme_profile_runtime_test.dart` - New 310-line, 27-test suite (4 groups: const instances unchanged, copyWith pass-through, runtime() factory, inert tokens preserved/not settable) using plain `test(...)` per the TRD's guidance for this file
- `lib/src/theme/eden_theme_profile.dart` - Added `copyWith(...)` instance method and `static runtime({...})` factory to `EdenThemeProfileData` (68 lines added, 0 removed, 0 changed elsewhere)

## Decisions Made
See `key-decisions` in frontmatter: `runtime()` delegates to `copyWith` on `base.data` (single code path); `monoFontFamily` stays a data-only field on `runtime()`, not themed; `copyWith`'s null-clearing limitation is documented rather than worked around with a sentinel type.

## Deviations from Plan
None - TRD executed exactly as written. The implemented code matches the TRD's Task 2 verbatim code block with no discrepancies.

## Issues Encountered
None.

## User Setup Required
None - no external service configuration required.

## Next Objective Readiness
- 022-04 (profile fonts) and 022-05 can now build on `EdenThemeProfileData.runtime(...)` as the runtime-construction entry point.
- `monoFontFamily`'s data-only status is documented in-line and cross-referenced to TRD 022-05, which is expected to make the corresponding decision on `EdenAdaptiveTheme.lightFromConfig` explicitly rather than rediscovering it.
- No blockers. Objective 0b (wiring the 4 inert tokens + `density` into `ThemeExtension`/widget call sites) remains explicitly out of scope and untouched.

---
*Objective: 022-runtime-brand-tokens*
*Completed: 2026-08-26*

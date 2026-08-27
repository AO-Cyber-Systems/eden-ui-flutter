---
objective: 022-runtime-brand-tokens
job: "022-02"
subsystem: ui
tags: [flutter, dart, theming, color, material-design, hsl]

# Dependency graph
requires:
  - objective: 022-runtime-brand-tokens
    provides: "022-01 frozen back-compat baseline (theme_back_compat_baseline.dart fixtures + eden_theme_back_compat_test.dart) that this TRD must not disturb"
provides:
  - "EdenBrandSwatch.tryParse(String?) -> MaterialColor?: lenient hex parser (#RRGGBB, RRGGBB, #RGB, RGB, #AARRGGBB, AARRGGBB, case-insensitive, whitespace-tolerant) that never throws"
  - "EdenBrandSwatch.fromColor(Color) -> MaterialColor: HSL-lightness-ramp generator producing all 11 Material shades (50..950) anchored so shade 500 equals the input exactly"
  - "lib/eden_ui.dart now exports src/theme/eden_brand_swatch.dart"
affects: [022-03-theme-profile, 022-04-profile-fonts, 022-05]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "HSL lightness-ramp swatch generation anchored at the seed's own lightness, with load-bearing clamps on lightEnd/darkEnd to prevent ramp inversion near white/black"
    - "Lenient hex-string parsing guarded by an anchored ^[0-9A-Fa-f]+$ regex applied BEFORE int.tryParse, closing the signed-hex-string parsing hole"

key-files:
  created:
    - lib/src/theme/eden_brand_swatch.dart
    - test/theme/eden_brand_swatch_test.dart
    - test/theme/_fixtures/brand_swatch_fixtures.dart
  modified:
    - lib/eden_ui.dart

key-decisions:
  - "Implemented the TRD's pre-researched algorithm exactly as specified — did not re-derive the HSL ramp math or tolerance constants"
  - "Asserted saturation preservation with closeTo(expected, 1e-12) rather than equality, per the TRD's measured 1-2 ULP quantization drift on shades 400/900/950 for #FF0000/#00FF00"
  - "Left lib/src/theme/eden_brand_preset.dart and the 15-preset registry completely untouched (verified via empty git diff)"

patterns-established:
  - "Pattern: hex-color parsers in this repo should validate with an anchored hex-digit regex before calling int.tryParse(_, radix: 16), since tryParse silently accepts a leading +/- sign"

requirements-completed: []  # No `requirements` field present in this TRD's frontmatter; none to mark complete.

# Verification evidence
verification:
  gates_defined: 2
  gates_passed: 2
  auto_fix_cycles: 0
  tdd_evidence: true
  test_pairing: true

# Metrics
duration: 25min
completed: 2026-08-26
---

# Objective 022, TRD 022-02: Runtime Brand Swatch Generator Summary

**`EdenBrandSwatch.tryParse`/`fromColor` add a lenient hex parser plus an HSL-lightness-ramp 11-shade `MaterialColor` generator (shade 500 exact, shade 950 present for `EdenTheme.dark()`), exported from `lib/eden_ui.dart` with zero changes to the 15-preset registry or the 022-01 back-compat baseline.**

## Performance

- **Duration:** 25 min
- **Started:** 2026-08-26T22:58:00Z
- **Completed:** 2026-08-26T23:22:44Z
- **Tasks:** 2 (RED, GREEN — no REFACTOR phase needed)
- **Files modified:** 4 (1 created source file, 1 modified export file, 2 created test files)

## Accomplishments
- `EdenBrandSwatch.tryParse(String?)` accepts 6 hex forms (3-digit/6-digit/8-digit, with/without `#`, case-insensitive, whitespace-tolerant) and returns `null` — never throws — for any malformed input, including the signed-hex-string parsing hole (`'-0F62FE'`, `'+0F62FE'`, etc.) closed via an anchored `^[0-9A-Fa-f]+$` regex guard applied before `int.tryParse`.
- `EdenBrandSwatch.fromColor(Color)` generates all 11 Material shades (50 through 950) via an HSL lightness ramp anchored at the input's own lightness, with load-bearing clamps (`lightEnd`, `darkEnd`) preventing ramp inversion for near-white/near-black inputs.
- Shade 500 is assigned directly from the seed color (never round-tripped through HSL), so it is bit-exact, and the `MaterialColor`'s own primary value equals shade 500.
- Verified against the TRD's pre-measured Carbon Blue (`#0F62FE`) golden ramp — all 11 shades reproduced exactly.
- `lib/eden_ui.dart` now exports the new file; `lib/src/theme/eden_brand_preset.dart` and its 15-preset registry are completely untouched (confirmed via empty `git diff`).
- Zero regressions: all 153 pre-existing `test/theme/` tests (122 + 31 back-compat) plus the new 26 tests pass — 179/179 total.

## Task Evidence

| Task | Verify Command | Exit Code | Status |
|---|---|---|---|
| 1: Write failing test suite for EdenBrandSwatch | `flutter test test/theme/eden_brand_swatch_test.dart` | 1 | FAIL (correct — RED) |
| 2: Implement EdenBrandSwatch HSL ramp generator | `flutter test test/theme/eden_brand_swatch_test.dart` | 0 | PASS (correct — GREEN, 26/26) |

## Task Commits

Each task was committed atomically:

1. **Task 1: Add failing test for EdenBrandSwatch** - `afeb0f4` (test)
2. **Task 2: Implement EdenBrandSwatch HSL ramp generator** - `453433e` (feat)

**Plan metadata:** (this commit) - `docs(022-02): complete runtime brand swatch generator`

_Note: no REFACTOR commit — the GREEN implementation required no cleanup; tests passed on first attempt._

## Validation Gate Results

| Gate | Command | Exit Code | Status |
|---|---|---|---|
| lint | `flutter analyze lib/src/theme/eden_brand_swatch.dart lib/eden_ui.dart` | 0 | PASS (1 pre-existing-pattern info: `deprecated_member_use` on `.value`, sanctioned by TRD gotchas for repo consistency; 0 errors) |
| test | `flutter test test/theme/` | 0 | PASS (179/179 — 153 pre-existing + 26 new, zero regressions) |

Full-repo `flutter analyze` baseline cross-check: 350 pre-existing info/warning-level issues repo-wide, 0 errors; the `.value` deprecation notice matches an existing pattern already present in 61 other locations (e.g. `test/widgets/eden_tank_fleet_map_test.dart:36`).

## TDD Evidence

| Phase | Command | Exit Code | Expected |
|---|---|---|---|
| RED | `flutter test test/theme/eden_brand_swatch_test.dart` | 1 | FAIL (correct) — `Error: Undefined name 'EdenBrandSwatch'` at each call site, 24 compile errors, re-reproduced this turn by temporarily removing the implementation file and confirming the identical failure before restoring it |
| GREEN | `flutter test test/theme/eden_brand_swatch_test.dart` | 0 | PASS (correct) — 26/26, including `Carbon Blue golden ramp tryParse(#0F62FE) reproduces the verified golden ramp exactly` |
| REFACTOR | _(not performed — no cleanup needed)_ | — | N/A |

## Post-TRD Verification

- **Auto-fix cycles used:** 0
- **Must-haves verified:** 12/12
- **Gate failures:** None

Verification checklist (per TRD `<verification>`), all re-confirmed with fresh commands:
1. `flutter analyze` clean of errors (0 errors; 1 sanctioned info-level notice on new files). PASS
2. `flutter test test/theme/` green — 179/179 (153 pre-existing + 26 new). PASS
3. `EdenBrandSwatch.tryParse('#0F62FE')!` reproduces the eleven verified Carbon Blue shades exactly. PASS
4. For every `realPartnerHexes` + `degenerate` input: 11 shades present, shade 500 exact, monotonic lightness, hue/saturation within tolerance. PASS (part of the 26/26 suite)
5. For every `malformed` input, including the four signed forms: `tryParse` returns null, throws nothing. PASS
5b. `grep -n "RegExp" lib/src/theme/eden_brand_swatch.dart` shows the anchored `^[0-9A-Fa-f]+$` guard applied before `int.tryParse`. PASS
6. `EdenTheme.light(brand: s)` / `EdenTheme.dark(brand: s)` construct successfully for a generated swatch. PASS (part of the 26/26 suite)
7. `git diff -- lib/src/theme/eden_brand_preset.dart` is EMPTY. PASS (confirmed `0` lines changed across both TRD commits)
8. `git diff` contains no reference to `surfaceTonalSeed`, `radiusMultiplier`, `minimumTouchTargetPx`, `preferBorderOverShadow`, `EdenRadii`, or `EdenColors` call sites. PASS (zero grep matches)

## TDD Exceptions

None — no TDD-EXCEPTION markers were used; both tasks followed the standard RED/GREEN cycle.

## Files Created/Modified
- `lib/src/theme/eden_brand_swatch.dart` (new) - `EdenBrandSwatch.tryParse`/`fromColor`: lenient hex parsing + HSL lightness-ramp 11-shade swatch generator
- `lib/eden_ui.dart` (export only) - added `export 'src/theme/eden_brand_swatch.dart';`
- `test/theme/eden_brand_swatch_test.dart` (new) - 26-test suite covering theme integration, swatch shape, golden ramp, degenerate inputs, accepted/malformed input forms, registry non-regression
- `test/theme/_fixtures/brand_swatch_fixtures.dart` (new) - hand-built fixture data (`realPartnerHexes`, `degenerate`, `malformed`) with provenance headers

## Decisions Made
None - followed the TRD exactly as specified. The TRD explicitly instructed implementing its pre-researched algorithm rather than re-deriving it; every numeric constant (clamp formulas, precomputed weights, tolerance values, golden ramp) came directly from the TRD's `<research_context>`.

## Deviations from Plan

None - TRD executed exactly as written.

## Issues Encountered
None. Every verification command in this TRD passed on first attempt; no debugging iterations were required at any point in the TDD cycle or the post-TRD verification loop.

## User Setup Required

None - no external service configuration required.

## Next Objective Readiness
- `lib/eden_ui.dart` is now owned by TRD 022-02's export addition for this wave; TRDs 022-03 (`eden_theme_profile.dart`) and 022-04 (`eden_profile_fonts.dart`) remain untouched and ready for their own execution.
- The 022-01 back-compat baseline (`test/theme/eden_theme_back_compat_test.dart`, `test/theme/_fixtures/theme_back_compat_baseline.dart`) is confirmed still green and was not modified.
- No blockers for downstream TRDs in this objective.

---
*Objective: 022-runtime-brand-tokens*
*Completed: 2026-08-26*
